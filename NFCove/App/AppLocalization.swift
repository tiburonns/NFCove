import Foundation

enum AppLocalization {
    static let languageStorageKey = "selectedLanguage"

    static func string(_ key: String) -> String {
        let selected = UserDefaults.standard.string(forKey: languageStorageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system

        let languageCode: String?
        switch selected {
        case .system:
            languageCode = nil
        case .english:
            languageCode = "en"
        case .spanish:
            languageCode = "es"
        }

        if let languageCode,
           let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: nil, table: nil)
        }

        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}
