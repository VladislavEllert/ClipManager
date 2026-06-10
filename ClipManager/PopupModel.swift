import Foundation
import Observation

@MainActor
@Observable
final class PopupModel {
    var query = ""
    var selectedIndex = 0

    let store: HistoryStore
    let settings: AppSettings

    var onChoose: (ClipboardItem, Bool) -> Void = { _, _ in }
    var onClose: () -> Void = {}
    var onOpenSettings: () -> Void = {}

    init(store: HistoryStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    var filtered: [ClipboardItem] {
        let base = store.items
        guard settings.searchEnabled, !query.isEmpty else { return base }
        return base.filter { $0.previewText.localizedCaseInsensitiveContains(query) }
    }

    func reset() {
        query = ""
        selectedIndex = 0
    }

    func clampSelection() {
        let count = filtered.count
        if count == 0 {
            selectedIndex = 0
        } else if selectedIndex >= count {
            selectedIndex = count - 1
        } else if selectedIndex < 0 {
            selectedIndex = 0
        }
    }

    func moveDown() {
        clampSelection()
        if selectedIndex < filtered.count - 1 { selectedIndex += 1 }
    }

    func moveUp() {
        clampSelection()
        if selectedIndex > 0 { selectedIndex -= 1 }
    }

    func chooseCurrent(plain: Bool = false) {
        clampSelection()
        guard filtered.indices.contains(selectedIndex) else { return }
        onChoose(filtered[selectedIndex], plain)
    }
}
