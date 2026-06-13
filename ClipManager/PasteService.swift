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
        let cmd = CGKeyCode(kVK_Command)
        let v = CGKeyCode(kVK_ANSI_V)

        // Реальные события клавиши Cmd (down/up), не только флаг — иначе приёмники
        // вроде iPhone Mirroring теряют модификатор и печатают голый V.
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmd, keyDown: true)
        cmdDown?.flags = .maskCommand
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: false)
        vUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmd, keyDown: false)
        cmdUp?.flags = []

        let tap = CGEventTapLocation.cghidEventTap
        cmdDown?.post(tap: tap)
        vDown?.post(tap: tap)
        vUp?.post(tap: tap)
        cmdUp?.post(tap: tap)
    }
}
