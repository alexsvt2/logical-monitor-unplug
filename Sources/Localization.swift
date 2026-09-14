import Foundation

enum LanguageChoice: String, CaseIterable {
    case system, es, en

    static func resolve(_ choice: LanguageChoice, preferredLanguages: [String]) -> String {
        if choice != .system { return choice.rawValue }
        for preferred in preferredLanguages {
            let code = preferred.replacingOccurrences(of: "_", with: "-").split(separator: "-").first?.lowercased()
            if code == "es" || code == "en" { return code! }
        }
        return "en"
    }
}

final class Localization {
    static let shared = Localization()
    private let defaults: UserDefaults
    private let resources: URL
    private let preferredLanguages: [String]
    private var bundle: Bundle?
    private var fallback: Bundle?
    private(set) var language = "en"
    // A CLI override applies to this invocation only; the GUI setting is persisted.
    var override: LanguageChoice? { didSet { reload() } }
    var choice: LanguageChoice {
        get { LanguageChoice(rawValue: defaults.string(forKey: "language") ?? "system") ?? .system }
        set { defaults.set(newValue.rawValue, forKey: "language"); reload() }
    }

    init(resources: URL = Bundle.main.resourceURL ?? Bundle.main.bundleURL,
         defaults: UserDefaults = .standard,
         preferredLanguages: [String] = Locale.preferredLanguages) {
        self.resources = resources
        self.defaults = defaults
        self.preferredLanguages = preferredLanguages
        reload()
    }

    private func reload() {
        language = LanguageChoice.resolve(override ?? choice, preferredLanguages: preferredLanguages)
        bundle = Bundle(url: resources.appendingPathComponent("\(language).lproj"))
        fallback = Bundle(url: resources.appendingPathComponent("en.lproj"))
    }

    func text(_ key: String, arguments: [CVarArg] = []) -> String {
        let fallbackText = fallback?.localizedString(forKey: key, value: key, table: nil) ?? key
        let text = bundle?.localizedString(forKey: key, value: fallbackText, table: nil) ?? fallbackText
        return arguments.isEmpty ? text : String(format: text, locale: Locale(identifier: language), arguments: arguments)
    }
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    Localization.shared.text(key, arguments: arguments)
}
