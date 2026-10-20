import SwiftUI

enum AppTab: Hashable { case home, browse, quiz, saved, settings }

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingDone")

    var body: some View {
        tabs
            .tint(Color.gold)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onAppear {
                #if DEBUG
                DebugLaunchOptions.seedDemoProgressIfRequested()
                if let tab = DebugLaunchOptions.initialTab {
                    selectedTab = tab
                    showOnboarding = false
                }
                #endif
            }
    }

    @ViewBuilder
    private var tabs: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: AppTab.home) { HomeView(selectedTab: $selectedTab) }
                Tab("Browse", systemImage: "books.vertical.fill", value: AppTab.browse) { LearnView() }
                Tab("Quiz", systemImage: "checkmark.circle.fill", value: AppTab.quiz) { QuizSetupView() }
                Tab("Saved", systemImage: "bookmark.fill", value: AppTab.saved) { BookmarksView() }
                Tab("Settings", systemImage: "gearshape.fill", value: AppTab.settings) { SettingsView() }
            }
            .tabViewStyle(.sidebarAdaptable)   // sidebar on iPad, tab bar on iPhone
        } else {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem { Label("Home", systemImage: "house.fill") }.tag(AppTab.home)
                LearnView()
                    .tabItem { Label("Browse", systemImage: "books.vertical.fill") }.tag(AppTab.browse)
                QuizSetupView()
                    .tabItem { Label("Quiz", systemImage: "checkmark.circle.fill") }.tag(AppTab.quiz)
                BookmarksView()
                    .tabItem { Label("Saved", systemImage: "bookmark.fill") }.tag(AppTab.saved)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(AppTab.settings)
            }
        }
    }
}
