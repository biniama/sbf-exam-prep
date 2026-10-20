import Foundation
import Combine
import WidgetKit

struct QuizRecord: Codable, Hashable {
    let date: Date
    let examType: String
    let totalQuestions: Int
    let correctAnswers: Int
    /// Set for exam simulations only.
    var isExam: Bool? = nil
    var passed: Bool? = nil

    var accuracy: Double { totalQuestions > 0 ? Double(correctAnswers) / Double(totalQuestions) : 0 }
    var type: ExamType { ExamType(rawValue: examType) ?? .all }
}

/// Leitner box of a question for spaced repetition.
struct ReviewState: Codable, Equatable {
    var box: Int        // 1 … 5
    var due: Date
}

enum SpacedRepetition {
    static let maxBox = 5
    /// Days until the next review for each box.
    static let intervalDays: [Int: Int] = [1: 1, 2: 3, 3: 7, 4: 14, 5: 30]

    /// Next state after an answer.  A wrong answer sends the question back to
    /// box 1 and makes it due immediately; a correct answer promotes it one box.
    static func next(after state: ReviewState?, correct: Bool, now: Date = .now,
                     calendar: Calendar = .current) -> ReviewState {
        guard correct else { return ReviewState(box: 1, due: now) }
        let box = min((state?.box ?? 0) + 1, maxBox)
        let start = calendar.startOfDay(for: now)
        let due = calendar.date(byAdding: .day, value: intervalDays[box] ?? 1, to: start) ?? now
        return ReviewState(box: box, due: due)
    }
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
    @Published private(set) var reviewStates: [String: ReviewState] = [:]

    // Local preferences (not synced)
    @Published var showEnglish: Bool = true
    @Published var quizCount: Int = 20
    @Published private(set) var reminderEnabled = false
    @Published private(set) var reminderMinutes = 18 * 60
    @Published private(set) var iCloudSyncEnabled = true

    private let defaults: UserDefaults
    private let cloud: CloudSync?
    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private enum Key {
        static let bookmarks = "bookmarks", wrong = "wrongAnswers", mastered = "mastered",
                   history = "quizHistory", studyDates = "studyDates", catCorrect = "categoryCorrect",
                   catTotal = "categoryTotal", review = "reviewStates"
        static let synced = [bookmarks, wrong, mastered, history, studyDates, catCorrect, catTotal, review]
    }

    private init() {
        defaults = .standard
        cloud = CloudSync.shared
        load()
        cloud?.start { [weak self] keys in self?.applyRemoteChanges(keys) }
        updateWidget()
    }

    /// Isolated instance for unit tests (no iCloud, separate defaults).
    init(testDefaults: UserDefaults) {
        defaults = testDefaults
        cloud = nil
        load()
    }

    // MARK: - Persistence

