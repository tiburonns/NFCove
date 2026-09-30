import Foundation

enum NFCRecordContent {
    static func normalizedValue(
        for kind: NFCRecordKind,
        value: String
    ) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch kind {
        case .text:
            return trimmed

        case .url:
            let candidate: String
            if let scheme = URLComponents(string: trimmed)?.scheme,
               !scheme.isEmpty {
                candidate = trimmed
            } else {
                candidate = "https://\(trimmed)"
            }

            guard let components = URLComponents(string: candidate),
                  let scheme = components.scheme,
                  !scheme.isEmpty,
                  components.url != nil else {
                return nil
            }

            if scheme == "http" || scheme == "https" {
                guard let host = components.host, !host.isEmpty else {
                    return nil
                }
            }
            return components.url?.absoluteString

        case .email:
            let address = trimmed
                .replacingOccurrences(
                    of: "mailto:",
                    with: "",
                    options: [.anchored, .caseInsensitive]
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let pieces = address.split(
                separator: "@",
                omittingEmptySubsequences: false
            )
            guard pieces.count == 2,
                  !pieces[0].isEmpty,
                  !pieces[1].isEmpty,
                  !address.contains(where: { $0.isWhitespace }) else {
                return nil
            }

            var components = URLComponents()
            components.scheme = "mailto"
            components.path = address
            return components.url?.absoluteString

        case .phone:
            guard let compact = normalizedDialString(
                trimmed,
                removingScheme: "tel:"
            ) else {
                return nil
            }
            return "tel:\(compact)"

        case .sms:
            guard let compact = normalizedDialString(
                trimmed,
                removingScheme: "sms:"
            ) else {
                return nil
            }
            return "sms:\(compact)"

        case .location:
            let raw = trimmed.replacingOccurrences(
                of: "geo:",
                with: "",
                options: [.anchored, .caseInsensitive]
            )
            let pieces = raw.split(
                separator: ",",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            guard pieces.count == 2,
                  let latitude = Double(
                    pieces[0].trimmingCharacters(in: .whitespacesAndNewlines)
                  ),
                  let longitude = Double(
                    pieces[1].trimmingCharacters(in: .whitespacesAndNewlines)
                  ),
                  (-90...90).contains(latitude),
                  (-180...180).contains(longitude) else {
                return nil
            }

            return "geo:\(coordinateString(latitude)),\(coordinateString(longitude))"
        }
    }

    static func actionURL(
        for kind: NFCRecordKind,
        value: String
    ) -> URL? {
        guard let normalized = normalizedValue(for: kind, value: value) else {
            return nil
        }

        switch kind {
        case .text:
            return nil
        case .url, .email, .phone, .sms:
            return URL(string: normalized)
        case .location:
            let coordinates = normalized.dropFirst("geo:".count)
            var components = URLComponents(string: "https://maps.apple.com/")
            components?.queryItems = [
                URLQueryItem(name: "ll", value: String(coordinates))
            ]
            return components?.url
        }
    }

    private static func normalizedDialString(
        _ value: String,
        removingScheme scheme: String
    ) -> String? {
        let raw = value.replacingOccurrences(
            of: scheme,
            with: "",
            options: [.anchored, .caseInsensitive]
        )
        let formatting = CharacterSet(charactersIn: " ()-.")
        let compact = raw.unicodeScalars
            .filter { !formatting.contains($0) }
            .map(String.init)
            .joined()

        let allowed = CharacterSet(charactersIn: "+*#0123456789,;")
        guard !compact.isEmpty,
              compact.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              compact.unicodeScalars.contains(where: {
                  CharacterSet.decimalDigits.contains($0)
              }),
              !compact.dropFirst().contains("+") else {
            return nil
        }

        return compact
    }

    private static func coordinateString(_ value: Double) -> String {
        var result = String(
            format: "%.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
        while result.contains(".") && result.last == "0" {
            result.removeLast()
        }
        if result.last == "." {
            result.removeLast()
        }
        return result
    }
}

enum NFCRecordKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case text
    case url
    case email
    case phone
    case sms
    case location

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        case .sms: return "message"
        case .location: return "location"
        }
    }

    var localizationKey: String {
        switch self {
        case .text: return "record.text"
        case .url: return "record.url"
        case .email: return "record.email"
        case .phone: return "record.phone"
        case .sms: return "record.sms"
        case .location: return "record.location"
        }
    }

    var placeholderKey: String {
        switch self {
        case .text: return "create.placeholder.text"
        case .url: return "create.placeholder.url"
        case .email: return "create.placeholder.email"
        case .phone: return "create.placeholder.phone"
        case .sms: return "create.placeholder.sms"
        case .location: return "create.placeholder.location"
        }
    }
}

