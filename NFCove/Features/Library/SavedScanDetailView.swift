import CoreNFC
import Foundation
import SwiftUI

struct SavedScanDetailView: View {
    let card: SavedScanCard
    @ObservedObject var manager: NFCSessionManager

    private var message: NFCNDEFMessage? {
        NDEFBuilder.message(from: card)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        card.name,
                        systemImage: "sensor.tag.radiowaves.forward"
                    )
                    .font(.title3.bold())

                    HStack(spacing: 14) {
                        Label {
                            Text(card.scannedAt, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }

                        if let capacity = card.tagCapacity {
                            Label(
                                "\(capacity) B",
                                systemImage: "externaldrive"
                            )
                            .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let accessKey = card.tagAccessKey {
                        Label {
                            Text(LocalizedStringKey(accessKey))
                        } icon: {
                            Image(systemName: "lock.open.display")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }

            Section {
                LabeledContent(
                    "library.scan.recordCount",
                    value: "\(card.records.count)"
                )
                LabeledContent(
                    "library.scan.payloadBytes",
                    value: "\(card.totalPayloadBytes) B"
                )
                LabeledContent("library.scan.copyQuality") {
                    if card.hasOriginalNDEF {
                        Text("library.scan.copyQuality.exact")
                    } else {
                        Text("library.scan.copyQuality.reconstructed")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("library.scan.info.section")
            }

            Section {
                Button {
                    if let message {
                        manager.beginWrite(message: message)
                    }
                } label: {
                    Label(
                        "library.scan.write",
                        systemImage: "wave.3.right"
                    )
                    .frame(maxWidth: .infinity)
                }
                .disabled(
                    message == nil ||
                    manager.isActive ||
                    !manager.isNFCAvailable
                )
                .accessibilityHint("library.scan.write.hint")
            } footer: {
                if card.hasOriginalNDEF {
                    Text("library.scan.write.footer.exact")
                } else {
                    Text("library.scan.write.footer.reconstructed")
                }
            }

            if manager.isActive ||
                manager.statusKey != "nfc.status.ready" ||
                manager.lastError != nil {
                Section {
                    if manager.isActive ||
                        manager.statusKey != "nfc.status.ready" {
                        Label {
                            Text(
                                LocalizedStringKey(manager.statusKey)
                            )
                        } icon: {
                            Image(
                                systemName: manager.isActive
                                    ? "wave.3.right.circle.fill"
                                    : "info.circle"
                            )
                        }
                    }

                    if let error = manager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }

            Section("library.scan.records.section") {
                ForEach(card.records) { record in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label {
                                if let kind = record.kind {
                                    Text(
                                        LocalizedStringKey(
                                            kind.localizationKey
                                        )
                                    )
                                } else {
                                    Text("record.custom")
                                }
                            } icon: {
                                Image(
                                    systemName: record.kind?.icon
                                        ?? "doc.text"
                                )
                            }
                            .font(.headline)

                            Spacer()

                            Text("\(record.byteCount) B")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        Text(record.value)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)

                        DisclosureGroup(
                            "library.scan.technicalDetails"
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                LabeledContent(
                                    "library.scan.tnf",
                                    value: record.typeNameFormatRaw.map {
                                        String(
                                            format: "0x%02X",
                                            $0
                                        )
                                    } ?? "—"
                                )

                                technicalValue(
                                    title: "library.scan.type",
                                    value: record.typeHex
                                )
                                technicalValue(
                                    title: "library.scan.identifier",
                                    value: record.identifierHex
                                )
                                technicalValue(
                                    title: "library.scan.payload",
                                    value: record.payloadHex
                                )
                            }
                            .padding(.top, 8)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("library.scan.detail.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func technicalValue(
        title: LocalizedStringKey,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
    }
}