    private func modified(_ key: String) -> Date? {
        let t = defaults.double(forKey: "ts." + key)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        if let remote = cloud?.newerValue(forKey: key, than: modified(key)),
           let value = try? JSONDecoder().decode(T.self, from: remote) {
            defaults.set(remote, forKey: key)
            if let ts = cloud?.remoteTimestamp(forKey: key) {
                defaults.set(ts.timeIntervalSince1970, forKey: "ts." + key)
            }
            return value
        }
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func load() {
        bookmarks = decode(Set<String>.self, key: Key.bookmarks) ?? []
        wrongAnswerIds = decode([String: Int].self, key: Key.wrong) ?? [:]
        masteredIds = decode(Set<String>.self, key: Key.mastered) ?? []
        quizHistory = decode([QuizRecord].self, key: Key.history) ?? []
        studyDates = decode(Set<String>.self, key: Key.studyDates) ?? []
        categoryCorrect = decode([String: Int].self, key: Key.catCorrect) ?? [:]
        categoryTotal = decode([String: Int].self, key: Key.catTotal) ?? [:]
        reviewStates = decode([String: ReviewState].self, key: Key.review) ?? [:]
        showEnglish = defaults.object(forKey: "showEnglish") as? Bool ?? true
        quizCount = defaults.object(forKey: "quizCount") as? Int ?? 20
        reminderEnabled = defaults.bool(forKey: "reminderEnabled")
        reminderMinutes = defaults.object(forKey: "reminderMinutes") as? Int ?? 18 * 60
        iCloudSyncEnabled = cloud?.isEnabled ?? false
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        let data = try? JSONEncoder().encode(value)
        let now = Date()
        defaults.set(data, forKey: key)
        defaults.set(now.timeIntervalSince1970, forKey: "ts." + key)
        cloud?.push(data, forKey: key, modified: now)
    }

    private func applyRemoteChanges(_ keys: [String]) {
        guard keys.contains(where: Key.synced.contains) else { return }
        load()
        updateWidget()
    }

    // MARK: - Bookmarks

    func toggleBookmark(_ id: String) {
        guard !id.isEmpty else { return }
        if bookmarks.contains(id) { bookmarks.remove(id) } else { bookmarks.insert(id) }
        save(bookmarks, key: Key.bookmarks)
    }
    func isBookmarked(_ id: String) -> Bool { bookmarks.contains(id) }

    // MARK: - Answers

    func recordAnswer(questionId: String, category: String, correct: Bool, now: Date = .now) {
        if correct {
            if let count = wrongAnswerIds[questionId], count > 0 {
                wrongAnswerIds[questionId] = count - 1
                if wrongAnswerIds[questionId] == 0 { wrongAnswerIds.removeValue(forKey: questionId) }
            }
        } else {
            wrongAnswerIds[questionId, default: 0] += 1
            masteredIds.remove(questionId)
        }
        save(wrongAnswerIds, key: Key.wrong)
        save(masteredIds, key: Key.mastered)

        categoryTotal[category, default: 0] += 1
        if correct { categoryCorrect[category, default: 0] += 1 }
        save(categoryTotal, key: Key.catTotal)
        save(categoryCorrect, key: Key.catCorrect)

        reviewStates[questionId] = SpacedRepetition.next(after: reviewStates[questionId], correct: correct, now: now)
        save(reviewStates, key: Key.review)

        recordStudy(on: now)
        updateWidget()
    }

    func markMastered(_ id: String) {
        masteredIds.insert(id)
        wrongAnswerIds.removeValue(forKey: id)
        reviewStates[id] = ReviewState(box: SpacedRepetition.maxBox,
                                       due: Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now)
        save(masteredIds, key: Key.mastered)
        save(wrongAnswerIds, key: Key.wrong)
        save(reviewStates, key: Key.review)
        updateWidget()
    }

    func clearWrongAnswer(_ id: String) {
        wrongAnswerIds.removeValue(forKey: id)
        save(wrongAnswerIds, key: Key.wrong)
        updateWidget()
    }

    var wrongAnswerCount: Int { wrongAnswerIds.count }
    func isWrong(_ id: String) -> Bool { (wrongAnswerIds[id] ?? 0) > 0 }

    // MARK: - Spaced repetition

    func dueQuestionIds(now: Date = .now) -> [String] {
        reviewStates.filter { $0.value.due <= now }
            .sorted { ($0.value.box, $0.value.due) < ($1.value.box, $1.value.due) }
            .map(\.key)
    }

    var dueCount: Int { dueQuestionIds().count }
    var masteredCount: Int {
        Set(reviewStates.filter { $0.value.box >= SpacedRepetition.maxBox }.map(\.key)).union(masteredIds).count
    }
    func box(for id: String) -> Int? { reviewStates[id]?.box }

    // MARK: - Category mastery

    func masteryForCategory(_ category: String) -> Double? {
        guard let total = categoryTotal[category], total >= 3 else { return nil }
        return Double(categoryCorrect[category] ?? 0) / Double(total)
    }

    // MARK: - Quiz history

    func saveQuizRecord(_ record: QuizRecord) {
        quizHistory.insert(record, at: 0)
        if quizHistory.count > 100 { quizHistory = Array(quizHistory.prefix(100)) }
        save(quizHistory, key: Key.history)
        recordStudy(on: record.date)
        updateWidget()
    }

    /// Every answered question counts, not only finished quizzes.
    var totalAnswered: Int { categoryTotal.values.reduce(0, +) }
    var overallAccuracy: Double {
        let total = categoryTotal.values.reduce(0, +)
        return total > 0 ? Double(categoryCorrect.values.reduce(0, +)) / Double(total) : 0
    }

    // MARK: - Daily streak

    private func recordStudy(on date: Date) {
        let key = dateFmt.string(from: date)
        guard !studyDates.contains(key) else { return }
        studyDates.insert(key)
        save(studyDates, key: Key.studyDates)
    }

    var studiedToday: Bool { studyDates.contains(dateFmt.string(from: .now)) }

    var dailyStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: .now)
        if !studyDates.contains(dateFmt.string(from: day)) {
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while studyDates.contains(dateFmt.string(from: day)) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    var last7Days: [(date: Date, studied: Bool)] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))!
            return (date, studyDates.contains(dateFmt.string(from: date)))
        }
    }

    // MARK: - Settings

    func setShowEnglish(_ value: Bool) {
        showEnglish = value
        defaults.set(value, forKey: "showEnglish")
    }

    func toggleEnglish() { setShowEnglish(!showEnglish) }

    func setQuizCount(_ n: Int) {
        quizCount = n
        defaults.set(n, forKey: "quizCount")
    }

    func setReminder(enabled: Bool, minutes: Int? = nil) {
        reminderEnabled = enabled
        if let minutes { reminderMinutes = minutes }
        defaults.set(enabled, forKey: "reminderEnabled")
        defaults.set(reminderMinutes, forKey: "reminderMinutes")
        if enabled {
            NotificationManager.shared.scheduleDailyReminder(hour: reminderMinutes / 60, minute: reminderMinutes % 60)
        } else {
            NotificationManager.shared.cancelReminders()
        }
    }

    func setICloudSync(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        cloud?.isEnabled = enabled
        if enabled {
            // Upload the current state so other devices pick it up.
            save(bookmarks, key: Key.bookmarks); save(wrongAnswerIds, key: Key.wrong)
            save(masteredIds, key: Key.mastered); save(quizHistory, key: Key.history)
            save(studyDates, key: Key.studyDates); save(categoryCorrect, key: Key.catCorrect)
            save(categoryTotal, key: Key.catTotal); save(reviewStates, key: Key.review)
        }
    }

    // MARK: - Reset

    func resetProgress() {
        bookmarks = []; wrongAnswerIds = [:]; masteredIds = []
        quizHistory = []; studyDates = []; categoryCorrect = [:]; categoryTotal = [:]; reviewStates = [:]
        Key.synced.forEach {
            defaults.removeObject(forKey: $0)
            defaults.removeObject(forKey: "ts." + $0)
        }
        cloud?.removeAll(keys: Key.synced)
        updateWidget()
    }

    // MARK: - Widget

    private func updateWidget() {
        guard cloud != nil else { return }   // not in unit tests
        let lastStudyDay = studyDates.compactMap { dateFmt.date(from: $0) }.max()
        let snapshot = WidgetSnapshot(streak: dailyStreak, lastStudyDay: lastStudyDay,
                                      dueDates: reviewStates.values.map(\.due).sorted(),
                                      answered: totalAnswered, accuracy: overallAccuracy,
                                      masteredCount: masteredCount,
                                      totalQuestions: QuestionStore.shared.allQuestions.count, updated: .now)
        if var old = WidgetSnapshot.load() {
            old.updated = snapshot.updated
            if old == snapshot { return }      // nothing the widget shows has changed
        }
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
