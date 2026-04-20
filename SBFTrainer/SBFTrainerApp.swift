import SwiftUI
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct SBFExamPrepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
