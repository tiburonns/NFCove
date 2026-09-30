import SwiftUI
import UIKit

struct SavedCardUseView: View {
    let item: SavedNFCItem
    @ObservedObject var manager: NFCSessionManager

    @Environment(\.openURL) private var openURL
    @State private var copied = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: item.kind.icon)
                            .font(.title2)
                            .frame(width: 46, height: 46)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            Text(LocalizedStringKey(item.kind.localizationKey))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(item.value)
                        .font(.body)
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)

                    Label("library.use.status.ready", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section {
                Button {
                    useNow()
                } label: {
                    Label(
                        item.kind == .text
                            ? "library.use.copy"
                            : "library.use.now",
                        systemImage: item.kind == .text
                            ? "doc.on.doc"
                            : item.kind.icon
                    )
                }

                Button {
                    writeSavedCard()
                } label: {
                    Label("library.use.write", systemImage: "wave.3.right")
                }
                .disabled(
                    !manager.isNFCAvailable ||
                    manager.isActive ||
                    NDEFBuilder.message(for: item.kind, value: item.value) == nil
                )
            } header: {
                Text("library.use.action.section")
            } footer: {
                Text("library.use.action.footer")
            }

            if manager.isActive ||
                manager.statusKey != "nfc.status.ready" ||
                manager.lastError != nil {
                Section {
                    if manager.isActive ||
                        manager.statusKey != "nfc.status.ready" {
                        Label {
                            Text(LocalizedStringKey(manager.statusKey))
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

            Section("library.use.nfc.section") {
                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        "library.use.nfc.generic.title",
                        systemImage: "sensor.tag.radiowaves.forward"
                    )
                    .font(.headline)

                    Text("library.use.nfc.generic.detail")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Label(
                        "library.use.nfc.secure.title",
                        systemImage: "lock.shield"
                    )
                    .font(.headline)

                    Text("library.use.nfc.secure.detail")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("library.use.title")
        .navigationBarTitleDisplayMode(.inline)
        .alert("library.use.copied", isPresented: $copied) {
            Button("common.ok", role: .cancel) {}
        }
    }

    private func useNow() {
        if item.kind == .text {
            UIPasteboard.general.string = item.value
            copied = true
            return
        }

        guard let url = NFCRecordContent.actionURL(
            for: item.kind,
            value: item.value
        ) else {
            return
        }

        openURL(url)
    }

    private func writeSavedCard() {
        guard let message = NDEFBuilder.message(
            for: item.kind,
            value: item.value
        ) else {
            return
        }

        manager.beginWrite(message: message)
    }
}
