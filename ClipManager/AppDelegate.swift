import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyID: UInt32?

    let settings = AppSettings()
    lazy var store = HistoryStore(settings: settings)
    lazy var monitor = ClipboardMonitor(store: store, settings: settings)
    lazy var model = PopupModel(store: store, settings: settings)
    lazy var panelController = PanelController(model: model)
    lazy var settingsWindow = SettingsWindowController(
        settings: settings,
        store: store,
        onHotKeyChanged: { [weak self] in self?.registerHotKey() }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        terminateOtherInstances()
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()

        model.onChoose = { [weak self] item, plain in self?.pasteSelected(item, plainOnly: plain) }
        model.onClose = { [weak self] in self?.panelController.hide() }
        model.onOpenSettings = { [weak self] in
            self?.panelController.hide()
            self?.settingsWindow.show()
        }
        store.onChange = { [weak self] in self?.panelController.liveRefresh() }

        monitor.start()
        registerHotKey()
    }

    private func terminateOtherInstances() {
        let myPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.vladislav.ClipManager"
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        where app.processIdentifier != myPID {
            app.forceTerminate()
        }
    }

    func registerHotKey() {
        if let hotKeyID { HotKeyCenter.shared.unregister(hotKeyID) }
        hotKeyID = HotKeyCenter.shared.register(
            keyCode: UInt32(settings.hotKeyCode),
            modifiers: UInt32(settings.hotKeyModifiers)
        ) { [weak self] in
            self?.panelController.toggle()
        }
    }

    private func pasteSelected(_ item: ClipboardItem, plainOnly: Bool) {
        panelController.hide()
        let prev = panelController.previousApp
        PasteService.placeOnPasteboard(item, plainOnly: plainOnly)
        monitor.acknowledgeOwnChange()

        guard settings.autoPaste else {
            prev?.activate()
            return
        }
        guard PasteService.accessibilityGranted else {
            PasteService.requestAccessibility()
            prev?.activate()
            return
        }
        prev?.activate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            PasteService.simulatePaste()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "ClipManager"
            )
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Открыть историю", action: #selector(openHistory), keyEquivalent: "")
        menu.addItem(withTitle: "Настройки…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Выход", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items {
            item.target = self
        }
        statusItem.menu = menu
    }

    @objc private func openHistory() {
        panelController.show()
    }

    @objc private func openSettings() {
        settingsWindow.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
