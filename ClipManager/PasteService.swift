import AppKit
import ApplicationServices
import Carbon.HIToolbox

@MainActor
enum PasteService {
    static func placeOnPasteboard(_ item: ClipboardItem, plainOnly: Bool) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.kind {
        case .text:
            pb.setString(item.text ?? "", forType: .string)
        case .rtf:
            if plainOnly {
                pb.setString(item.text ?? "", forType: .string)
            } else {
                if let rtf = item.rtfData {
                    pb.setData(rtf, forType: .rtf)
                }
                pb.setString(item.text ?? "", forType: .string)
            }
        case .image:
            if let name = item.blobFileName,
               let data = try? Data(contentsOf: Storage.blobURL(name)) {
                pb.setData(data, forType: .png)
            }
        case .file:
            if let paths = item.filePaths {
                let urls = paths.map { URL(fileURLWithPath: $0) as NSURL }
                pb.writeObjects(urls)
            }
        }
    }

    static var accessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static func simulatePaste() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
