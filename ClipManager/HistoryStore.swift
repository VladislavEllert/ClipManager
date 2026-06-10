import Foundation
import Observation

@MainActor
@Observable
final class HistoryStore {
    private(set) var items: [ClipboardItem] = []
    var onChange: (() -> Void)?
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
        self.items = Storage.loadHistory()
    }

    func add(_ item: ClipboardItem) {
        if let idx = items.firstIndex(where: { $0.contentHash == item.contentHash }) {
            var existing = items.remove(at: idx)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            // новый item мог записать blob-дубль — чистим
            if let name = item.blobFileName, name != existing.blobFileName {
                Storage.deleteBlob(name)
            }
        } else {
            items.insert(item, at: 0)
        }
        trim()
        save()
    }

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isPinned.toggle()
        save()
    }

    func remove(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        let removed = items.remove(at: idx)
        if let name = removed.blobFileName { Storage.deleteBlob(name) }
        save()
    }

    func clear() {
        let toDelete = items.filter { !$0.isPinned }
        for item in toDelete {
            if let name = item.blobFileName { Storage.deleteBlob(name) }
        }
        items.removeAll { !$0.isPinned }
        save()
    }

    func enforceLimit() {
        trim()
        save()
    }

    private func trim() {
        let limit = max(1, min(100, settings.maxHistory))
        guard items.count > limit else { return }
        var kept: [ClipboardItem] = []
        var nonPinnedCount = 0
        var toDelete: [ClipboardItem] = []
        for item in items {
            if item.isPinned {
                kept.append(item)
            } else if nonPinnedCount < limit {
                kept.append(item)
                nonPinnedCount += 1
            } else {
                toDelete.append(item)
            }
        }
        for item in toDelete {
            if let name = item.blobFileName { Storage.deleteBlob(name) }
        }
        items = kept
    }

    private func save() {
        Storage.saveHistory(items)
        onChange?()
    }
}