struct NFCRecordSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let kind: NFCRecordKind?
    let title: String
    let value: String
    let byteCount: Int
    let typeNameFormatRaw: UInt8?
    let type: Data?
    let identifier: Data?
    let payload: Data?

    init(
        id: UUID = UUID(),
        kind: NFCRecordKind?,
        title: String,
        value: String,
        byteCount: Int,
        typeNameFormatRaw: UInt8? = nil,
        type: Data? = nil,
        identifier: Data? = nil,
        payload: Data? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.value = value
        self.byteCount = byteCount
        self.typeNameFormatRaw = typeNameFormatRaw
        self.type = type
        self.identifier = identifier
        self.payload = payload
    }
}

struct SavedNFCItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: NFCRecordKind
    var value: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        kind: NFCRecordKind,
        value: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.value = value
        self.createdAt = createdAt
    }
}

struct SavedScanRecord: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let kind: NFCRecordKind?
    let title: String
    let value: String
    let byteCount: Int

    // These fields preserve the original NDEF record byte-for-byte for
    // scans created by NFCove 0.4.0 and later. They are optional so scans
    // saved by older versions remain readable.
    let typeNameFormatRaw: UInt8?
    let type: Data?
    let identifier: Data?
    let payload: Data?

    init(
        id: UUID = UUID(),
        kind: NFCRecordKind?,
        title: String,
        value: String,
        byteCount: Int,
        typeNameFormatRaw: UInt8? = nil,
        type: Data? = nil,
        identifier: Data? = nil,
        payload: Data? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.value = value
        self.byteCount = byteCount
        self.typeNameFormatRaw = typeNameFormatRaw
        self.type = type
        self.identifier = identifier
        self.payload = payload
    }

    init(snapshot: NFCRecordSnapshot) {
        self.init(
            kind: snapshot.kind,
            title: snapshot.title,
            value: snapshot.value,
            byteCount: snapshot.byteCount,
            typeNameFormatRaw: snapshot.typeNameFormatRaw,
            type: snapshot.type,
            identifier: snapshot.identifier,
            payload: snapshot.payload
        )
    }

    var hasOriginalNDEF: Bool {
        typeNameFormatRaw != nil &&
        type != nil &&
        identifier != nil &&
        payload != nil
    }

    var typeHex: String { Self.hex(type) }
    var identifierHex: String { Self.hex(identifier) }
    var payloadHex: String { Self.hex(payload) }

    private static func hex(_ data: Data?) -> String {
        guard let data else { return "—" }
        if data.isEmpty { return "—" }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}

struct SavedScanCard: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    let records: [SavedScanRecord]
    let tagCapacity: Int?
    let tagAccessKey: String?
    let scannedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        records: [SavedScanRecord],
        tagCapacity: Int?,
        tagAccessKey: String?,
        scannedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.records = records
        self.tagCapacity = tagCapacity
        self.tagAccessKey = tagAccessKey
        self.scannedAt = scannedAt
    }

    var totalPayloadBytes: Int {
        records.reduce(0) { $0 + $1.byteCount }
    }

    var hasOriginalNDEF: Bool {
        !records.isEmpty && records.allSatisfy(\.hasOriginalNDEF)
    }

    var canRebuildNDEF: Bool {
        !records.isEmpty &&
        records.allSatisfy { $0.hasOriginalNDEF || $0.kind != nil }
    }
}
