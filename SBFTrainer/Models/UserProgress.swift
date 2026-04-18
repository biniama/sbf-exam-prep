import Foundation
import Combine

struct QuizRecord: Codable {
    let date: Date
    let examType: String
    let totalQuestions: Int
    let correctAnswers: Int
    var accuracy: Double { totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0 }
}

@MainActor
final class UserProgress: ObservableObject {
    static let shared = UserProgress()

    @Published private(set) var bookmarks: Set<String> = []
    @Published private(set) var wrongAnswerIds: [String: Int] = [:]
    @Published private(set) var masteredIds: Set<String> = []
    @Published private(set) var quizHistory: [QuizRecord] = []
    @Published private(set) var studyDates: Set<String> = []
    @Published private(set) var categoryCorrect: [String: Int] = [:]
    @Published private(set) var categoryTotal: [String: Int] = [:]
    @Published var showEnglish: Bool = true
    @Published var quizCount: Int = 20

    private let defaults = UserDefaults.standard
    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private init() { load() }

    // MARK: - Persistence

    private func load() {
        if let d = defaults.data(forKey: "bookmarks"),
           let v = try? JSONDecoder().decode(Set<String>.self, from: d) { bookmarks = v }
        if let d = defaults.data(forKey: "wrongAnswers"),
           let v = try? JSONDecoder().decode([String: Int].self, from: d) { wrongAnswerIds = v }
        if let d = defaults.data(forKey: "mastered"),
           let v = try? JSONDecoder().decode(Set<String>.self, from: d) { masteredIds = v }
        if let d = defaults.data(forKey: "quizHistory"),
           let v = try? JSONDecoder().decode([QuizRecord].self, from: d) { quizHistory = v }
        if let d = defaults.data(forKey: "studyDates"),
           let v = try? JSONDecoder().decode(Set<String>.self, from: d) { studyDates = v }
        if let d = defaults.data(forKey: "categoryCorrect"),
           let v = try? JSONDecoder().decode([String: Int].self, from: d) { categoryCorrect = v }
        if let d = defaults.data(forKey: "categoryTotal"),
           let v = try? JSONDecoder().decode([String: Int].self, from: d) { categoryTotal = v }
        showEnglish = defaults.object(forKey: "showEnglish") as? Bool ?? true
        quizCount = defaults.object(forKey: "quizCount") as? Int ?? 20
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    // MARK: - Bookmarks

    func toggleBookmark(_ id: String) {
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
        save(bookmarks, key: "bookmarks")
    }
    func isBookmarked(_ id: String) -> Bool { bookmarks.contains(id) }

    // MARK: - Wrong Answers

    func recordAnswer(questionId: String, category: String, correct: Bool) {
        if correct {
            if let count = wrongAnswerIds[questionId], count > 0 {
                wrongAnswerIds[questionId] = max(0, count - 1)
                if wrongAnswerIds[questionId] == 0 { wrongAnswerIds.removeValue(forKey: questionId) }
            }
        } else {
            wrongAnswerIds[questionId, default: 0] += 1
            masteredIds.remove(questionId)
        }
        save(wrongAnswerIds, key: "wrongAnswers")
        save(masteredIds, key: "mastered")

        categoryTotal[category, default: 0] += 1
        if correct { categoryCorrect[category, default: 0] += 1 }
        save(categoryTotal, key: "categoryTotal")
        save(categoryCorrect, key: "categoryCorrect")
    }

    func markMastered(_ id: String) {
        masteredIds.insert(id)
        wrongAnswerIds.removeValue(forKey: id)
        save(masteredIds, key: "mastered")
        save(wrongAnswerIds, key: "wrongAnswers")
    }

    func clearWrongAnswer(_ id: String) {
        wrongAnswerIds.removeValue(forKey: id)
        save(wrongAnswerIds, key: "wrongAnswers")
    }

    var wrongAnswerCount: Int { wrongAnswerIds.count }
    func isWrong(_ id: String) -> Bool { (wrongAnswerIds[id] ?? 0) > 0 }

    // MARK: - Category Mastery

    func masteryForCategory(_ category: String) -> Double? {
        guard let total = categoryTotal[category], total >= 3 else { return nil }
        let correct = categoryCorrect[category] ?? 0
        return Double(correct) / Double(total)
    }

    // MARK: - Quiz History

    func saveQuizRecord(_ record: QuizRecord) {
        quizHistory.insert(record, at: 0)
        if quizHistory.count > 100 { quizHistory = Array(quizHistory.prefix(100)) }
        save(quizHistory, key: "quizHistory")
        recordStudyToday()
    }

    var totalAnswered: Int { quizHistory.reduce(0) { $0 + $1.totalQuestions } }
    var overallAccuracy: Double {
        let total = quizHistory.reduce(0) { $0 + $1.totalQuestions }
        let correct = quizHistory.reduce(0) { $0 + $1.correctAnswers }
        return total > 0 ? Double(correct) / Double(total) : 0
    }

    // MARK: - Daily Streak

    private func recordStudyToday() {
        let key = dateFmt.string(from: Date())
        guard !studyDates.contains(key) else { return }
        studyDates.insert(key)
        save(studyDates, key: "studyDates")
    }

    var dailyStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())

        // If not studied today, start count from yesterday
        if !studyDates.contains(dateFmt.string(from: checkDate)) {
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        while studyDates.contains(dateFmt.string(from: checkDate)) {
            streak += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    var last7Days: [(date: Date, studied: Bool)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            return (date, studyDates.contains(dateFmt.string(from: date)))
        }
    }

    // MARK: - Computed streak (kept for compatibility)
    var currentStreak: Int { dailyStreak }

    // MARK: - Settings

    func toggleEnglish() {
        showEnglish.toggle()
        defaults.set(showEnglish, forKey: "showEnglish")
    }

    func setQuizCount(_ n: Int) {
        quizCount = n
        defaults.set(n, forKey: "quizCount")
    }

    // MARK: - Reset

    func resetProgress() {
        bookmarks = []; wrongAnswerIds = [:]; masteredIds = []
        quizHistory = []; studyDates = []; categoryCorrect = [:]; categoryTotal = [:]
        ["bookmarks","wrongAnswers","mastered","quizHistory",
         "studyDates","categoryCorrect","categoryTotal"].forEach { defaults.removeObject(forKey: $0) }
    }
}
