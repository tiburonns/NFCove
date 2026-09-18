import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case spanish

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .system: return "language.system"
        case .english: return "language.english"
        case .spanish: return "language.spanish"
        }
    }

    var locale: Locale {
        switch self {
        case .system: return .autoupdatingCurrent
        case .english: return Locale(identifier: "en")
        case .spanish: return Locale(identifier: "es")
        }
    }
}
