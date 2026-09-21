import Combine
import CoreNFC
import Foundation

final class NFCSessionManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {
    enum Operation {
        case read
        case write(NFCNDEFMessage)
    }

    @Published private(set) var isActive = false
    @Published private(set) var records: [NFCRecordSnapshot] = []
    @Published private(set) var statusKey = "nfc.status.ready"
    @Published private(set) var lastError: String?
    @Published private(set) var tagCapacity: Int?
    @Published private(set) var tagAccessKey: String?

    private var session: NFCNDEFReaderSession?
    private var operation: Operation = .read

    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    func beginRead() {
        guard NFCNDEFReaderSession.readingAvailable else {
            statusKey = "nfc.status.unavailable"
            return
        }

        resetResult()
        operation = .read

        let reader = NFCNDEFReaderSession(
            delegate: self,
            queue: DispatchQueue.main,
            invalidateAfterFirstRead: false
        )
        reader.alertMessage = AppLocalization.string("nfc.scan.prompt")
        session = reader
        reader.begin()
    }

    func beginWrite(message: NFCNDEFMessage) {
        guard NFCNDEFReaderSession.readingAvailable else {
            statusKey = "nfc.status.unavailable"
            return
        }

        resetResult(keepRecords: true)
        operation = .write(message)

        let reader = NFCNDEFReaderSession(
            delegate: self,
            queue: DispatchQueue.main,
            invalidateAfterFirstRead: false
        )
        reader.alertMessage = AppLocalization.string("nfc.write.prompt")
        session = reader
        reader.begin()
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        isActive = true
        statusKey = "nfc.status.scanning"
    }

