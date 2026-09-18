import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [SavedNFCItem] = []

    private let storageKey = "nfcove.library.items"

    init() {
        load()
    }

    func add(name: String, kind: NFCRecordKind, value: String) {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanedName.isEmpty ? value : cleanedName
        items.insert(SavedNFCItem(name: finalName, kind: kind, value: value), at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            items.remove(at: index)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedNFCItem].self, from: data) else {
            return
        }
        items = decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
