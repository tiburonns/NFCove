import CoreNFC
import Foundation

final class NFCSessionManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    enum Operation {
        case read
        case write(NFCNDEFMessage)
    }

    @Published private(set) var isActive = false
    @Published private(set) var records: [NFCRecordSnapshot] = []
    @Published private(set) var statusKey = "nfc.status.ready"
    @Published private(set) var lastError: String?

    private var session: NFCNDEFReaderSession?
    private var operation: Operation = .read

    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    func beginRead() {
        guard NFCNDEFReaderSession.readingAvailable else {
            publish(status: "nfc.status.unavailable")
            return
        }

        records = []
        lastError = nil
        operation = .read

        let reader = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        reader.alertMessage = AppLocalization.string("nfc.scan.prompt")
        session = reader
        reader.begin()
    }

    func beginWrite(message: NFCNDEFMessage) {
        guard NFCNDEFReaderSession.readingAvailable else {
            publish(status: "nfc.status.unavailable")
            return
        }

        lastError = nil
        operation = .write(message)

        let reader = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false
        )
        reader.alertMessage = AppLocalization.string("nfc.write.prompt")
        session = reader
        reader.begin()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isActive = true
            self?.statusKey = "nfc.status.scanning"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard case .read = operation else { return }

        let snapshots = messages.flatMap(\.records).map(Self.snapshot(from:))

        DispatchQueue.main.async { [weak self] in
            self?.records = snapshots
            self?.statusKey = snapshots.isEmpty ? "nfc.status.empty" : "nfc.status.readSuccess"
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard case let .write(message) = operation else { return }

        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = AppLocalization.string("nfc.error.multipleTags")
            session.restartPolling()
            return
        }

        session.connect(to: tag) { [weak self] error in
            if let error {
                self?.fail(session: session, error: error)
                return
            }

            tag.queryNDEFStatus { [weak self] status, capacity, error in
                if let error {
                    self?.fail(session: session, error: error)
                    return
                }

                guard status == .readWrite else {
                    let key = status == .readOnly ? "nfc.error.readOnly" : "nfc.error.notSupported"
                    self?.fail(session: session, messageKey: key)
                    return
                }

                guard Self.estimatedMessageSize(message) <= capacity else {
                    self?.fail(session: session, messageKey: "nfc.error.tooLarge")
                    return
                }

                tag.writeNDEF(message) { [weak self] error in
                    if let error {
                        self?.fail(session: session, error: error)
                        return
                    }

                    session.alertMessage = AppLocalization.string("nfc.write.success")
                    session.invalidate()
                    DispatchQueue.main.async {
                        self?.statusKey = "nfc.status.writeSuccess"
                    }
                }
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isActive = false
            self?.session = nil

            if let readerError = error as? NFCReaderError,
               readerError.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
                return
            }

            if let readerError = error as? NFCReaderError,
               readerError.code == .readerSessionInvalidationErrorUserCanceled {
                self?.statusKey = "nfc.status.ready"
                return
            }

            self?.lastError = error.localizedDescription
            self?.statusKey = "nfc.status.failed"
        }
    }

    private func fail(session: NFCNDEFReaderSession, error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = error.localizedDescription
            self?.statusKey = "nfc.status.failed"
        }
        session.invalidate(errorMessage: error.localizedDescription)
    }

    private func fail(session: NFCNDEFReaderSession, messageKey: String) {
        let message = AppLocalization.string(messageKey)
        DispatchQueue.main.async { [weak self] in
            self?.lastError = message
            self?.statusKey = "nfc.status.failed"
        }
        session.invalidate(errorMessage: message)
    }

    private func publish(status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusKey = status
        }
    }

    private static func estimatedMessageSize(_ message: NFCNDEFMessage) -> Int {
        message.records.reduce(0) { result, payload in
            result + payload.payload.count + payload.type.count + payload.identifier.count + 6
        }
    }

    private static func snapshot(from payload: NFCNDEFPayload) -> NFCRecordSnapshot {
        if let url = payload.wellKnownTypeURIPayload() {
            let value = url.absoluteString
            let kind: NFCRecordKind
            if value.hasPrefix("mailto:") {
                kind = .email
            } else if value.hasPrefix("tel:") {
                kind = .phone
            } else {
                kind = .url
            }

            return NFCRecordSnapshot(kind: kind, title: kind.rawValue.capitalized, value: value, byteCount: payload.payload.count)
        }

        let (text, _) = payload.wellKnownTypeTextPayload()
        if let text {
            return NFCRecordSnapshot(kind: .text, title: "Text", value: text, byteCount: payload.payload.count)
        }

        return NFCRecordSnapshot(
            kind: nil,
            title: "NDEF",
            value: payload.payload.map { String(format: "%02X", $0) }.joined(separator: " "),
            byteCount: payload.payload.count
        )
    }
}
