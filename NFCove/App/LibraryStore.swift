import Combine
import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [SavedNFCItem] = []
    @Published private(set) var persistenceError: String?

    private static let legacyStorageKey = "nfcove.library.items"

    private let fileManager: FileManager
    private let preferences: UserDefaults
    private let storageURL: URL

    init(
        fileManager: FileManager = .default,
        preferences: UserDefaults = .standard,
        storageURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.preferences = preferences

        if let storageURL {
            self.storageURL = storageURL
        } else {
            let directory = fileManager
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("NFCove", isDirectory: true)
            self.storageURL = directory.appendingPathComponent("library-v1.json")
        }

        load()
    }

    func add(name: String, kind: NFCRecordKind, value: String) {
        guard let normalizedValue = NFCRecordContent.normalizedValue(
            for: kind,
            value: value
        ) else {
            return
        }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanedName.isEmpty ? normalizedValue : cleanedName

        items.insert(
            SavedNFCItem(
                name: finalName,
                kind: kind,
                value: normalizedValue
            ),
            at: 0
        )
        save()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard items.indices.contains(index) else { continue }
            items.remove(at: index)
        }
        save()
    }

    private func load() {
        do {
            try ensureStorageDirectory()

            if fileManager.fileExists(atPath: storageURL.path) {
                let data = try Data(contentsOf: storageURL)
                items = try JSONDecoder()
                    .decode([SavedNFCItem].self, from: data)
                    .sorted { $0.createdAt > $1.createdAt }
                persistenceError = nil
                return
            }

            try migrateLegacyLibraryIfNeeded()
        } catch {
            preserveCorruptStoreIfNeeded()
            items = []
            persistenceError = error.localizedDescription
        }
    }

    private func migrateLegacyLibraryIfNeeded() throws {
        guard let data = preferences.data(forKey: Self.legacyStorageKey) else {
            items = []
            return
        }

        let decoded = try JSONDecoder().decode([SavedNFCItem].self, from: data)
        items = decoded.sorted { $0.createdAt > $1.createdAt }

        try persist(items)
        preferences.removeObject(forKey: Self.legacyStorageKey)
        persistenceError = nil
    }

    private func save() {
        do {
            try ensureStorageDirectory()
            try persist(items)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func persist(_ items: [SavedNFCItem]) throws {
        let data = try JSONEncoder().encode(items)
        #if os(iOS)
        try data.write(
            to: storageURL,
            options: [.atomic, .completeFileProtection]
        )
        #else
        try data.write(to: storageURL, options: .atomic)
        #endif
    }

    private func ensureStorageDirectory() throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func preserveCorruptStoreIfNeeded() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }

        let backup = storageURL
            .deletingPathExtension()
            .appendingPathExtension("corrupt-(UUID().uuidString).json")

        try? fileManager.moveItem(at: storageURL, to: backup)
    }
}
