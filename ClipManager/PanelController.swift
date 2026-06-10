import AppKit
import SwiftUI

@MainActor
final class PanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<PopupView>?
    private var keyMonitor: Any?
    private var tick = 0
    private let model: PopupModel
    private(set) var previousApp: NSRunningApplication?

    init(model: PopupModel) {
        self.model = model
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        previousApp = NSWorkspace.shared.frontmostApplication
        model.reset()

        let panel = self.panel ?? makePanel()
        self.panel = panel

        // Свежий контент при каждом открытии — гарантирует актуальную историю.
        tick += 1
        let host = NSHostingView(rootView: PopupView(model: model, tick: tick))
        hostingView = host
        panel.contentView = host

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    /// Живое обновление списка, когда окно открыто и пользователь не вводит поиск.
    func liveRefresh() {
        guard let panel, panel.isVisible, model.query.isEmpty else { return }
        tick += 1
        hostingView?.rootView = PopupView(model: model, tick: tick)
    }

    func hide() {
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.minSize = NSSize(width: 280, height: 220)
        panel.animationBehavior = .utilityWindow
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        if !panel.setFrameUsingName("ClipManagerPopup") {
            panel.center()
        }
        panel.setFrameAutosaveName("ClipManagerPopup")
        return panel
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            switch event.keyCode {
            case 125: self.model.moveDown(); return nil   // ↓
            case 126: self.model.moveUp(); return nil     // ↑
            case 36, 76:                                  // Return / Enter
                let plain = event.modifierFlags.contains(.option)
                self.model.chooseCurrent(plain: plain)
                return nil
            case 53: self.model.onClose(); return nil     // Esc
            default: return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
    }
}
