import Combine
import Foundation

enum LibraryStoreError: LocalizedError {
    case invalidStoredItem(UUID)

    var errorDescription: String? {
        switch self {
        case .invalidStoredItem(let id):
            return "The saved NFC library contains an invalid record (\(id.uuidString))."
        }
    }
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [SavedNFCItem] = []
    @Published private(set) var scannedCards: [SavedScanCard] = []
    @Published private(set) var persistenceError: String?

    private static let legacyStorageKey = "nfcove.library.items"

    private let fileManager: FileManager
    private let preferences: UserDefaults
    private let storageURL: URL
    private let scansStorageURL: URL

    init(
        fileManager: FileManager = .default,
        preferences: UserDefaults = .standard,
        storageURL: URL? = nil,
        scansStorageURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.preferences = preferences

        let directory: URL
        if let storageURL {
            self.storageURL = storageURL
            directory = storageURL.deletingLastPathComponent()
        } else {
            directory = fileManager
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("NFCove", isDirectory: true)
            self.storageURL = directory.appendingPathComponent("library-v1.json")
        }

        self.scansStorageURL = scansStorageURL
            ?? directory.appendingPathComponent("scanned-tags-v1.json")

        load()
        loadScannedCards()
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

    func addScannedCard(
        name: String,
        records: [NFCRecordSnapshot],
        tagCapacity: Int?,
        tagAccessKey: String?
    ) {
        guard !records.isEmpty else { return }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = String(records[0].value.prefix(64))
        let finalName = cleanedName.isEmpty ? fallback : cleanedName

        scannedCards.insert(
            SavedScanCard(
                name: finalName,
                records: records.map(SavedScanRecord.init(snapshot:)),
                tagCapacity: tagCapacity,
                tagAccessKey: tagAccessKey
            ),
            at: 0
        )
        saveScannedCards()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard items.indices.contains(index) else { continue }
            items.remove(at: index)
        }
        save()
    }

    func deleteScannedCard(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard scannedCards.indices.contains(index) else { continue }
            scannedCards.remove(at: index)
        }
        saveScannedCards()
    }

    private func load() {
        do {
            try ensureStorageDirectory()

            if fileManager.fileExists(atPath: storageURL.path) {
                let data = try Data(contentsOf: storageURL)
                let decoded = try JSONDecoder()
                    .decode([SavedNFCItem].self, from: data)
                let validated = try validatedItems(decoded)
                items = validated.sorted { $0.createdAt > $1.createdAt }

                if validated != decoded {
                    try persist(validated)
                }
                return
            }

            try migrateLegacyLibraryIfNeeded()
        } catch {
            preserveCorruptStoreIfNeeded(at: storageURL)
            items = []
            persistenceError = error.localizedDescription
        }
    }

    private func loadScannedCards() {
        do {
            try ensureStorageDirectory()
            guard fileManager.fileExists(atPath: scansStorageURL.path) else {
                scannedCards = []
                return
            }

            let data = try Data(contentsOf: scansStorageURL)
            scannedCards = try JSONDecoder()
                .decode([SavedScanCard].self, from: data)
                .sorted { $0.scannedAt > $1.scannedAt }
        } catch {
            preserveCorruptStoreIfNeeded(at: scansStorageURL)
            scannedCards = []
            persistenceError = error.localizedDescription
        }
    }

    private func migrateLegacyLibraryIfNeeded() throws {
        guard let data = preferences.data(forKey: Self.legacyStorageKey) else {
            items = []
            return
        }

        do {
            let decoded = try JSONDecoder().decode(
                [SavedNFCItem].self,
                from: data
            )
            let validated = try validatedItems(decoded)
            items = validated.sorted { $0.createdAt > $1.createdAt }

            try persist(items)
            preferences.removeObject(forKey: Self.legacyStorageKey)
        } catch {
            try preserveLegacyCorruptData(data)
            throw error
        }
    }

    private func preserveLegacyCorruptData(_ data: Data) throws {
        try ensureStorageDirectory()
        let backup = storageURL
            .deletingPathExtension()
            .appendingPathExtension(
                "legacy-corrupt-\(UUID().uuidString).json"
            )

        #if os(iOS)
        try data.write(
            to: backup,
            options: [.atomic, .completeFileProtection]
        )
        #else
        try data.write(to: backup, options: .atomic)
        #endif
    }

    private func validatedItems(
        _ decoded: [SavedNFCItem]
    ) throws -> [SavedNFCItem] {
        try decoded.map { original in
            guard let normalized = NFCRecordContent.normalizedValue(
                for: original.kind,
                value: original.value
            ) else {
                throw LibraryStoreError.invalidStoredItem(original.id)
            }

            var item = original
            item.value = normalized

            let cleanedName = item.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            item.name = cleanedName.isEmpty ? normalized : cleanedName
            return item
        }
    }

    private func save() {
        do {
            try ensureStorageDirectory()
            try persist(items)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func saveScannedCards() {
        do {
            try ensureStorageDirectory()
            let data = try JSONEncoder().encode(scannedCards)
            try writeProtected(data, to: scansStorageURL)
        } catch {
            persistenceError = error.localizedDescription
        }
    }

    private func persist(_ items: [SavedNFCItem]) throws {
        let data = try JSONEncoder().encode(items)
        try writeProtected(data, to: storageURL)
    }

    private func writeProtected(_ data: Data, to url: URL) throws {
        #if os(iOS)
        try data.write(
            to: url,
            options: [.atomic, .completeFileProtection]
        )
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }

    private func ensureStorageDirectory() throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    private func preserveCorruptStoreIfNeeded(at url: URL) {
        guard fileManager.fileExists(atPath: url.path) else { return }

        let backup = url
            .deletingPathExtension()
            .appendingPathExtension("corrupt-\(UUID().uuidString).json")

        try? fileManager.moveItem(at: url, to: backup)
    }
}
