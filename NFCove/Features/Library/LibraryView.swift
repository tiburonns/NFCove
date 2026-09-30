import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var manager = NFCSessionManager()

    private var isEmpty: Bool {
        library.items.isEmpty && library.scannedCards.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "library.empty.title",
                            systemImage: "books.vertical",
                            description: Text("library.empty.subtitle")
                        )

                        persistenceErrorView
                    }
                } else {
                    List {
                        if library.persistenceError != nil ||
                            manager.isActive ||
                            manager.statusKey != "nfc.status.ready" ||
                            manager.lastError != nil {
                            Section {
                                operationStatusView
                            }
                        }

                        if !library.scannedCards.isEmpty {
                            Section("library.scanned.section") {
                                ForEach(library.scannedCards) { card in
                                    NavigationLink {
                                        SavedScanDetailView(
                                            card: card,
                                            manager: manager
                                        )
                                    } label: {
                                        scannedCardRow(card)
                                    }
                                    .swipeActions(
                                        edge: .leading,
                                        allowsFullSwipe: false
                                    ) {
                                        Button {
                                            write(card)
                                        } label: {
                                            Label(
                                                "library.write",
                                                systemImage: "wave.3.right"
                                            )
                                        }
                                        .tint(.accentColor)
                                        .disabled(
                                            manager.isActive ||
                                            !manager.isNFCAvailable ||
                                            NDEFBuilder.message(
                                                from: card
                                            ) == nil
                                        )
                                    }
                                }
                                .onDelete(
                                    perform: library.deleteScannedCard
                                )
                            }
                        }

                        if !library.items.isEmpty {
                            Section("library.created.section") {
                                ForEach(library.items) { item in
                                    NavigationLink {
                                        SavedCardUseView(
                                            item: item,
                                            manager: manager
                                        )
                                    } label: {
                                        libraryRow(item)
                                    }
                                    .swipeActions(
                                        edge: .leading,
                                        allowsFullSwipe: false
                                    ) {
                                        Button {
                                            write(item)
                                        } label: {
                                            Label(
                                                "library.write",
                                                systemImage: "wave.3.right"
                                            )
                                        }
                                        .tint(.accentColor)
                                        .disabled(
                                            !manager.isNFCAvailable ||
                                            manager.isActive ||
                                            NDEFBuilder.message(
                                                for: item.kind,
                                                value: item.value
                                            ) == nil
                                        )
                                    }
                                }
                                .onDelete(perform: library.delete)
                            }
                        }
                    }
                }
            }
            .navigationTitle("library.title")
        }
    }

    @ViewBuilder
    private var persistenceErrorView: some View {
        if let error = library.persistenceError {
            Label {
                Text(error)
                    .font(.caption)
                    .textSelection(.enabled)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
    }

    private var operationStatusView: some View {
        VStack(alignment: .leading, spacing: 7) {
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

            persistenceErrorView
        }
    }

    private func scannedCardRow(_ card: SavedScanCard) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(
                    card.name,
                    systemImage: "sensor.tag.radiowaves.forward"
                )
                .font(.headline)

                Spacer()

                Text("\(card.records.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if let first = card.records.first {
                Text(first.value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Text(card.scannedAt, style: .date)

                if card.hasOriginalNDEF {
                    Label(
                        "library.scan.copyQuality.exact",
                        systemImage: "checkmark.shield"
                    )
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func libraryRow(_ item: SavedNFCItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(item.name, systemImage: item.kind.icon)
                    .font(.headline)

                Spacer()

                Text(
                    LocalizedStringKey(item.kind.localizationKey)
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(item.value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)

            Text(item.createdAt, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func write(_ item: SavedNFCItem) {
        guard let message = NDEFBuilder.message(
            for: item.kind,
            value: item.value
        ) else {
            return
        }

        manager.beginWrite(message: message)
    }

    private func write(_ card: SavedScanCard) {
        guard let message = NDEFBuilder.message(from: card) else {
            return
        }

        manager.beginWrite(message: message)
    }
}
