import XCTest
@testable import SBFTrainer

@MainActor
final class ExamRulesTests: XCTestCase {
    func testOfficialPassMarks() {
        let rules = ExamRules(type: .binnen)
        XCTAssertEqual(rules.totalCount, 30)
        XCTAssertEqual(rules.minutes, 45)
        XCTAssertEqual(ExamRules(type: .see).minutes, 60)

        XCTAssertTrue(rules.result(basicCorrect: 5, specificCorrect: 18).passed)
        XCTAssertFalse(rules.result(basicCorrect: 4, specificCorrect: 23).passed, "basic part failed")
        XCTAssertFalse(rules.result(basicCorrect: 7, specificCorrect: 17).passed, "specific part failed")
    }

    func testExamSimulationComposition() {
        let defaults = UserDefaults(suiteName: "ExamRulesTests")!
        defaults.removePersistentDomain(forName: "ExamRulesTests")
        let vm = QuizViewModel(progress: UserProgress(testDefaults: defaults))
        for type in [ExamType.binnen, .see] {
            vm.setupExam(type: type)
            XCTAssertEqual(vm.questions.count, 30)
            XCTAssertEqual(vm.questions.filter { $0.examType == .shared }.count, 7)
            XCTAssertEqual(vm.questions.filter { $0.examType == type }.count, 23)
            XCTAssertEqual(Set(vm.questions.map(\.uniqueId)).count, 30, "no duplicates")
            XCTAssertEqual(vm.timeRemaining, ExamRules(type: type).minutes * 60)
            XCTAssertTrue(vm.examMode)
        }
    }

    func testExamScoringCountsBothParts() {
        let defaults = UserDefaults(suiteName: "ExamScoring")!
        defaults.removePersistentDomain(forName: "ExamScoring")
        let vm = QuizViewModel(progress: UserProgress(testDefaults: defaults))
        vm.setupExam(type: .binnen)
        // Answer every question correctly.
        while vm.state != .finished {
            guard let q = vm.current else { break }
            let correctKey = vm.shuffledOptions(for: q).first { vm.isCorrect($0.key, for: q) }!.key
            vm.select(correctKey)
            vm.next()
        }
        let result = vm.examResult
        XCTAssertEqual(result?.basicCorrect, 7)
        XCTAssertEqual(result?.specificCorrect, 23)
        XCTAssertEqual(result?.passed, true)
    }
}

final class SpacedRepetitionTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    func testCorrectAnswersPromoteThroughTheBoxes() {
        var state: ReviewState? = nil
        var expectedDays: [Int] = []
        for _ in 0..<6 {
            state = SpacedRepetition.next(after: state, correct: true, now: now, calendar: cal)
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: state!.due).day!
            expectedDays.append(days)
        }
        XCTAssertEqual(expectedDays, [1, 3, 7, 14, 30, 30])
        XCTAssertEqual(state?.box, SpacedRepetition.maxBox)
    }

    func testWrongAnswerResetsAndIsDueImmediately() {
        let promoted = ReviewState(box: 4, due: now.addingTimeInterval(86_400 * 10))
        let reset = SpacedRepetition.next(after: promoted, correct: false, now: now, calendar: cal)
        XCTAssertEqual(reset.box, 1)
        XCTAssertLessThanOrEqual(reset.due, now)
    }

    @MainActor
    func testProgressTracksDueQuestionsAndStats() {
        let defaults = UserDefaults(suiteName: "SpacedRepetitionTests")!
        defaults.removePersistentDomain(forName: "SpacedRepetitionTests")
        let progress = UserProgress(testDefaults: defaults)
        progress.recordAnswer(questionId: "q1", category: "Weather", correct: false, now: now)
        progress.recordAnswer(questionId: "q2", category: "Weather", correct: true, now: now)
        XCTAssertEqual(progress.dueQuestionIds(now: now), ["q1"])
        XCTAssertEqual(progress.totalAnswered, 2)
        XCTAssertEqual(progress.overallAccuracy, 0.5)
        XCTAssertTrue(progress.isWrong("q1"))

        // Persisted
        let reloaded = UserProgress(testDefaults: defaults)
        XCTAssertEqual(reloaded.totalAnswered, 2)
        XCTAssertEqual(reloaded.box(for: "q2"), 1)
    }
}

@MainActor
final class SoundSignalTests: XCTestCase {
    func testTimeline() {
        let (segments, total) = SoundSignalPlayer.timeline(for: "-.")
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].duration, SoundSignalPlayer.longSeconds)
        XCTAssertEqual(segments[1].start, SoundSignalPlayer.longSeconds + SoundSignalPlayer.gapSeconds)
        XCTAssertEqual(total, SoundSignalPlayer.longSeconds + SoundSignalPlayer.gapSeconds + SoundSignalPlayer.shortSeconds)
    }

    func testSpokenDescription() {
        XCTAssertEqual(SoundSignalButton.spokenDescription("-.").split(separator: ",").count, 2)
    }
}

final class WidgetSnapshotTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    func testStreakSurvivesUntilTheEndOfTheNextDay() {
        let today = cal.startOfDay(for: Date(timeIntervalSince1970: 1_760_000_000))
        let snap = WidgetSnapshot(streak: 4, lastStudyDay: today, dueDates: [], answered: 0, accuracy: 0,
                                  masteredCount: 0, totalQuestions: 466, updated: today)
        XCTAssertEqual(snap.currentStreak(at: today.addingTimeInterval(3600), calendar: cal), 4)
        XCTAssertEqual(snap.currentStreak(at: today.addingTimeInterval(86_400 + 3600), calendar: cal), 4)
        XCTAssertEqual(snap.currentStreak(at: today.addingTimeInterval(2 * 86_400 + 3600), calendar: cal), 0)
        XCTAssertTrue(snap.studied(on: today, calendar: cal))
    }

    func testDueCountGrowsOverTime() {
        let now = Date(timeIntervalSince1970: 1_760_000_000)
        let snap = WidgetSnapshot(streak: 0, lastStudyDay: nil,
                                  dueDates: [now.addingTimeInterval(-10), now.addingTimeInterval(3600)],
                                  answered: 0, accuracy: 0, masteredCount: 0, totalQuestions: 466, updated: now)
        XCTAssertEqual(snap.dueCount(at: now), 1)
        XCTAssertEqual(snap.dueCount(at: now.addingTimeInterval(7200)), 2)
    }
}
