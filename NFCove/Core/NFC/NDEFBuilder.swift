import CoreNFC
import Foundation

enum NDEFBuilder {
    static func message(for kind: NFCRecordKind, value: String) -> NFCNDEFMessage? {
        guard let payload = payload(for: kind, value: value) else { return nil }
        return NFCNDEFMessage(records: [payload])
    }

    static func payload(for kind: NFCRecordKind, value: String) -> NFCNDEFPayload? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        switch kind {
        case .text:
            return NFCNDEFPayload.wellKnownTypeTextPayload(string: trimmed, locale: Locale(identifier: "en"))
        case .url:
            return NFCNDEFPayload.wellKnownTypeURIPayload(string: normalizedURL(trimmed))
        case .email:
            return NFCNDEFPayload.wellKnownTypeURIPayload(string: "mailto:\(trimmed)")
        case .phone:
            return NFCNDEFPayload.wellKnownTypeURIPayload(string: "tel:\(trimmed)")
        }
    }

    static func estimatedSize(for kind: NFCRecordKind, value: String) -> Int {
        guard let payload = payload(for: kind, value: value) else { return 0 }
        return payload.payload.count + payload.type.count + payload.identifier.count + 6
    }

    private static func normalizedURL(_ value: String) -> String {
        if value.contains("://") || value.hasPrefix("mailto:") || value.hasPrefix("tel:") {
            return value
        }
        return "https://\(value)"
    }
}
