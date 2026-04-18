import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingDone")

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            LearnView()
                .tabItem { Label("Browse", systemImage: "books.vertical.fill") }
                .tag(1)

            QuizSetupView()
                .tabItem { Label("Quiz", systemImage: "checkmark.circle.fill") }
                .tag(2)

            BookmarksView()
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(Color.navy)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}
