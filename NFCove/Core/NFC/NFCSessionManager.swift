import Combine
@preconcurrency import CoreNFC
import Foundation

final class NFCSessionManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {
    private struct TagContext: @unchecked Sendable {
        let tag: NFCNDEFTag
        let session: NFCNDEFReaderSession
    }

    private struct WriteContext: @unchecked Sendable {
        let message: NFCNDEFMessage
        let tag: NFCNDEFTag
        let session: NFCNDEFReaderSession
    }

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

    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetectNDEFs messages: [NFCNDEFMessage]
    ) {
        guard case .read = operation else { return }
        completeRead(messages: messages, session: session)
    }

    func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetect tags: [NFCNDEFTag]
    ) {
        guard tags.count == 1, let tag = tags.first else {
            session.alertMessage = AppLocalization.string(
                "nfc.error.multipleTags"
            )
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

    func readerSession(
        _ session: NFCNDEFReaderSession,
        didInvalidateWithError error: Error
    ) {
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
           readerError.code == .readerSessionInvalidationErrorFirstNDEFTagRead,
           statusKey != "nfc.status.scanning" {
            return
        }

        lastError = Self.userFacingMessage(for: error)
        statusKey = "nfc.status.failed"
    }

    private func read(
        tag: NFCNDEFTag,
        in session: NFCNDEFReaderSession
    ) {
        let context = TagContext(tag: tag, session: session)

        context.session.connect(to: context.tag) { [weak self, context] error in
            guard let self else { return }

            if let error {
                fail(session: context.session, error: error)
                return
            }

            context.tag.queryNDEFStatus { [weak self, context] status, capacity, error in
                guard let self else { return }

                if let error {
                    fail(session: context.session, error: error)
                    return
                }

                guard status != .notSupported else {
                    fail(
                        session: context.session,
                        messageKey: "nfc.error.notSupported"
                    )
                    return
                }

                publishTagInfo(status: status, capacity: capacity)

                context.tag.readNDEF { [weak self, context] message, error in
                    guard let self else { return }

                    if let readerError = error as? NFCReaderError,
                       readerError.code == .ndefReaderSessionErrorZeroLengthMessage {
                        completeRead(messages: [], session: context.session)
                        return
                    }

                    if let error {
                        fail(session: context.session, error: error)
                        return
                    }

                    guard let message else {
                        completeRead(messages: [], session: context.session)
                        return
                    }

                    completeRead(messages: [message], session: context.session)
                }
            }
        }
    }

    private func write(
        message: NFCNDEFMessage,
        to tag: NFCNDEFTag,
        in session: NFCNDEFReaderSession
    ) {
        let context = WriteContext(
            message: message,
            tag: tag,
            session: session
        )

        context.session.connect(to: context.tag) { [weak self, context] error in
            guard let self else { return }

            if let error {
                fail(session: context.session, error: error)
                return
            }

            context.tag.queryNDEFStatus { [weak self, context] status, capacity, error in
                guard let self else { return }

                if let error {
                    fail(session: context.session, error: error)
                    return
                }

                publishTagInfo(status: status, capacity: capacity)

                guard status == .readWrite else {
                    let key = status == .readOnly
                        ? "nfc.error.readOnly"
                        : "nfc.error.notSupported"
                    fail(session: context.session, messageKey: key)
                    return
                }

                guard context.message.length <= capacity else {
                    fail(
                        session: context.session,
                        messageKey: "nfc.error.tooLarge"
                    )
                    return
                }

                context.tag.writeNDEF(context.message) { [weak self, context] error in
                    guard let self else { return }

                    if let error {
                        fail(session: context.session, error: error)
                        return
                    }

                    verify(
                        message: context.message,
                        on: context.tag,
                        in: context.session
                    )
                }
            }
        }
    }

    private func verify(
        message expected: NFCNDEFMessage,
        on tag: NFCNDEFTag,
        in session: NFCNDEFReaderSession
    ) {
        let context = WriteContext(
            message: expected,
            tag: tag,
            session: session
        )

        context.tag.readNDEF { [weak self, context] actual, error in
            guard let self else { return }

            if error != nil {
                lastError = AppLocalization.string(
                    "nfc.error.verification"
                )
                statusKey = "nfc.status.writeUnverified"
                context.session.alertMessage = AppLocalization.string(
                    "nfc.write.unverified"
                )
                context.session.invalidate()
                return
            }

            guard let actual,
                  Self.messagesMatch(context.message, actual) else {
                lastError = AppLocalization.string(
                    "nfc.error.verification"
                )
                statusKey = "nfc.status.writeUnverified"
                context.session.alertMessage = AppLocalization.string(
                    "nfc.write.unverified"
                )
                context.session.invalidate()
                return
            }

            statusKey = "nfc.status.writeVerified"
            records = actual.records.map(Self.snapshot(from:))
            context.session.alertMessage = AppLocalization.string(
                "nfc.write.verified"
            )
            context.session.invalidate()
        }
    }

    private func completeRead(
        messages: [NFCNDEFMessage],
        session: NFCNDEFReaderSession
    ) {
        records = messages
            .flatMap(\.records)
            .map(Self.snapshot(from:))

        statusKey = records.isEmpty
            ? "nfc.status.empty"
            : "nfc.status.readSuccess"

        session.alertMessage = records.isEmpty
            ? AppLocalization.string("nfc.read.empty")
            : AppLocalization.string("nfc.read.success")
        session.invalidate()
    }

    private func publishTagInfo(
        status: NFCNDEFStatus,
        capacity: Int
    ) {
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

    private func fail(
        session: NFCNDEFReaderSession,
        error: Error
    ) {
        let description = Self.userFacingMessage(for: error)
        lastError = description
        statusKey = "nfc.status.failed"
        session.invalidate(errorMessage: description)
    }

    private func fail(
        session: NFCNDEFReaderSession,
        messageKey: String
    ) {
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

    private static func messagesMatch(
        _ lhs: NFCNDEFMessage,
        _ rhs: NFCNDEFMessage
    ) -> Bool {
        guard lhs.records.count == rhs.records.count else {
            return false
        }

        return zip(lhs.records, rhs.records).allSatisfy { left, right in
            left.typeNameFormat == right.typeNameFormat &&
            left.type == right.type &&
            left.identifier == right.identifier &&
            left.payload == right.payload
        }
    }

    private static func snapshot(
        from payload: NFCNDEFPayload
    ) -> NFCRecordSnapshot {
        let rawFields = (
            typeNameFormatRaw: payload.typeNameFormat.rawValue,
            type: payload.type,
            identifier: payload.identifier,
            payload: payload.payload
        )

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
                byteCount: payload.payload.count,
                typeNameFormatRaw: rawFields.typeNameFormatRaw,
                type: rawFields.type,
                identifier: rawFields.identifier,
                payload: rawFields.payload
            )
        }

        let (text, _) = payload.wellKnownTypeTextPayload()
        if let text {
            return NFCRecordSnapshot(
                kind: .text,
                title: AppLocalization.string(
                    NFCRecordKind.text.localizationKey
                ),
                value: text,
                byteCount: payload.payload.count,
                typeNameFormatRaw: rawFields.typeNameFormatRaw,
                type: rawFields.type,
                identifier: rawFields.identifier,
                payload: rawFields.payload
            )
        }

        return NFCRecordSnapshot(
            kind: nil,
            title: "NDEF",
            value: payload.payload
                .map { String(format: "%02X", $0) }
                .joined(separator: " "),
            byteCount: payload.payload.count,
            typeNameFormatRaw: rawFields.typeNameFormatRaw,
            type: rawFields.type,
            identifier: rawFields.identifier,
            payload: rawFields.payload
        )
    }

    private static func userFacingMessage(
        for error: Error
    ) -> String {
        guard let readerError = error as? NFCReaderError else {
            return error.localizedDescription
        }

        let key: String?
        switch readerError.code {
        case .readerSessionInvalidationErrorSessionTimeout:
            key = "nfc.error.timeout"
        case .readerSessionInvalidationErrorSystemIsBusy:
            key = "nfc.error.systemBusy"
        case .readerTransceiveErrorTagConnectionLost,
             .readerTransceiveErrorTagNotConnected:
            key = "nfc.error.tagMoved"
        case .ndefReaderSessionErrorTagNotWritable:
            key = "nfc.error.readOnly"
        case .ndefReaderSessionErrorTagSizeTooSmall:
            key = "nfc.error.tooLarge"
        case .readerErrorRadioDisabled:
            key = "nfc.error.radioDisabled"
        default:
            key = nil
        }

        return key.map { AppLocalization.string($0) }
            ?? error.localizedDescription
    }
}
