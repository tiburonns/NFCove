import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore

    var body: some View {
        NavigationStack {
            Group {
                if library.items.isEmpty {
                    ContentUnavailableView(
                        "library.empty.title",
                        systemImage: "books.vertical",
                        description: Text("library.empty.subtitle")
                    )
                } else {
                    List {
                        ForEach(library.items) { item in
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

                                Text(item.createdAt, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: library.delete)
                    }
                }
            }
            .navigationTitle("library.title")
        }
    }
}
