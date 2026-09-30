import SwiftUI

struct SavedScanDetailView: View {
    let card: SavedScanCard

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label(card.name, systemImage: "sensor.tag.radiowaves.forward")
                        .font(.title3.bold())

                    HStack(spacing: 14) {
                        Label {
                            Text(card.scannedAt, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }

                        if let capacity = card.tagCapacity {
                            Label("\(capacity) B", systemImage: "externaldrive")
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
            } header: {
                Text("library.scan.info.section")
            }

            Section("library.scan.records.section") {
                ForEach(card.records) { record in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Label {
                                if let kind = record.kind {
                                    Text(LocalizedStringKey(kind.localizationKey))
                                } else {
                                    Text("record.custom")
                                }
                            } icon: {
                                Image(systemName: record.kind?.icon ?? "doc.text")
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
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("library.scan.detail.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}
