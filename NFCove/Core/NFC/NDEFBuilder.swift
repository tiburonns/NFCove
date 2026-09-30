import CoreNFC
import Foundation

enum NDEFBuilder {
    static func message(
        for kind: NFCRecordKind,
        value: String
    ) -> NFCNDEFMessage? {
        guard let payload = payload(for: kind, value: value) else {
            return nil
        }
        return NFCNDEFMessage(records: [payload])
    }

    static func message(from card: SavedScanCard) -> NFCNDEFMessage? {
        guard !card.records.isEmpty else { return nil }

        let payloads = card.records.compactMap(payload(from:))
        guard payloads.count == card.records.count else { return nil }

        return NFCNDEFMessage(records: payloads)
    }

    static func payload(
        for kind: NFCRecordKind,
        value: String
    ) -> NFCNDEFPayload? {
        guard let normalized = NFCRecordContent.normalizedValue(
            for: kind,
            value: value
        ) else {
            return nil
        }

        switch kind {
        case .text:
            return NFCNDEFPayload.wellKnownTypeTextPayload(
                string: normalized,
                locale: .current
            )
        case .url, .email, .phone, .sms, .location:
            return NFCNDEFPayload.wellKnownTypeURIPayload(string: normalized)
        }
    }

    static func estimatedSize(
        for kind: NFCRecordKind,
        value: String
    ) -> Int {
        message(for: kind, value: value)?.length ?? 0
    }

    private static func payload(
        from record: SavedScanRecord
    ) -> NFCNDEFPayload? {
        if let raw = record.typeNameFormatRaw,
           let format = NFCTypeNameFormat(rawValue: raw),
           let type = record.type,
           let identifier = record.identifier,
           let payload = record.payload {
            return NFCNDEFPayload(
                format: format,
                type: type,
                identifier: identifier,
                payload: payload
            )
        }

        guard let kind = record.kind else { return nil }
        return payload(for: kind, value: record.value)
    }
}
