import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageManager: LanguageManager

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"
        return "\(version) (\(build))"
    }

    private var privacyPolicyURL: URL? {
        configuredURL(for: "NFCovePrivacyPolicyURL")
    }

    private var supportURL: URL? {
        configuredURL(for: "NFCoveSupportURL")
            ?? URL(string: "https://github.com/tiburonns/NFCove/issues/new?template=feedback.yml")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.language.section") {
                    Picker(
                        "settings.language.picker",
                        selection: $languageManager.selection
                    ) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(
                                LocalizedStringKey(
                                    language.localizationKey
                                )
                            )
                            .tag(language)
                        }
                    }
                }

                Section("settings.about.section") {
                    LabeledContent(
                        "settings.about.version",
                        value: appVersion
                    )

                    NavigationLink {
                        PrivacyView()
                    } label: {
                        LabeledContent(
                            "settings.about.privacy"
                        ) {
                            Text("settings.about.localOnly")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let privacyPolicyURL {
                        Link(destination: privacyPolicyURL) {
                            Label(
                                "settings.about.privacyPolicy",
                                systemImage: "hand.raised"
                            )
                        }
                    }

                    if let supportURL {
                        Link(destination: supportURL) {
                            Label(
                                "settings.about.support",
                                systemImage: "questionmark.circle"
                            )
                        }
                    }
                }
            }
            .navigationTitle("settings.title")
        }
    }

    private func configuredURL(for key: String) -> URL? {
        guard let value = Bundle.main.object(
            forInfoDictionaryKey: key
        ) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              url.host != nil else {
            return nil
        }

        return url
    }
}
