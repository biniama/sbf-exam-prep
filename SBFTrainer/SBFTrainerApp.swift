import SwiftUI

@main
struct SBFTrainerApp: App {
    @StateObject private var progress = UserProgress.shared
    @StateObject private var store    = QuestionStore.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(progress)
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
