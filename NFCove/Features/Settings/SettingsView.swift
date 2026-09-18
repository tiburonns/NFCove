import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var languageManager: LanguageManager

    var body: some View {
        NavigationStack {
            Form {
                Section("settings.language.section") {
                    Picker("settings.language.picker", selection: $languageManager.selection) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(LocalizedStringKey(language.localizationKey))
                                .tag(language)
                        }
                    }
                }

                Section("settings.about.section") {
                    LabeledContent("settings.about.version", value: "0.2.0")
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        LabeledContent("settings.about.privacy") {
                            Text("settings.about.localOnly")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("settings.expert.section") {
                    Label("settings.expert.comingSoon", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("settings.title")
        }
    }
}
