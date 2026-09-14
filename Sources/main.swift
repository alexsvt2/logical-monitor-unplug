import AppKit
import Foundation

let controller = MonitorController()
let arguments = Array(CommandLine.arguments.dropFirst())
if !arguments.isEmpty {
    do {
        let command = arguments[0]
        guard ["--help", "--list", "--toggle", "--enable", "--disable", "--recover"].contains(command),
              arguments.count <= ( ["--toggle", "--enable", "--disable"].contains(command) ? 2 : 1) else {
            throw MonitorError(message: "Comando inválido. Usa --help para ver las opciones.")
        }
        if command == "--help" {
            print("""
            Logical Unplug — controla una pantalla sin desconectar el cable.
            Sin argumentos: abre la interfaz gráfica.
            --list             Muestra pantallas y sus identificadores.
            --toggle [UUID]    Alterna la pantalla elegida en la app.
            --enable [UUID]    Reactiva la pantalla elegida.
            --disable [UUID]   Desactiva la pantalla elegida.
            --recover          Intenta recuperar todas las pantallas ocultas.
            Sin elección guardada, usa la única pantalla externa secundaria.
            """)
        } else if command == "--recover" {
            print(try controller.recover())
        } else {
            let monitors = try controller.monitors()
            if command == "--list" {
                for monitor in monitors {
                    let state = !monitor.available ? "No detectada" : monitor.active ? "Activa" : "Desactivada"
                    print("\(monitor.uuid)  \(monitor.name)  \(state)\(monitor.main ? " · Principal" : "")")
                }
                if monitors.isEmpty { print("macOS no detectó pantallas en esta sesión.") }
            } else {
                let requested = arguments.count == 2 ? arguments[1] : controller.selectedUUID
                guard let target = MonitorPolicy.target(monitors, selected: requested) else {
                    throw MonitorError(message: "Abre la app para elegir una pantalla externa secundaria o indica un UUID de --list.")
                }
                print(try controller.change(uuid: target.uuid, enable: command == "--toggle" ? !target.active : command == "--enable"))
            }
        }
        exit(0)
    } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        exit(1)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    let picker = NSPopUpButton()
    let state = NSTextField(wrappingLabelWithString: "")
    let feedback = NSTextField(wrappingLabelWithString: "")
    let action = NSButton(title: "Desactivar en este Mac", target: nil, action: nil)
    let recovery = NSButton(title: "Recuperar pantallas", target: nil, action: nil)
    var displays: [Monitor] = []
    var choice: String?
    var busy = false
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Salir de Logical Unplug", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Logical Unplug")
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 550, height: 510),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Logical Unplug"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        let title = NSTextField(labelWithString: "Tu monitor, en la computadora que necesitas.")
        title.font = .systemFont(ofSize: 19, weight: .semibold)
        let description = NSTextField(wrappingLabelWithString: "Desactiva la salida de video del Mac sin quitar el cable. Si tu monitor busca entradas automáticamente, podrá mostrar la otra computadora.")
        description.textColor = .secondaryLabelColor
        picker.target = self
        picker.action = #selector(selectMonitor)
        action.target = self
        action.action = #selector(toggle)
        action.bezelStyle = .rounded
        action.controlSize = .large
        state.font = .systemFont(ofSize: 14, weight: .medium)
        feedback.textColor = .secondaryLabelColor
        let settings = NSButton(title: "Ajustes de pantallas…", target: self, action: #selector(openSettings))
        settings.bezelStyle = .rounded
        recovery.target = self
        recovery.action = #selector(recover)
        recovery.bezelStyle = .rounded
        let hint = NSTextField(wrappingLabelWithString: "¿No aparece el monitor? Recuperar pantallas intenta reactivar todas las salidas desactivadas del Mac.")
        hint.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [title, description, picker, state, action, feedback, hint, recovery, settings])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 15
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 25),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -25),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 25),
            picker.widthAnchor.constraint(equalTo: stack.widthAnchor),
            description.widthAnchor.constraint(equalTo: stack.widthAnchor),
            state.widthAnchor.constraint(equalTo: stack.widthAnchor),
            feedback.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        choice = controller.selectedUUID
        refresh()
        showWindow()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }

    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
    @objc func openSettings() { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension")!) }
    @objc func selectMonitor() {
        guard let key = picker.selectedItem?.representedObject as? String,
              let monitor = displays.first(where: { $0.uuid == key }) else { return }
        do {
            try controller.select(monitor)
            choice = key
            feedback.stringValue = "Elección guardada. Puedes controlarla también desde la barra de menús."
        } catch { feedback.stringValue = error.localizedDescription }
        refresh()
    }
    func refresh() {
        guard !busy else { return }
        do {
            displays = try controller.monitors()
            choice = controller.selectedUUID ?? choice
            if choice == nil { choice = MonitorPolicy.target(displays, selected: nil)?.uuid }
            picker.removeAllItems()
            picker.addItem(withTitle: "Elige la pantalla que quieres controlar")
            for (index, monitor) in displays.enumerated() {
                picker.addItem(withTitle: "\(index + 1). \(monitor.name)\(monitor.main ? " · Principal" : "")\(monitor.available ? "" : " · No detectada")")
                picker.lastItem?.representedObject = monitor.uuid
                if monitor.uuid == choice { picker.selectItem(at: index + 1) }
            }
            let target = displays.first { $0.uuid == choice }
            state.stringValue = target.map { !$0.available ? "Pantalla no detectada por el Mac" : $0.active ? "● Activa en este Mac" : "○ Desactivada en este Mac" } ?? "Elige una pantalla externa secundaria."
            action.title = target?.active == false ? "Reactivar en este Mac" : "Desactivar en este Mac"
            action.isEnabled = false
            if let target = target {
                do {
                    try MonitorPolicy.validate(target, enable: !target.active, monitors: displays)
                    action.isEnabled = true
                } catch { state.stringValue += "\n" + error.localizedDescription }
            }
            statusItem.button?.image = NSImage(systemSymbolName: target?.active == false ? "display.trianglebadge.exclamationmark" : "display", accessibilityDescription: state.stringValue)
            statusItem.button?.toolTip = state.stringValue
            let menu = NSMenu()
            let label = NSMenuItem(title: target?.name ?? "Logical Unplug", action: nil, keyEquivalent: "")
            menu.addItem(label)
            let item = NSMenuItem(title: action.title, action: #selector(toggle), keyEquivalent: "")
            item.target = self
            item.isEnabled = action.isEnabled
            menu.autoenablesItems = false
            menu.addItem(item)
            let recoverItem = NSMenuItem(title: "Recuperar pantallas", action: #selector(recover), keyEquivalent: "")
            recoverItem.target = self
            menu.addItem(recoverItem)
            let show = NSMenuItem(title: "Mostrar controles…", action: #selector(showWindow), keyEquivalent: "")
            show.target = self
            menu.addItem(show)
            menu.addItem(.separator())
            menu.addItem(withTitle: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
        } catch {
            state.stringValue = error.localizedDescription
            action.isEnabled = false
        }
    }
    @objc func toggle() {
        guard !busy, let target = displays.first(where: { $0.uuid == choice }) else { return }
        perform { try controller.change(uuid: target.uuid, enable: !target.active) }
    }
    @objc func recover() {
        guard !busy else { return }
        perform { try controller.recover() }
    }
    func perform(_ operation: @escaping () throws -> String) {
        busy = true
        action.isEnabled = false
        recovery.isEnabled = false
        picker.isEnabled = false
        feedback.stringValue = "Aplicando cambio…"
        // Let the UI paint before the synchronous WindowServer transaction.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                self.feedback.stringValue = try operation()
            } catch {
                self.feedback.stringValue = error.localizedDescription
                let alert = NSAlert()
                alert.messageText = "No se pudo cambiar la pantalla"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
            self.busy = false
            self.picker.isEnabled = true
            self.recovery.isEnabled = true
            self.refresh()
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
