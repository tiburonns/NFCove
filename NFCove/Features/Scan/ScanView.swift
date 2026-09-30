import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var manager = NFCSessionManager()

    @State private var showingSavePrompt = false
    @State private var scanName = ""
    @State private var didSaveScan = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 190, height: 190)

                    Image(
                        systemName: manager.isActive
                            ? "wave.3.right.circle.fill"
                            : "wave.3.right.circle"
                    )
                    .font(.system(size: 78, weight: .light))
                    .symbolEffect(
                        .pulse,
                        isActive: manager.isActive
                    )
                }
                .accessibilityHidden(true)

                Text(LocalizedStringKey(manager.statusKey))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                if manager.tagCapacity != nil ||
                    manager.tagAccessKey != nil {
                    HStack(spacing: 10) {
                        if let accessKey = manager.tagAccessKey {
                            Label {
                                Text(LocalizedStringKey(accessKey))
                            } icon: {
                                Image(
                                    systemName: "lock.open.display"
                                )
                            }
                        }

                        if let capacity = manager.tagCapacity {
                            Label(
                                "\(capacity) B",
                                systemImage: "externaldrive"
                            )
                            .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                }

                if let error = manager.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel(error)
                }

                Button {
                    manager.beginRead()
                } label: {
                    Label(
                        "scan.button",
                        systemImage: "wave.3.right"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(
                    !manager.isNFCAvailable ||
                    manager.isActive
                )
                .padding(.horizontal)
                .accessibilityHint("scan.button.hint")

                if manager.records.isEmpty {
                    ContentUnavailableView(
                        "scan.results.empty.title",
                        systemImage: "sensor.tag.radiowaves.forward",
                        description: Text(
                            "scan.results.empty.subtitle"
                        )
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    Button {
                        scanName = ""
                        showingSavePrompt = true
                    } label: {
                        Label(
                            "scan.save.button",
                            systemImage: "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .accessibilityHint("scan.save.button.hint")

                    List(manager.records) { record in
                        VStack(
                            alignment: .leading,
                            spacing: 6
                        ) {
                            HStack {
                                Label {
                                    Text(
                                        record.kind.map {
                                            LocalizedStringKey(
                                                $0.localizationKey
                                            )
                                        } ?? LocalizedStringKey(
                                            "record.custom"
                                        )
                                    )
                                } icon: {
                                    Image(
                                        systemName: record.kind?.icon
                                            ?? "doc.text"
                                    )
                                }

                                Spacer()

                                Text("\(record.byteCount) B")
                                    .font(
                                        .caption.monospacedDigit()
                                    )
                                    .foregroundStyle(.secondary)
                            }

                            Text(record.value)
                                .font(.subheadline)
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(
                            children: .combine
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("scan.title")
            .alert(
                "scan.save.title",
                isPresented: $showingSavePrompt
            ) {
                TextField(
                    "scan.save.name.placeholder",
                    text: $scanName
                )
                Button("common.cancel", role: .cancel) {}
                Button("scan.save.confirm") {
                    library.addScannedCard(
                        name: scanName.isEmpty
                            ? AppLocalization.string(
                                "scan.save.defaultName"
                            )
                            : scanName,
                        records: manager.records,
                        tagCapacity: manager.tagCapacity,
                        tagAccessKey: manager.tagAccessKey
                    )
                    didSaveScan = true
                }
            } message: {
                Text("scan.save.message")
            }
            .alert(
                "scan.save.saved.title",
                isPresented: $didSaveScan
            ) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text("scan.save.saved.message")
            }
        }
    }
}
