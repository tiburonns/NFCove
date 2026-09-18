import SwiftUI

enum AppTab: Hashable {
    case home
    case scan
    case create
    case library
    case settings
}

struct RootView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView(
                onScan: { selection = .scan },
                onCreate: { selection = .create },
                onLibrary: { selection = .library }
            )
            .tabItem { Label("tab.home", systemImage: "house") }
            .tag(AppTab.home)

            ScanView()
                .tabItem { Label("tab.scan", systemImage: "wave.3.right") }
                .tag(AppTab.scan)

            CreateView()
                .tabItem { Label("tab.create", systemImage: "plus.square.on.square") }
                .tag(AppTab.create)

            LibraryView()
                .tabItem { Label("tab.library", systemImage: "books.vertical") }
                .tag(AppTab.library)

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        }
    }
}
