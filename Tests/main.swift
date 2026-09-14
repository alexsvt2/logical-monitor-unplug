import Foundation
func display(_ id: String, main: Bool = false, active: Bool = true,
             builtin: Bool = false, available: Bool = true) -> Monitor {
    Monitor(uuid: id, name: "Cualquier marca", id: 1, active: active,
            main: main, builtin: builtin, available: available)
}
func rejects(_ monitor: Monitor, enable: Bool, all: [Monitor]) -> Bool {
    do { try MonitorPolicy.validate(monitor, enable: enable, monitors: all); return false }
    catch { return true }
}
let primary = display("primary", main: true)
let secondary = display("new-device")
assert(MonitorPolicy.target([primary, secondary], selected: nil)?.uuid == secondary.uuid)
assert(MonitorPolicy.target([primary], selected: nil) == nil)
assert(MonitorPolicy.target([primary, secondary, display("third")], selected: nil) == nil)
assert(MonitorPolicy.target([primary, secondary], selected: "removed-device") == nil)
assert(MonitorPolicy.target([primary, secondary], selected: secondary.uuid)?.uuid == secondary.uuid)
assert(rejects(primary, enable: false, all: [primary, secondary]))
assert(rejects(secondary, enable: false, all: [secondary]))
assert(rejects(display("internal", builtin: true), enable: false, all: [primary]))
assert(rejects(display("missing", active: false, available: false), enable: true, all: [primary]))
assert(!rejects(secondary, enable: false, all: [primary, secondary]))
assert(!rejects(display("off", active: false), enable: true, all: [primary]))
print("11 pruebas de selección y protección aprobadas; no se modificaron pantallas.")
