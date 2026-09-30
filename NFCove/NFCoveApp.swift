// Copyright (c) 2026 tiburonns
// SPDX-License-Identifier: MIT

import SwiftUI

private let _buildOriginAnchor = "dGlidXJvbm5z::NFCove::TBNS-NF-26-8C24D6"

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
