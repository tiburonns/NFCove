import Foundation

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

@main
struct NFCoveCoreLogicIntegration {
    @MainActor
    static func main() throws {
        try testContentNormalization()
        try testLibraryPersistence()
        try testLegacyMigration()
        try testCorruptStorePreservation()
        print("PASS: NFC normalization, library persistence, migration, and corrupt-store preservation")
    }

    private static func require(
        _ condition: @autoclosure () -> Bool,
        _ message: String
    ) throws {
        guard condition() else {
            throw TestFailure.failed(message)
        }
    }

    private static func testContentNormalization() throws {
        try require(
            NFCRecordContent.normalizedValue(
                for: .text,
                value: "  Hello NFC  "
            ) == "Hello NFC",
            "Text normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .url,
                value: "example.com/path"
            ) == "https://example.com/path",
            "URL scheme normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .url,
                value: "https://example.com/a"
            ) == "https://example.com/a",
            "Existing URL scheme was changed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .email,
                value: " hello@example.com "
            ) == "mailto:hello@example.com",
            "Email normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .email,
                value: "not-an-email"
            ) == nil,
            "Invalid email was accepted"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .phone,
                value: "+52 (81) 1234-5678"
            ) == "tel:+528112345678",
            "Phone normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .phone,
                value: "call-me"
            ) == nil,
            "Invalid phone number was accepted"
        )
    }

    @MainActor
    private static func testLibraryPersistence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NFCoveTests-(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("library.json")
        let suiteName = "NFCoveTests.(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed("Could not create isolated UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        first.add(
            name: "",
            kind: .url,
            value: "example.com"
        )

        try require(first.items.count == 1, "Library did not add an item")
        try require(first.items[0].name == "https://example.com", "Fallback item name was not normalized")
        try require(first.items[0].value == "https://example.com", "Stored value was not normalized")
        try require(FileManager.default.fileExists(atPath: url.path), "Library file was not created")

        let second = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        try require(second.items == first.items, "Library did not round-trip from disk")

        second.delete(at: IndexSet(integer: 0))
        let third = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        try require(third.items.isEmpty, "Deletion did not persist")
    }

    @MainActor
    private static func testLegacyMigration() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NFCoveMigration-(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("library.json")
        let suiteName = "NFCoveMigration.(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed("Could not create migration UserDefaults suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let legacy = [
            SavedNFCItem(
                name: "Migrated",
                kind: .text,
                value: "Hello",
                createdAt: Date(timeIntervalSince1970: 1_000)
            )
        ]

        defaults.set(
            try JSONEncoder().encode(legacy),
            forKey: "nfcove.library.items"
        )

        let store = LibraryStore(
            preferences: defaults,
            storageURL: url
        )

        try require(store.items == legacy, "Legacy library was not migrated")
        try require(defaults.data(forKey: "nfcove.library.items") == nil, "Legacy key was not removed after migration")
        try require(FileManager.default.fileExists(atPath: url.path), "Migrated library file was not created")
    }

    @MainActor
    private static func testCorruptStorePreservation() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("NFCoveCorrupt-(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        let url = root.appendingPathComponent("library.json")
        try Data("not-json".utf8).write(to: url)

        let store = LibraryStore(storageURL: url)
        try require(store.items.isEmpty, "Corrupt library should not produce items")
        try require(store.persistenceError != nil, "Corrupt library did not surface an error")
        try require(!FileManager.default.fileExists(atPath: url.path), "Corrupt primary store was not moved aside")

        let backups = try FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil
        )
        try require(
            backups.contains(where: { $0.lastPathComponent.contains(".corrupt-") }),
            "Corrupt library backup was not preserved"
        )
    }
}
