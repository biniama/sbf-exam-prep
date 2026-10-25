import Foundation

#if DEBUG
/// Debug-only launch arguments used for UI checks and App Store screenshots, e.g.
///
///     -screenshotTab browse -screenshotQuestion binnen_162 -demoProgress YES
///
/// Arguments passed on launch end up in `UserDefaults` (argument domain).
enum DebugLaunchOptions {
    static var initialTab: AppTab? {
        switch UserDefaults.standard.string(forKey: "screenshotTab") {
        case "home": return .home
        case "browse": return .browse
        case "quiz": return .quiz
        case "saved": return .saved
        case "settings": return .settings
        default: return nil
        }
    }

    static var selectedQuestion: String? { UserDefaults.standard.string(forKey: "screenshotQuestion") }

    /// Opens a quiz on launch: "exam-binnen", "exam-segeln", "exam-see", "navigation-exam" or "practice".
    static var autoQuiz: String? { UserDefaults.standard.string(forKey: "screenshotQuiz") }

    /// Seeds realistic progress so screenshots don't show an empty app.
    @MainActor
    static func seedDemoProgressIfRequested() {
        guard UserDefaults.standard.bool(forKey: "demoProgress"), !UserDefaults.standard.bool(forKey: "demoSeeded") else { return }
        let progress = UserProgress.shared
        progress.resetProgress()     // iCloud key-value data survives reinstalls; start from a clean slate
        let questions = QuestionStore.shared.allQuestions
        let calendar = Calendar.current
        for (i, q) in questions.prefix(180).enumerated() {
            let day = calendar.date(byAdding: .day, value: -(i % 9), to: .now) ?? .now
            progress.recordAnswer(questionId: q.uniqueId, category: q.category, correct: i % 5 != 0, now: day)
        }
        for (i, q) in questions.prefix(180).enumerated() where i % 4 == 1 { progress.markMastered(q.uniqueId) }
        for q in questions.dropFirst(20).prefix(6) { progress.toggleBookmark(q.uniqueId) }
        progress.saveQuizRecord(QuizRecord(date: .now.addingTimeInterval(-3600), examType: "Binnen", totalQuestions: 30,
                                           correctAnswers: 27, isExam: true, passed: true))
        progress.saveQuizRecord(QuizRecord(date: .now.addingTimeInterval(-90_000), examType: "All", totalQuestions: 20,
                                           correctAnswers: 16))
        progress.setLicenceGoal(LicenceGoal(inland: .motorAndSail, sea: true))
        UserDefaults.standard.set(true, forKey: "demoSeeded")
        UserDefaults.standard.set(true, forKey: "onboardingDone")
    }
}
#endif
