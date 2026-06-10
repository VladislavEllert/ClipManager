import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    var maxHistory: Int { didSet { d.set(maxHistory, forKey: K.maxHistory) } }
    var autoPaste: Bool { didSet { d.set(autoPaste, forKey: K.autoPaste) } }
    var searchEnabled: Bool { didSet { d.set(searchEnabled, forKey: K.searchEnabled) } }
    var pinEnabled: Bool { didSet { d.set(pinEnabled, forKey: K.pinEnabled) } }
    var plainPasteEnabled: Bool { didSet { d.set(plainPasteEnabled, forKey: K.plainPasteEnabled) } }
    var skipPasswords: Bool { didSet { d.set(skipPasswords, forKey: K.skipPasswords) } }

    // Carbon keyCode + modifier mask (cmd=256, shift=512, option=2048, control=4096)
    var hotKeyCode: Int { didSet { d.set(hotKeyCode, forKey: K.hotKeyCode) } }
    var hotKeyModifiers: Int { didSet { d.set(hotKeyModifiers, forKey: K.hotKeyModifiers) } }
    var hotKeyDisplay: String { didSet { d.set(hotKeyDisplay, forKey: K.hotKeyDisplay) } }

    private let d = UserDefaults.standard

    init() {
        d.register(defaults: [
            K.maxHistory: 20,
            K.autoPaste: true,
            K.searchEnabled: true,
            K.pinEnabled: true,
            K.plainPasteEnabled: true,
            K.skipPasswords: true,
            K.hotKeyCode: 9,          // kVK_ANSI_V
            K.hotKeyModifiers: 768,   // cmdKey(256) | shiftKey(512)
            K.hotKeyDisplay: "⌘⇧V",
        ])
        maxHistory = max(1, min(100, d.integer(forKey: K.maxHistory)))
        autoPaste = d.bool(forKey: K.autoPaste)
        searchEnabled = d.bool(forKey: K.searchEnabled)
        pinEnabled = d.bool(forKey: K.pinEnabled)
        plainPasteEnabled = d.bool(forKey: K.plainPasteEnabled)
        skipPasswords = d.bool(forKey: K.skipPasswords)
        hotKeyCode = d.integer(forKey: K.hotKeyCode)
        hotKeyModifiers = d.integer(forKey: K.hotKeyModifiers)
        hotKeyDisplay = d.string(forKey: K.hotKeyDisplay) ?? "⌘⇧V"
    }

    private enum K {
        static let maxHistory = "maxHistory"
        static let autoPaste = "autoPaste"
        static let searchEnabled = "searchEnabled"
        static let pinEnabled = "pinEnabled"
        static let plainPasteEnabled = "plainPasteEnabled"
        static let skipPasswords = "skipPasswords"
        static let hotKeyCode = "hotKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let hotKeyDisplay = "hotKeyDisplay"
    }
}
