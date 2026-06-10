import Foundation

enum Storage {
    static let dir: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let d = base.appendingPathComponent("ClipManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    static let blobsDir: URL = {
        let d = dir.appendingPathComponent("blobs", isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }()

    static let historyFile = dir.appendingPathComponent("history.json")

    static func loadHistory() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: historyFile) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([ClipboardItem].self, from: data)) ?? []
    }

    static func saveHistory(_ items: [ClipboardItem]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: historyFile, options: .atomic)
    }

    static func blobURL(_ name: String) -> URL {
        blobsDir.appendingPathComponent(name)
    }

    static func writeBlob(_ data: Data, name: String) {
        try? data.write(to: blobURL(name), options: .atomic)
    }

    static func deleteBlob(_ name: String) {
        try? FileManager.default.removeItem(at: blobURL(name))
    }
}
