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

                Section("settings.support.section") {
                    NavigationLink {
                        NFCoveFeedbackView()
                    } label: {
                        Label(
                            "settings.support.feedback",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                    }

                    Link(
                        destination: URL(string: "https://github.com/tiburonns/NFCove/issues")!
                    ) {
                        Label(
                            "settings.support.issues",
                            systemImage: "exclamationmark.bubble"
                        )
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


private struct NFCoveFeedbackView: View {
    private enum Category: String, CaseIterable, Identifiable {
        case question, suggestion, bug, feedback
        var id: String { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .question: "feedback.category.question"
            case .suggestion: "feedback.category.suggestion"
            case .bug: "feedback.category.bug"
            case .feedback: "feedback.category.feedback"
            }
        }

        var issuePrefix: String {
            switch self {
            case .question: "Question"
            case .suggestion: "Suggestion"
            case .bug: "Bug"
            case .feedback: "Feedback"
            }
        }
    }

    @Environment(\.openURL) private var openURL
    @State private var category = Category.question
    @State private var message = ""

    var body: some View {
        Form {
            Section("feedback.type") {
                Picker("feedback.category", selection: $category) {
                    ForEach(Category.allCases) { option in
                        Text(option.titleKey).tag(option)
                    }
                }
            }

            Section("feedback.message") {
                TextEditor(text: $message)
                    .frame(minHeight: 160)

                Text("feedback.privacy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    submit()
                } label: {
                    Label("feedback.send", systemImage: "paperplane.fill")
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("feedback.review")
            }
        }
        .navigationTitle("feedback.title")
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func submit() {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "github.com"
        components.path = "/tiburonns/NFCove/issues/new"
        components.queryItems = [
            URLQueryItem(name: "title", value: "[\(category.issuePrefix)] "),
            URLQueryItem(
                name: "body",
                value: """
                \(message)

                ---
                App: NFCove
                Version: \(appVersion)
                """
            )
        ]

        if let url = components.url {
            openURL(url)
        }
    }
}
