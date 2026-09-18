import CoreNFC
import Foundation

enum NDEFBuilder {
    static func message(for kind: NFCRecordKind, value: String) -> NFCNDEFMessage? {
        guard let payload = payload(for: kind, value: value) else { return nil }
        return NFCNDEFMessage(records: [payload])
    }

    static func payload(for kind: NFCRecordKind, value: String) -> NFCNDEFPayload? {
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
        case .url, .email, .phone:
            return NFCNDEFPayload.wellKnownTypeURIPayload(string: normalized)
        }
    }

    static func estimatedSize(for kind: NFCRecordKind, value: String) -> Int {
        message(for: kind, value: value)?.length ?? 0
    }
}
