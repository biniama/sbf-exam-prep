import XCTest
@testable import SBFTrainer

@MainActor
final class ExamRulesTests: XCTestCase {
    func testOfficialCompositionAndTimes() {
        let expected: [ExamFormat: (count: Int, minutes: Int)] = [
            .binnenMotor: (30, 45), .binnenSail: (25, 35), .binnenMotorSail: (37, 60), .sailAddOn: (7, 15), .see: (30, 60),
        ]
        for (format, value) in expected {
            let rules = ExamRules(format: format)
            XCTAssertEqual(rules.totalCount, value.count, format.rawValue)
            XCTAssertEqual(rules.minutes, value.minutes, format.rawValue)
        }
    }

    func testPartPassMarks() {
        let rules = ExamRules(format: .binnenMotor)
        XCTAssertTrue(rules.result(correct: [.shared: 5, .binnen: 18]).passed)
        XCTAssertFalse(rules.result(correct: [.shared: 4, .binnen: 23]).passed, "basic part failed")
        XCTAssertFalse(rules.result(correct: [.shared: 7, .binnen: 17]).passed, "inland part failed")

        let combined = ExamRules(format: .binnenMotorSail)
        XCTAssertTrue(combined.result(correct: [.shared: 5, .binnen: 18, .segeln: 5]).passed)
        XCTAssertFalse(combined.result(correct: [.shared: 7, .binnen: 23, .segeln: 4]).passed, "sailing part failed")

        let addOn = ExamRules(format: .sailAddOn)
        XCTAssertTrue(addOn.result(correct: [.segeln: 5]).passed)
        XCTAssertFalse(addOn.result(correct: [.segeln: 4]).passed)
    }

    func testSailOnlyCountsTheTotal() {
        let rules = ExamRules(format: .binnenSail)
        XCTAssertEqual(rules.totalPassMark, 20)
        // 0 of 4 basic questions is fine as long as the total reaches 20.
        XCTAssertTrue(rules.result(correct: [.shared: 0, .binnen: 14, .segeln: 6]).passed)
        XCTAssertFalse(rules.result(correct: [.shared: 4, .binnen: 12, .segeln: 3]).passed, "19 in total")
    }

    func testExamSimulationComposition() {
        let defaults = UserDefaults(suiteName: "ExamRulesTests")!
        defaults.removePersistentDomain(forName: "ExamRulesTests")
        let vm = QuizViewModel(progress: UserProgress(testDefaults: defaults))
        for format in ExamFormat.allCases {
            let rules = ExamRules(format: format)
            vm.setupExam(format: format)
            XCTAssertEqual(vm.questions.count, rules.totalCount, format.rawValue)
            for part in rules.parts {
                XCTAssertEqual(vm.questions.filter { $0.examType == part.type }.count, part.count, format.rawValue)
            }
            XCTAssertEqual(Set(vm.questions.map(\.uniqueId)).count, rules.totalCount, "no duplicates")
            XCTAssertEqual(vm.timeRemaining, rules.minutes * 60)
            XCTAssertTrue(vm.examMode)
        }
    }

    func testExamScoringCountsEveryPart() {
        let defaults = UserDefaults(suiteName: "ExamScoring")!
        defaults.removePersistentDomain(forName: "ExamScoring")
        let vm = QuizViewModel(progress: UserProgress(testDefaults: defaults))
        vm.setupExam(format: .binnenMotorSail)
        // Answer every question correctly.
        while vm.state != .finished {
            guard let q = vm.current else { break }
            let correctKey = vm.shuffledOptions(for: q).first { vm.isCorrect($0.key, for: q) }!.key
            vm.select(correctKey)
            vm.next()
        }
        let result = vm.examResult
        XCTAssertEqual(result?.correct, [.shared: 7, .binnen: 23, .segeln: 7])
        XCTAssertEqual(result?.passed, true)
    }

    func testLicenceGoalOffersMatchingExams() {
        XCTAssertEqual(LicenceGoal.standard.examFormats, [.binnenMotor, .see])
        XCTAssertEqual(LicenceGoal(inland: .motorAndSail, sea: false).examFormats, [.binnenMotorSail])
        XCTAssertEqual(LicenceGoal(inland: .sailAddOn, sea: true).examFormats, [.sailAddOn, .see])
        XCTAssertFalse(LicenceGoal(inland: .none, sea: false).isValid)

        let defaults = UserDefaults(suiteName: "LicenceGoal")!
        defaults.removePersistentDomain(forName: "LicenceGoal")
        let progress = UserProgress(testDefaults: defaults)
        XCTAssertFalse(progress.hasChosenLicence)
        progress.setLicenceGoal(LicenceGoal(inland: .sail, sea: false))
        let reloaded = UserProgress(testDefaults: defaults)
        XCTAssertTrue(reloaded.hasChosenLicence)
        XCTAssertEqual(reloaded.licenceGoal, LicenceGoal(inland: .sail, sea: false))
    }

    func testOldExamRecordsKeepTheirTitle() throws {
        let json = #"{"date":0,"examType":"See","totalQuestions":30,"correctAnswers":25,"isExam":true,"passed":true}"#
        let record = try JSONDecoder().decode(QuizRecord.self, from: Data(json.utf8))
        XCTAssertEqual(record.format, .see)
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

@MainActor
final class FeatureFlagTests: XCTestCase {
    func testFlagsAreOffByDefaultAndPersist() {
        let defaults = UserDefaults(suiteName: "FeatureFlagTests")!
        defaults.removePersistentDomain(forName: "FeatureFlagTests")
        let flags = FeatureFlags(defaults: defaults)
        XCTAssertTrue(flags.enabled.isEmpty)
        flags.set(.navigationTasks, true)
        XCTAssertTrue(FeatureFlags(defaults: defaults).isOn(.navigationTasks))
        flags.set(.navigationTasks, false)
        XCTAssertFalse(FeatureFlags(defaults: defaults).isOn(.navigationTasks))
    }
}
