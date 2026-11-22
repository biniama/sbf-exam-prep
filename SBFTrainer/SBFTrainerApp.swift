import SwiftUI

@main
struct SBFExamPrepApp: App {
    @StateObject private var progress = UserProgress.shared
    @StateObject private var store = QuestionStore.shared
    @StateObject private var flags = FeatureFlags.shared
    @StateObject private var entitlements = EntitlementManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(progress)
                .environmentObject(store)
                .environmentObject(flags)
                .environmentObject(entitlements)
        }
    }
}
