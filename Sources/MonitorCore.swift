import Foundation
import AppKit
import CoreGraphics
import ColorSync
import Darwin

struct Monitor: Codable {
    let uuid: String
    let name: String
    let id: UInt32
    let active: Bool
    let main: Bool
    let builtin: Bool
    let available: Bool
}

struct MonitorError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

// Kept separate from the hardware calls so selection and safeguards can be tested.
enum MonitorPolicy {
    static func target(_ monitors: [Monitor], selected: String?) -> Monitor? {
        if let selected = selected { return monitors.first { $0.uuid == selected } }
        let secondary = monitors.filter { !$0.main && !$0.builtin && $0.available }
        return secondary.count == 1 ? secondary[0] : nil
    }

    static func validate(_ monitor: Monitor, enable: Bool, monitors: [Monitor]) throws {
        guard monitor.available else {
            throw MonitorError(message: "El Mac no detecta esta pantalla. Revisa el cable o selecciona la entrada del Mac en el monitor y vuelve a intentar.")
        }
        if !enable {
            guard !monitor.builtin else { throw MonitorError(message: "La pantalla integrada no se desactiva desde esta app.") }
            guard !monitor.main else { throw MonitorError(message: "Esta es la pantalla principal. Elige otra pantalla o cambia la principal en Ajustes del Sistema.") }
            guard monitors.contains(where: { $0.uuid != monitor.uuid && $0.active && $0.main }) else {
                throw MonitorError(message: "No se desactivará la única pantalla disponible.")
            }
        }
    }
}

