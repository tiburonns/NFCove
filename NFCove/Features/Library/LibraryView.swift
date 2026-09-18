import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var manager = NFCSessionManager()

    var body: some View {
        NavigationStack {
            Group {
                if library.items.isEmpty {
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

                        Section {
                            ForEach(library.items) { item in
                                libraryRow(item)
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

    private func libraryRow(_ item: SavedNFCItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(item.name, systemImage: item.kind.icon)
                    .font(.headline)

                Spacer()

                Text(LocalizedStringKey(item.kind.localizationKey))
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
}
