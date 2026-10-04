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
        try testSavedCardActions()
        try testScannedTagPersistence()
        try testLegacyScannedTagCompatibility()
        try testLibraryPersistence()
        try testLegacyMigration()
        try testCorruptLegacyMigrationPreservesBytes()
        try testCorruptStorePreservation()
        try testInvalidStoredRecordIsQuarantined()
        try testRepeatedCorruptionCreatesUniqueBackups()

        print(
            "PASS: NFC normalization, saved-card actions, original NDEF persistence, " +
            "legacy compatibility, library persistence, migration, validation, and corrupt-store preservation"
        )
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

        try require(
            NFCRecordContent.normalizedValue(
                for: .sms,
                value: "+52 (81) 1234-5678"
            ) == "sms:+528112345678",
            "SMS normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .location,
                value: "25.6866, -100.3161"
            ) == "geo:25.6866,-100.3161",
            "Location normalization failed"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .location,
                value: "95.0, -100.0"
            ) == nil,
            "Out-of-range latitude was accepted"
        )

        try require(
            NFCRecordContent.normalizedValue(
                for: .location,
                value: "25.0, -181.0"
            ) == nil,
            "Out-of-range longitude was accepted"
        )
    }

    private static func testSavedCardActions() throws {
        try require(
            NFCRecordContent.actionURL(
                for: .text,
                value: "Hello"
            ) == nil,
            "Text should use the local copy action"
        )

        try require(
            NFCRecordContent.actionURL(
                for: .url,
                value: "example.com"
            )?.absoluteString == "https://example.com",
            "Saved URL action resolution failed"
        )

        try require(
            NFCRecordContent.actionURL(
                for: .email,
                value: "hello@example.com"
            )?.scheme == "mailto",
            "Saved email action resolution failed"
        )

        try require(
            NFCRecordContent.actionURL(
                for: .phone,
                value: "+52 81 1234 5678"
            )?.scheme == "tel",
            "Saved phone action resolution failed"
        )

        try require(
            NFCRecordContent.actionURL(
                for: .sms,
                value: "+52 81 1234 5678"
            )?.scheme == "sms",
            "Saved SMS action resolution failed"
        )

        let mapURL = NFCRecordContent.actionURL(
            for: .location,
            value: "25.6866, -100.3161"
        )
        try require(
            mapURL?.host == "maps.apple.com" &&
            mapURL?.absoluteString.contains(
                "ll=25.6866,-100.3161"
            ) == true,
            "Saved location action resolution failed"
        )
    }

    @MainActor
    private static func testScannedTagPersistence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveScans-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        let itemsURL = root.appendingPathComponent("library.json")
        let scansURL = root.appendingPathComponent("scans.json")
        let suiteName = "NFCoveScans.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed(
                "Could not create isolated UserDefaults suite"
            )
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let uriPayload = Data([
            0x04, 0x65, 0x78, 0x61, 0x6D, 0x70,
            0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D
        ])
        let textPayload = Data([
            0x02, 0x65, 0x6E, 0x48, 0x65, 0x6C,
            0x6C, 0x6F
        ])

        let records = [
            NFCRecordSnapshot(
                kind: .url,
                title: "URL",
                value: "https://example.com",
                byteCount: uriPayload.count,
                typeNameFormatRaw: 0x01,
                type: Data([0x55]),
                identifier: Data(),
                payload: uriPayload
            ),
            NFCRecordSnapshot(
                kind: .text,
                title: "Text",
                value: "Hello",
                byteCount: textPayload.count,
                typeNameFormatRaw: 0x01,
                type: Data([0x54]),
                identifier: Data([0x01]),
                payload: textPayload
            )
        ]

        let first = LibraryStore(
            preferences: defaults,
            storageURL: itemsURL,
            scansStorageURL: scansURL
        )
        first.addScannedCard(
            name: "Desk tag",
            records: records,
            tagCapacity: 504,
            tagAccessKey: "nfc.access.readWrite"
        )

        try require(
            first.scannedCards.count == 1,
            "Scanned tag was not added"
        )
        try require(
            first.scannedCards[0].records.count == 2,
            "Scanned tag did not preserve all records"
        )
        try require(
            first.scannedCards[0].tagCapacity == 504,
            "Scanned tag capacity was not preserved"
        )
        try require(
            first.scannedCards[0].hasOriginalNDEF,
            "Original NDEF fields were not preserved"
        )
        try require(
            first.scannedCards[0].records[0].payload == uriPayload,
            "Original URI payload bytes changed"
        )
        try require(
            first.scannedCards[0].records[1].identifier == Data([0x01]),
            "Original NDEF identifier changed"
        )
        try require(
            first.scannedCards[0].records[0].typeHex == "55",
            "Type HEX rendering failed"
        )
        try require(
            FileManager.default.fileExists(
                atPath: scansURL.path
            ),
            "Scanned tag store was not created"
        )

        let second = LibraryStore(
            preferences: defaults,
            storageURL: itemsURL,
            scansStorageURL: scansURL
        )
        try require(
            second.scannedCards == first.scannedCards,
            "Scanned tag did not round-trip from disk"
        )
        try require(
            second.scannedCards[0].hasOriginalNDEF,
            "Original NDEF availability was lost after reload"
        )

        second.deleteScannedCard(
            at: IndexSet(integer: 0)
        )
        let third = LibraryStore(
            preferences: defaults,
            storageURL: itemsURL,
            scansStorageURL: scansURL
        )
        try require(
            third.scannedCards.isEmpty,
            "Scanned tag deletion did not persist"
        )
    }

    private static func testLegacyScannedTagCompatibility() throws {
        let legacy = SavedScanCard(
            name: "Legacy scan",
            records: [
                SavedScanRecord(
                    kind: .url,
                    title: "URL",
                    value: "https://example.com",
                    byteCount: 19
                )
            ],
            tagCapacity: 144,
            tagAccessKey: "nfc.access.readWrite",
            scannedAt: Date(timeIntervalSince1970: 1_000)
        )

        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(
            SavedScanCard.self,
            from: data
        )

        try require(
            !decoded.hasOriginalNDEF,
            "Legacy scan incorrectly reported an exact NDEF copy"
        )
        try require(
            decoded.canRebuildNDEF,
            "Recognized legacy scan should remain reconstructable"
        )
    }

    @MainActor
    private static func testLibraryPersistence() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveTests-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("library.json")
        let suiteName = "NFCoveTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed(
                "Could not create isolated UserDefaults suite"
            )
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let first = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        first.add(
            name: "",
            kind: .url,
            value: "example.com"
        )

        try require(
            first.items.count == 1,
            "Library did not add an item"
        )
        try require(
            first.items[0].name == "https://example.com",
            "Fallback item name was not normalized"
        )
        try require(
            first.items[0].value == "https://example.com",
            "Stored value was not normalized"
        )
        try require(
            FileManager.default.fileExists(atPath: url.path),
            "Library file was not created"
        )

        let second = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        try require(
            second.items == first.items,
            "Library did not round-trip from disk"
        )

        second.delete(at: IndexSet(integer: 0))
        let third = LibraryStore(
            preferences: defaults,
            storageURL: url
        )
        try require(
            third.items.isEmpty,
            "Deletion did not persist"
        )
    }

    @MainActor
    private static func testLegacyMigration() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveMigration-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("library.json")
        let suiteName = "NFCoveMigration.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw TestFailure.failed(
                "Could not create migration UserDefaults suite"
            )
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

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

        try require(
            store.items == legacy,
            "Legacy library was not migrated"
        )
        try require(
            defaults.data(
                forKey: "nfcove.library.items"
            ) == nil,
            "Legacy key was not removed after migration"
        )
        try require(
            FileManager.default.fileExists(atPath: url.path),
            "Migrated library file was not created"
        )
    }

    @MainActor
    private static func testCorruptLegacyMigrationPreservesBytes()
        throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveLegacyCorrupt-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        let url = root.appendingPathComponent("library.json")
        let suiteName =
            "NFCoveLegacyCorrupt.\(UUID().uuidString)"
        guard let defaults = UserDefaults(
            suiteName: suiteName
        ) else {
            throw TestFailure.failed(
                "Could not create isolated UserDefaults suite"
            )
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let legacyBytes = Data("invalid-legacy-json".utf8)
        defaults.set(
            legacyBytes,
            forKey: "nfcove.library.items"
        )

        let store = LibraryStore(
            preferences: defaults,
            storageURL: url
        )

        try require(
            store.items.isEmpty,
            "Corrupt legacy migration produced active items"
        )
        try require(
            store.persistenceError != nil,
            "Corrupt legacy migration did not surface an error"
        )
        try require(
            defaults.data(
                forKey: "nfcove.library.items"
            ) == legacyBytes,
            "Corrupt legacy source was deleted before recovery"
        )

        let backups = try FileManager.default
            .contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil
            )
            .filter {
                $0.lastPathComponent.contains(
                    ".legacy-corrupt-"
                )
            }
        try require(
            backups.count == 1,
            "Corrupt legacy bytes were not preserved exactly once"
        )
        let recoveredBytes = try Data(contentsOf: backups[0])
        try require(
            recoveredBytes == legacyBytes,
            "Corrupt legacy recovery file changed original bytes"
        )
    }

    @MainActor
    private static func testCorruptStorePreservation() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveCorrupt-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        let url = root.appendingPathComponent("library.json")
        try Data("not-json".utf8).write(to: url)

        let store = LibraryStore(storageURL: url)
        try require(
            store.items.isEmpty,
            "Corrupt library should not produce items"
        )
        try require(
            store.persistenceError != nil,
            "Corrupt library did not surface an error"
        )
        try require(
            !FileManager.default.fileExists(atPath: url.path),
            "Corrupt primary store was not moved aside"
        )

        let backups = try FileManager.default
            .contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil
            )
        try require(
            backups.contains {
                $0.lastPathComponent.contains(".corrupt-")
            },
            "Corrupt library backup was not preserved"
        )
    }

    @MainActor
    private static func testInvalidStoredRecordIsQuarantined()
        throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveInvalidStore-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        let url = root.appendingPathComponent("library.json")
        let invalid = [
            SavedNFCItem(
                name: "Bad URL",
                kind: .url,
                value: "https://"
            )
        ]
        try JSONEncoder().encode(invalid).write(to: url)

        let store = LibraryStore(storageURL: url)
        try require(
            store.items.isEmpty,
            "Invalid stored record became active"
        )
        try require(
            store.persistenceError != nil,
            "Invalid stored record did not surface an error"
        )
        try require(
            !FileManager.default.fileExists(atPath: url.path),
            "Invalid store was not quarantined"
        )
    }

    @MainActor
    private static func testRepeatedCorruptionCreatesUniqueBackups()
        throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "NFCoveRepeatedCorruption-\(UUID().uuidString)",
                isDirectory: true
            )
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )

        let url = root.appendingPathComponent("library.json")

        try Data("first-corruption".utf8).write(to: url)
        _ = LibraryStore(storageURL: url)

        try Data("second-corruption".utf8).write(to: url)
        _ = LibraryStore(storageURL: url)

        let backups = try FileManager.default
            .contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil
            )
            .filter {
                $0.lastPathComponent.contains(".corrupt-")
            }

        try require(
            backups.count == 2,
            "Repeated corruption did not create unique backups"
        )
    }
}
