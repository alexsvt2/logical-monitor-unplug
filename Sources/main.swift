import AppKit
import Foundation

let controller = MonitorController()
var arguments = Array(CommandLine.arguments.dropFirst())
do {
    if let index = arguments.firstIndex(of: "--language") {
        guard arguments.filter({ $0 == "--language" }).count == 1,
              index + 1 < arguments.count,
              let language = LanguageChoice(rawValue: arguments[index + 1]) else {
            throw MonitorError(message: L("cli.languageInvalid"))
        }
        Localization.shared.override = language
        arguments.removeSubrange(index...(index + 1))
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
if !arguments.isEmpty {
    do {
        let command = arguments[0]
        guard ["--help", "--list", "--toggle", "--enable", "--disable", "--recover"].contains(command),
              arguments.count <= ( ["--toggle", "--enable", "--disable"].contains(command) ? 2 : 1) else {
            throw MonitorError(message: L("cli.invalid"))
        }
        if command == "--help" {
            print(L("cli.help"))
        } else if command == "--recover" {
            print(try controller.recover())
        } else {
            let monitors = try controller.monitors()
            if command == "--list" {
                for monitor in monitors {
                    let state = !monitor.available ? L("status.missing") : monitor.active ? L("status.active") : L("status.disabled")
                    print("\(monitor.uuid)  \(monitor.name)  \(state)\(monitor.main ? L("display.primarySuffix") : "")")
                }
                if monitors.isEmpty { print(L("cli.noDisplays")) }
            } else {
                let requested = arguments.count == 2 ? arguments[1] : controller.selectedUUID
                guard let target = MonitorPolicy.target(monitors, selected: requested) else {
                    throw MonitorError(message: L("cli.choose"))
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
    let action = NSButton(title: L("action.disable"), target: nil, action: nil)
    let recovery = NSButton(title: L("action.recover"), target: nil, action: nil)
    let headline = NSTextField(wrappingLabelWithString: "")
    let summary = NSTextField(wrappingLabelWithString: "")
    let recoveryHint = NSTextField(wrappingLabelWithString: "")
    let settings = NSButton(title: "", target: nil, action: nil)
    let languageLabel = NSTextField(labelWithString: "")
    let languagePicker = NSPopUpButton()
    var displays: [Monitor] = []
    var choice: String?
    var busy = false
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Logical Unplug")
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 570, height: 570),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Logical Unplug"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        headline.font = .systemFont(ofSize: 19, weight: .semibold)
        summary.textColor = .secondaryLabelColor
        picker.target = self
        picker.action = #selector(selectMonitor)
        action.target = self
        action.action = #selector(toggle)
        action.bezelStyle = .rounded
        action.controlSize = .large
        state.font = .systemFont(ofSize: 14, weight: .medium)
        feedback.textColor = .secondaryLabelColor
        settings.target = self
        settings.action = #selector(openSettings)
        settings.bezelStyle = .rounded
        recovery.target = self
        recovery.action = #selector(recover)
        recovery.bezelStyle = .rounded
        recoveryHint.textColor = .secondaryLabelColor
        languagePicker.target = self
        languagePicker.action = #selector(selectLanguage)
        let languageRow = NSStackView(views: [languageLabel, languagePicker])
        languageRow.orientation = .horizontal
        languageRow.spacing = 12
        let stack = NSStackView(views: [headline, summary, picker, state, action, feedback, recoveryHint, recovery, settings, languageRow])
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
            headline.widthAnchor.constraint(equalTo: stack.widthAnchor),
            summary.widthAnchor.constraint(equalTo: stack.widthAnchor),
            recoveryHint.widthAnchor.constraint(equalTo: stack.widthAnchor),
            state.widthAnchor.constraint(equalTo: stack.widthAnchor),
            feedback.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        choice = controller.selectedUUID
        applyLanguage()
        showWindow()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func applyLanguage() {
        headline.stringValue = L("app.headline")
        summary.stringValue = L("app.description")
        recoveryHint.stringValue = L("recovery.hint")
        settings.title = L("action.settings")
        recovery.title = L("action.recover")
        languageLabel.stringValue = L("language.label")
        languagePicker.removeAllItems()
        for language in LanguageChoice.allCases {
            languagePicker.addItem(withTitle: language == .system ? L("language.system") : language == .es ? "Español" : "English")
            languagePicker.lastItem?.representedObject = language.rawValue
            if language == (Localization.shared.override ?? Localization.shared.choice) {
                languagePicker.select(languagePicker.lastItem)
            }
        }
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("app.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        NSApp.mainMenu = menu
        refresh()
    }

    @objc func selectLanguage() {
        guard let raw = languagePicker.selectedItem?.representedObject as? String,
              let choice = LanguageChoice(rawValue: raw) else { return }
        Localization.shared.override = nil
        Localization.shared.choice = choice
        applyLanguage()
        feedback.stringValue = L("language.saved")
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
            feedback.stringValue = L("selection.saved")
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
            picker.addItem(withTitle: L("selection.placeholder"))
            for (index, monitor) in displays.enumerated() {
                picker.addItem(withTitle: "\(index + 1). \(monitor.name)\(monitor.main ? L("display.primarySuffix") : "")\(monitor.available ? "" : L("display.missingSuffix"))")
                picker.lastItem?.representedObject = monitor.uuid
                if monitor.uuid == choice { picker.selectItem(at: index + 1) }
            }
            let target = displays.first { $0.uuid == choice }
            state.stringValue = target.map { !$0.available ? L("status.macMissing") : $0.active ? L("status.macActive") : L("status.macDisabled") } ?? L("selection.secondary")
            action.title = target?.active == false ? L("action.enable") : L("action.disable")
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
            let recoverItem = NSMenuItem(title: L("action.recover"), action: #selector(recover), keyEquivalent: "")
            recoverItem.target = self
            menu.addItem(recoverItem)
            let show = NSMenuItem(title: L("action.show"), action: #selector(showWindow), keyEquivalent: "")
            show.target = self
            menu.addItem(show)
            menu.addItem(.separator())
            menu.addItem(withTitle: L("action.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
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
        languagePicker.isEnabled = false
        feedback.stringValue = L("action.progress")
        // Let the UI paint before the synchronous WindowServer transaction.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            do {
                self.feedback.stringValue = try operation()
            } catch {
                self.feedback.stringValue = error.localizedDescription
                let alert = NSAlert()
                alert.messageText = L("error.title")
                alert.informativeText = error.localizedDescription
                alert.addButton(withTitle: L("action.ok"))
                alert.runModal()
            }
            self.busy = false
            self.picker.isEnabled = true
            self.languagePicker.isEnabled = true
            self.recovery.isEnabled = true
            self.refresh()
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
#if UI_TESTING
// Run the real window in both languages without changing display state or preferences.
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    for language in [LanguageChoice.en, .es] {
        Localization.shared.override = language
        delegate.applyLanguage()
        let content = delegate.window.contentView!
        content.layoutSubtreeIfNeeded()
        assert(delegate.headline.stringValue == L("app.headline"))
        assert(delegate.recovery.title == L("action.recover"))
        assert(delegate.settings.title == L("action.settings"))
        assert(delegate.languagePicker.selectedItem?.representedObject as? String == language.rawValue)
        for view in [delegate.headline, delegate.summary, delegate.picker, delegate.state,
                     delegate.action, delegate.recoveryHint, delegate.recovery, delegate.settings,
                     delegate.languageLabel, delegate.languagePicker] as [NSView] {
            let frame = view.convert(view.bounds, to: content)
            assert(frame.width > 0 && frame.height > 0)
            assert(frame.minX >= 0 && frame.minY >= 0 && frame.maxX <= content.bounds.maxX && frame.maxY <= content.bounds.maxY)
        }
    }
    print("UI verified in English and Spanish; display state and preferences unchanged.")
    exit(0)
}
#endif
app.run()