    // When readerSession(_:didDetect:) is implemented, Core NFC uses that
    // callback instead of didDetectNDEFs. Keep this required delegate method
    // as a safe fallback.
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard case .read = operation else { return }
        completeRead(messages: messages, session: session)
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = AppLocalization.string("nfc.error.multipleTags")
            session.restartPolling()
            return
        }

        switch operation {
        case .read:
            read(tag: tag, in: session)
        case let .write(message):
            write(message: message, to: tag, in: session)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        isActive = false
        self.session = nil

        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled {
            if statusKey == "nfc.status.scanning" {
                statusKey = "nfc.status.ready"
            }
            return
        }

        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorFirstNDEFTagRead {
            return
        }

        lastError = error.localizedDescription
        statusKey = "nfc.status.failed"
    }

    private func read(tag: NFCNDEFTag, in session: NFCNDEFReaderSession) {
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }

            if let error {
                fail(session: session, error: error)
                return
            }

            tag.queryNDEFStatus { [weak self] status, capacity, error in
                guard let self else { return }

                if let error {
                    fail(session: session, error: error)
                    return
                }

                guard status != .notSupported else {
                    fail(session: session, messageKey: "nfc.error.notSupported")
                    return
                }

                publishTagInfo(status: status, capacity: capacity)

                tag.readNDEF { [weak self] message, error in
                    guard let self else { return }

                    if let readerError = error as? NFCReaderError,
                       readerError.code == .ndefReaderSessionErrorZeroLengthMessage {
                        completeRead(messages: [], session: session)
                        return
                    }

                    if let error {
                        fail(session: session, error: error)
                        return
                    }

                    guard let message else {
                        completeRead(messages: [], session: session)
                        return
                    }

                    completeRead(messages: [message], session: session)
                }
            }
        }
    }

    private func write(message: NFCNDEFMessage, to tag: NFCNDEFTag, in session: NFCNDEFReaderSession) {
        session.connect(to: tag) { [weak self] error in
            guard let self else { return }

            if let error {
                fail(session: session, error: error)
                return
            }

            tag.queryNDEFStatus { [weak self] status, capacity, error in
                guard let self else { return }

                if let error {
                    fail(session: session, error: error)
                    return
                }

                publishTagInfo(status: status, capacity: capacity)

                guard status == .readWrite else {
                    let key = status == .readOnly ? "nfc.error.readOnly" : "nfc.error.notSupported"
                    fail(session: session, messageKey: key)
                    return
                }

                guard message.length <= capacity else {
                    fail(session: session, messageKey: "nfc.error.tooLarge")
                    return
                }

                tag.writeNDEF(message) { [weak self] error in
                    guard let self else { return }

                    if let error {
                        fail(session: session, error: error)
                        return
                    }

                    verify(message: message, on: tag, in: session)
                }
            }
        }
    }

    private func verify(message expected: NFCNDEFMessage, on tag: NFCNDEFTag, in session: NFCNDEFReaderSession) {
        tag.readNDEF { [weak self] actual, error in
            guard let self else { return }

            if error != nil {
                lastError = AppLocalization.string("nfc.error.verification")
                statusKey = "nfc.status.writeUnverified"
                session.alertMessage = AppLocalization.string("nfc.write.unverified")
                session.invalidate()
                return
            }

            guard let actual, Self.messagesMatch(expected, actual) else {
                lastError = AppLocalization.string("nfc.error.verification")
                statusKey = "nfc.status.writeUnverified"
                session.alertMessage = AppLocalization.string("nfc.write.unverified")
                session.invalidate()
                return
            }

            statusKey = "nfc.status.writeVerified"
            records = actual.records.map(Self.snapshot(from:))
            session.alertMessage = AppLocalization.string("nfc.write.verified")
            session.invalidate()
        }
    }

    private func completeRead(messages: [NFCNDEFMessage], session: NFCNDEFReaderSession) {
        records = messages.flatMap(\.records).map(Self.snapshot(from:))
        statusKey = records.isEmpty ? "nfc.status.empty" : "nfc.status.readSuccess"

        session.alertMessage = records.isEmpty
            ? AppLocalization.string("nfc.read.empty")
            : AppLocalization.string("nfc.read.success")
        session.invalidate()
    }

    private func publishTagInfo(status: NFCNDEFStatus, capacity: Int) {
        tagCapacity = capacity

        switch status {
        case .readWrite:
            tagAccessKey = "nfc.access.readWrite"
        case .readOnly:
            tagAccessKey = "nfc.access.readOnly"
        case .notSupported:
            tagAccessKey = "nfc.access.notSupported"
        @unknown default:
            tagAccessKey = "nfc.access.unknown"
        }
    }

    private func fail(session: NFCNDEFReaderSession, error: Error) {
        let description = error.localizedDescription
        lastError = description
        statusKey = "nfc.status.failed"
        session.invalidate(errorMessage: description)
    }

    private func fail(session: NFCNDEFReaderSession, messageKey: String) {
        let message = AppLocalization.string(messageKey)
        lastError = message
        statusKey = "nfc.status.failed"
        session.invalidate(errorMessage: message)
    }

    private func resetResult(keepRecords: Bool = false) {
        if !keepRecords {
            records = []
        }
        lastError = nil
        tagCapacity = nil
        tagAccessKey = nil
    }

    private static func messagesMatch(_ lhs: NFCNDEFMessage, _ rhs: NFCNDEFMessage) -> Bool {
        guard lhs.records.count == rhs.records.count else { return false }

        return zip(lhs.records, rhs.records).allSatisfy { left, right in
            left.typeNameFormat == right.typeNameFormat &&
            left.type == right.type &&
            left.identifier == right.identifier &&
            left.payload == right.payload
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
            } else if value.hasPrefix("sms:") {
                kind = .sms
            } else if value.hasPrefix("geo:") {
                kind = .location
            } else {
                kind = .url
            }

            return NFCRecordSnapshot(
                kind: kind,
                title: AppLocalization.string(kind.localizationKey),
                value: value,
                byteCount: payload.payload.count
            )
        }

        let (text, _) = payload.wellKnownTypeTextPayload()
        if let text {
            return NFCRecordSnapshot(
                kind: .text,
                title: AppLocalization.string(NFCRecordKind.text.localizationKey),
                value: text,
                byteCount: payload.payload.count
            )
        }

        return NFCRecordSnapshot(
            kind: nil,
            title: "NDEF",
            value: payload.payload.map { String(format: "%02X", $0) }.joined(separator: " "),
            byteCount: payload.payload.count
        )
    }
}
