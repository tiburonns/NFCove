import SwiftUI

struct PrivacyView: View {
    var body: some View {
        List {
            Section {
                privacyRow(
                    icon: "hand.raised.fill",
                    title: "privacy.tracking.title",
                    detail: "privacy.tracking.detail"
                )
                privacyRow(
                    icon: "iphone",
                    title: "privacy.nfc.title",
                    detail: "privacy.nfc.detail"
                )
                privacyRow(
                    icon: "internaldrive",
                    title: "privacy.storage.title",
                    detail: "privacy.storage.detail"
                )
                privacyRow(
                    icon: "person.crop.circle.badge.xmark",
                    title: "privacy.account.title",
                    detail: "privacy.account.detail"
                )
            } header: {
                Text("privacy.summary.section")
            } footer: {
                Text("privacy.summary.footer")
            }

            Section("privacy.technical.section") {
                LabeledContent("privacy.technical.tracking") {
                    Text("privacy.value.no")
                }
                LabeledContent("privacy.technical.collection") {
                    Text("privacy.value.none")
                }
                LabeledContent("privacy.technical.userdefaults") {
                    Text("privacy.value.local")
                }
            }
        }
        .navigationTitle("privacy.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyRow(
        icon: String,
        title: LocalizedStringKey,
        detail: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
