import Foundation

/// Summary of the learner's progress, written by the app into the shared App
/// Group and read by the home-screen widget.  Time-dependent values (due
/// reviews, streak) are derived from dates so the widget stays correct even if
/// the app has not been opened for a while.
struct WidgetSnapshot: Codable, Equatable {
    var streak: Int                 // streak as of `lastStudyDay`
    var lastStudyDay: Date?
    var dueDates: [Date]            // next review date of every scheduled question
    var answered: Int
    var accuracy: Double
    var masteredCount: Int
    var totalQuestions: Int
    var updated: Date

    static let appGroup = "group.ai.biniam.SBFExamPrep"
    static let key = "widgetSnapshot"

    static let placeholder = WidgetSnapshot(streak: 5, lastStudyDay: .now, dueDates: Array(repeating: .distantPast, count: 12),
                                            answered: 140, accuracy: 0.82, masteredCount: 60, totalQuestions: 466,
                                            updated: .now)

    func dueCount(at date: Date) -> Int { dueDates.filter { $0 <= date }.count }

    func studied(on date: Date, calendar: Calendar = .current) -> Bool {
        guard let last = lastStudyDay else { return false }
        return calendar.isDate(last, inSameDayAs: date)
    }

    /// The streak survives until the end of the day after the last study day.
    func currentStreak(at date: Date, calendar: Calendar = .current) -> Int {
        guard let last = lastStudyDay else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: last),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return days <= 1 ? streak : 0
    }

    /// Times at which a widget showing this snapshot should refresh.
    func refreshDates(after date: Date, calendar: Calendar = .current) -> [Date] {
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
        let upcoming = Set(dueDates.filter { $0 > date && $0 < midnight })
        return (upcoming.sorted() + [midnight]).prefix(20).map { $0 }
    }

    static func load() -> WidgetSnapshot? {
        guard let data = UserDefaults(suiteName: appGroup)?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: Self.appGroup)?.set(data, forKey: Self.key)
    }
}
