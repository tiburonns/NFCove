import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var library: LibraryStore

    let onScan: () -> Void
    let onCreate: () -> Void
    let onLibrary: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero

                    VStack(spacing: 12) {
                        actionCard(
                            title: "home.scan.title",
                            subtitle: "home.scan.subtitle",
                            systemImage: "wave.3.right",
                            action: onScan
                        )

                        actionCard(
                            title: "home.create.title",
                            subtitle: "home.create.subtitle",
                            systemImage: "plus.square.on.square",
                            action: onCreate
                        )

                        actionCard(
                            title: "home.library.title",
                            subtitle: "home.library.subtitle",
                            systemImage: "books.vertical",
                            badge: "\(library.items.count)",
                            action: onLibrary
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("home.roadmap.title")
                            .font(.headline)

                        Label("home.roadmap.verify", systemImage: "checkmark.shield")
                        Label("home.roadmap.batch", systemImage: "square.stack.3d.up")
                        Label("home.roadmap.shortcuts", systemImage: "wand.and.stars")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("app.name")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "sensor.tag.radiowaves.forward")
                .font(.system(size: 40, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            Text("home.hero.title")
                .font(.largeTitle.bold())

            Text("home.hero.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func actionCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .frame(width: 42, height: 42)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if let badge {
                    Text(badge)
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
