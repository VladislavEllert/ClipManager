import Foundation
import CryptoKit

enum ClipKind: String, Codable {
    case text
    case rtf
    case image
    case file
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var kind: ClipKind
    var createdAt: Date
    var isPinned: Bool
    var previewText: String
    var text: String?
    var rtfData: Data?
    var blobFileName: String?
    var filePaths: [String]?
    var contentHash: String

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension ClipboardItem {
    static func makeText(_ s: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(), kind: .text, createdAt: Date(), isPinned: false,
            previewText: preview(s), text: s, rtfData: nil, blobFileName: nil,
            filePaths: nil, contentHash: "t:" + s
        )
    }

    static func makeRTF(rtf: Data, plain: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(), kind: .rtf, createdAt: Date(), isPinned: false,
            previewText: preview(plain), text: plain, rtfData: rtf, blobFileName: nil,
            filePaths: nil, contentHash: "t:" + plain
        )
    }

    static func makeImage(png: Data) -> ClipboardItem {
        let name = UUID().uuidString + ".png"
        Storage.writeBlob(png, name: name)
        return ClipboardItem(
            id: UUID(), kind: .image, createdAt: Date(), isPinned: false,
            previewText: "Изображение", text: nil, rtfData: nil, blobFileName: name,
            filePaths: nil, contentHash: "i:" + sha256(png)
        )
    }

    static func makeFile(paths: [String]) -> ClipboardItem {
        let label = paths.count == 1
            ? (paths[0] as NSString).lastPathComponent
            : "\(paths.count) файлов"
        return ClipboardItem(
            id: UUID(), kind: .file, createdAt: Date(), isPinned: false,
            previewText: label, text: nil, rtfData: nil, blobFileName: nil,
            filePaths: paths, contentHash: "f:" + paths.joined(separator: "|")
        )
    }

    private static func preview(_ s: String) -> String {
        let collapsed = s
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        return collapsed.count > 120 ? String(collapsed.prefix(120)) + "…" : collapsed
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
