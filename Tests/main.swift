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

assert(LanguageChoice.resolve(.system, preferredLanguages: ["es-MX", "en-US"]) == "es")
assert(LanguageChoice.resolve(.system, preferredLanguages: ["en_GB", "es"]) == "en")
assert(LanguageChoice.resolve(.system, preferredLanguages: ["fr-FR", "es-ES"]) == "es")
assert(LanguageChoice.resolve(.system, preferredLanguages: ["ja-JP"]) == "en")
assert(LanguageChoice.resolve(.es, preferredLanguages: ["en-US"]) == "es")
assert(LanguageChoice.resolve(.en, preferredLanguages: ["es-MX"]) == "en")
let resourceRoot = URL(fileURLWithPath: CommandLine.arguments[1])
let domain = "LogicalUnplug.Tests.\(UUID().uuidString)"
let preferences = UserDefaults(suiteName: domain)!
defer { preferences.removePersistentDomain(forName: domain) }
let translations = Localization(resources: resourceRoot, defaults: preferences, preferredLanguages: ["es-MX"])
assert(translations.language == "es")
assert(translations.text("action.disable") == "Desactivar en este Mac")
translations.choice = .en
assert(translations.text("action.disable") == "Disable on this Mac")
assert(translations.text("error.rejected", arguments: [Int32(42)]) == "macOS rejected the display change (42).")
assert(translations.text("recovery.success", arguments: ["LG"]) == "Recovered displays: LG")
let reopened = Localization(resources: resourceRoot, defaults: preferences, preferredLanguages: ["es-MX"])
assert(reopened.language == "en")
translations.override = .es
assert(translations.text("action.recover") == "Recuperar pantallas")
assert(translations.choice == .en)
translations.override = nil
assert(translations.language == "en")
translations.choice = .system
assert(translations.language == "es")

func dictionary(_ language: String) throws -> [String: String] {
    let data = try Data(contentsOf: resourceRoot.appendingPathComponent("\(language).lproj/Localizable.strings"))
    return try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: String]
}
let english = try dictionary("en")
let spanish = try dictionary("es")
assert(Set(english.keys) == Set(spanish.keys))
let formats = try NSRegularExpression(pattern: "%[@d]")
for key in english.keys {
    let en = english[key]!, es = spanish[key]!
    assert(!en.isEmpty && !es.isEmpty)
    func placeholders(_ value: String) -> [String] {
        formats.matches(in: value, range: NSRange(value.startIndex..., in: value)).map {
            (value as NSString).substring(with: $0.range)
        }
    }
    assert(placeholders(en) == placeholders(es), "Format mismatch: \(key)")
}
print("Idiomas, preferencia guardada, override temporal y \(english.count) traducciones verificados.")
