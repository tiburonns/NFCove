import Foundation

enum NFCRecordKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case text
    case url
    case email
    case phone

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .text: return "text.alignleft"
        case .url: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        }
    }

    var localizationKey: String {
        switch self {
        case .text: return "record.text"
        case .url: return "record.url"
        case .email: return "record.email"
        case .phone: return "record.phone"
        }
    }

    var placeholderKey: String {
        switch self {
        case .text: return "create.placeholder.text"
        case .url: return "create.placeholder.url"
        case .email: return "create.placeholder.email"
        case .phone: return "create.placeholder.phone"
        }
    }
}

struct NFCRecordSnapshot: Identifiable, Hashable, Sendable {
    let id = UUID()
    let kind: NFCRecordKind?
    let title: String
    let value: String
    let byteCount: Int
}

struct SavedNFCItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var name: String
    var kind: NFCRecordKind
    var value: String
    let createdAt: Date

    init(id: UUID = UUID(), name: String, kind: NFCRecordKind, value: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.kind = kind
        self.value = value
        self.createdAt = createdAt
    }
}
