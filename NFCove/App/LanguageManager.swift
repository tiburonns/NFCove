import Combine
import Foundation

@MainActor
final class LanguageManager: ObservableObject {
    @Published var selection: AppLanguage {
        didSet {
            UserDefaults.standard.set(selection.rawValue, forKey: Self.storageKey)
        }
    }

    private static let storageKey = AppLocalization.languageStorageKey

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        selection = AppLanguage(rawValue: raw ?? "") ?? .system
    }
}
