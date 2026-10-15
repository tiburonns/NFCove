import SwiftUI

struct FeedbackView: View {
    @Environment(\.openURL) private var openURL
    @State private var category = "feedback.suggestion"
    @State private var message = ""

    private let categories = ["feedback.bug", "feedback.comment", "feedback.suggestion", "feedback.other"]

    var body: some View {
        Form {
            Section("feedback.category") {
                Picker("feedback.category", selection: $category) {
                    ForEach(categories, id: \.self) { Text(LocalizedStringKey($0)) }
                }
            }
            Section("feedback.message") {
                TextEditor(text: $message).frame(minHeight: 150)
                Text("feedback.privacy")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section {
                Button(action: sendFeedback) {
                    Label("feedback.send", systemImage: "paperplane.fill")
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } footer: {
                Text("feedback.emailDraft")
                    .font(.footnote)
            }
        }
        .navigationTitle("feedback.title")
    }

    private func sendFeedback() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "tiburonns@icloud.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "[NFCove] [\(category)]"),
            URLQueryItem(name: "body", value: "\(message)\n\nNFCove \(version) (\(build))")
        ]
        if let url = components.url { openURL(url) }
    }
}