final class MonitorController {
    private let directory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/LogicalMonitorUnplug", isDirectory: true)
    private var stateURL: URL { directory.appendingPathComponent("selection.json") }
    private struct Selection: Codable { let uuid: String; let name: String }
    private var selection: Selection? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(Selection.self, from: data)
    }
    var selectedUUID: String? { selection?.uuid }

    func select(_ monitor: Monitor) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Selection(uuid: monitor.uuid, name: monitor.name))
        try data.write(to: stateURL, options: .atomic)
    }

    private func uuid(_ id: UInt32) -> String? {
        guard let value = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
        return CFUUIDCreateString(nil, value) as String
    }

    private func resolve(_ uuid: String) -> UInt32 {
        guard let value = CFUUIDCreateFromString(nil, uuid as CFString) else { return 0 }
        let id = CGDisplayGetDisplayIDFromUUID(value)
        // Never reuse a saved numeric screen ID belonging to another display.
        return id != 0 && self.uuid(id) == uuid ? id : 0
    }

    private func enabled(_ id: UInt32) -> Bool {
        id != 0 && (CGDisplayIsActive(id) != 0 || CGDisplayIsInMirrorSet(id) != 0)
    }

    func monitors() throws -> [Monitor] {
        var ids = [UInt32](repeating: 0, count: 64)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(ids.count), &ids, &count) == .success else {
            throw MonitorError(message: "No se pudieron consultar las pantallas de macOS.")
        }
        let remembered = selection
        if let remembered = remembered {
            let id = resolve(remembered.uuid)
            if id != 0 && Int(count) < ids.count && !ids.prefix(Int(count)).contains(id) {
                ids[Int(count)] = id
                count += 1
            }
        }
        var result: [Monitor] = []
        for id in ids.prefix(Int(count)) {
            guard let key = uuid(id) else { continue }
            let screen = NSScreen.screens.first {
                ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == id
            }
            let name = screen?.localizedName ?? (remembered?.uuid == key ? remembered?.name : nil)
                ?? "Pantalla externa \(result.count + 1)"
            result.append(Monitor(uuid: key, name: name, id: id, active: enabled(id),
                                  main: CGDisplayIsMain(id) != 0, builtin: CGDisplayIsBuiltin(id) != 0,
                                  available: true))
        }
        if let remembered = remembered, !result.contains(where: { $0.uuid == remembered.uuid }) {
            result.append(Monitor(uuid: remembered.uuid, name: remembered.name, id: 0,
                                  active: false, main: false, builtin: false, available: false))
        }
        return result.sorted { ($0.main ? 0 : 1, $0.name, $0.uuid) < ($1.main ? 0 : 1, $1.name, $1.uuid) }
    }

    func recover() throws -> String {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = Darwin.open(directory.appendingPathComponent("action.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw MonitorError(message: "No se pudo abrir el control de operaciones.") }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw MonitorError(message: "Hay un cambio de pantalla en curso.") }
        defer { flock(fd, LOCK_UN) }
        let before = try monitors()
        let oldActive = Set(before.filter { $0.active }.map { $0.uuid })
        // Compatibility recovery from the original @alex-konkov helper. Disabled
        // displays can disappear from the online list before we ever learn a UUID.
        // Probe the original 1...10 contextual IDs plus every currently known ID.
        // This is explicit recovery only, never automatic detection or disabling.
        let ids = Set((1...10).map { UInt32($0) } + before.filter { $0.id != 0 }.map { $0.id })
        guard let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY) else {
            throw MonitorError(message: "No se pudo cargar el control de pantallas.")
        }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "CGSConfigureDisplayEnabled") else {
            throw MonitorError(message: "La recuperación no está disponible en esta versión de macOS.")
        }
        typealias Configure = @convention(c) (OpaquePointer?, UInt32, Bool) -> Int32
        let configure = unsafeBitCast(symbol, to: Configure.self)
        for id in ids.sorted() where !enabled(id) {
            var config: CGDisplayConfigRef?
            guard CGBeginDisplayConfiguration(&config) == .success else { continue }
            if configure(config, id, true) == 0 {
                _ = CGCompleteDisplayConfiguration(config, .forSession)
            } else {
                CGCancelDisplayConfiguration(config)
            }
        }
        for _ in 0..<20 {
            Thread.sleep(forTimeInterval: 0.15)
            let after = try monitors()
            let recovered = after.filter { $0.active && !oldActive.contains($0.uuid) }
            if !recovered.isEmpty {
                return "Pantallas recuperadas: " + recovered.map { $0.name }.joined(separator: ", ")
            }
        }
        throw MonitorError(message: "No aparecieron pantallas adicionales. Selecciona la entrada del Mac en el monitor y vuelve a pulsar Recuperar pantallas.")
    }

    func change(uuid key: String, enable: Bool) throws -> String {
        // The CLI and GUI share a lock so two toggles cannot race.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = Darwin.open(directory.appendingPathComponent("action.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw MonitorError(message: "No se pudo abrir el control de operaciones.") }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw MonitorError(message: "Hay un cambio de pantalla en curso. Espera un momento.") }
        defer { flock(fd, LOCK_UN) }
        let all = try monitors()
        guard let monitor = all.first(where: { $0.uuid == key }) else { throw MonitorError(message: "La pantalla seleccionada ya no está disponible.") }
        try MonitorPolicy.validate(monitor, enable: enable, monitors: all)
        if monitor.active == enable { return enable ? "La pantalla ya está activa en este Mac." : "La pantalla ya está desactivada en este Mac." }
        try select(monitor)

        // Same WindowServer mechanism as the original Python helper/displayplacer.
        // Resolve dynamically: this private API may not exist on a future macOS.
        let handle = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_LAZY)
        guard let handle = handle else { throw MonitorError(message: "No se pudo cargar el control de pantallas.") }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "CGSConfigureDisplayEnabled") else {
            throw MonitorError(message: "Esta versión de macOS no ofrece el control de desconexión utilizado por la app.")
        }
        typealias Configure = @convention(c) (OpaquePointer?, UInt32, Bool) -> Int32
        let configure = unsafeBitCast(symbol, to: Configure.self)
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { throw MonitorError(message: "macOS no permitió iniciar el cambio de pantalla.") }
        let error = configure(config, monitor.id, enable)
        guard error == 0 else {
            CGCancelDisplayConfiguration(config)
            throw MonitorError(message: "macOS rechazó el cambio de pantalla (\(error)).")
        }
        guard CGCompleteDisplayConfiguration(config, .forSession) == .success else {
            throw MonitorError(message: "macOS no pudo aplicar el cambio de pantalla.")
        }
        // Verify the actual state; accepting an API request is not proof of success.
        for _ in 0..<20 {
            Thread.sleep(forTimeInterval: 0.15)
            let current = resolve(key)
            if enable ? (current != 0 && enabled(current)) : (current == 0 || !enabled(current)) {
                return enable ? "Pantalla activa en este Mac." : "Pantalla desactivada en este Mac."
            }
        }
        throw MonitorError(message: "No se pudo confirmar el cambio. Revisa el estado de la pantalla y vuelve a intentar.")
    }
}
