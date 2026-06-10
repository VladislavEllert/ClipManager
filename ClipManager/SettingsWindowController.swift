import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: AppSettings
    private let store: HistoryStore
    private let onHotKeyChanged: () -> Void

    init(settings: AppSettings, store: HistoryStore, onHotKeyChanged: @escaping () -> Void) {
        self.settings = settings
        self.store = store
        self.onHotKeyChanged = onHotKeyChanged
    }

    func show() {
        if window == nil {
            let view = SettingsView(
                settings: settings,
                store: store,
                onHotKeyChanged: onHotKeyChanged
            )
            let hosting = NSHostingController(rootView: view)
            let w = NSWindow(contentViewController: hosting)
            w.title = "ClipManager — Настройки"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
