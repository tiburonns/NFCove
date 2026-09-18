import SwiftUI

@main
struct NFCoveApp: App {
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var libraryStore = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(languageManager)
                .environmentObject(libraryStore)
                .environment(\.locale, languageManager.selection.locale)
        }
    }
}
