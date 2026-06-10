import SwiftUI
import Carbon.HIToolbox

struct HotKeyRecorder: NSViewRepresentable {
    let settings: AppSettings
    let onChange: () -> Void

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.display = settings.hotKeyDisplay
        view.onCapture = { keyCode, carbonMods, display in
            settings.hotKeyCode = Int(keyCode)
            settings.hotKeyModifiers = Int(carbonMods)
            settings.hotKeyDisplay = display
            onChange()
        }
        return view
    }

    func updateNSView(_ nsView: RecorderView, context: Context) {
        nsView.display = settings.hotKeyDisplay
        nsView.needsDisplay = true
    }
}

final class RecorderView: NSView {
    var onCapture: ((UInt16, UInt32, String) -> Void)?
    var display: String = ""
    private var recording = false { didSet { needsDisplay = true } }

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        recording = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        recording = false
        return true
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard recording else {
            super.keyDown(with: event)
            return
        }
        let flags = event.modifierFlags
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        guard carbon != 0 else {
            NSSound.beep() // требуется хотя бы один модификатор
            return
        }
        let text = Self.displayString(flags: flags, event: event)
        onCapture?(event.keyCode, carbon, text)
        window?.makeFirstResponder(nil)
    }

    private static func displayString(flags: NSEvent.ModifierFlags, event: NSEvent) -> String {
        var s = ""
        if flags.contains(.control) { s += "⌃" }
        if flags.contains(.option) { s += "⌥" }
        if flags.contains(.shift) { s += "⇧" }
        if flags.contains(.command) { s += "⌘" }
        let key = (event.charactersIgnoringModifiers ?? "").uppercased()
        s += key.isEmpty ? "?" : key
        return s
    }

    override func draw(_ dirtyRect: NSRect) {
        let bg = recording
            ? NSColor.controlAccentColor.withAlphaComponent(0.18)
            : NSColor.controlBackgroundColor
        bg.setFill()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        path.fill()
        NSColor.separatorColor.setStroke()
        path.stroke()

        let text = recording ? "Нажмите сочетание…" : display
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: recording ? NSColor.secondaryLabelColor : NSColor.labelColor,
        ]
        let size = (text as NSString).size(withAttributes: attrs)
        let pt = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        (text as NSString).draw(at: pt, withAttributes: attrs)
    }
}
