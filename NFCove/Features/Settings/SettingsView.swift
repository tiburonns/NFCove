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
                }
            }
            .navigationTitle("settings.title")
        }
    }
}
