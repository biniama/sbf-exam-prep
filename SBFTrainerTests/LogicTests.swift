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

@MainActor
final class NavigationExamTests: XCTestCase {
    private var catalog: NavigationCatalog { NavigationStore.shared.catalog! }
    private func step(_ task: Int, _ number: Int) -> NavigationStep {
        catalog.tasks[task - 1].steps[number - 1]
    }

    func testAnswerCheckerUsesPracticeTolerances() {
        let t = catalog.tolerances
        // Task 1: MgK 074°, distance 6.1 nm, 45.75 min, DR position, two bearings, set and drift.
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 2), inputs: ["74"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 2), inputs: ["077"], tolerances: t), false)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 3), inputs: ["6,2"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 4), inputs: ["46"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 5), inputs: ["53", "55,9", "7", "51,2"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 5), inputs: ["53", "56,5", "7", "51,3"], tolerances: t), false)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 6), inputs: ["170", "065"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(1, 8), inputs: ["100", "0.8"], tolerances: t), true)
        XCTAssertNil(NavigationAnswerChecker.isCorrect(step(1, 7), inputs: [""], tolerances: t), "chart work is self-graded")
        // Task 3: arrival 15:12; task 12: course 007° wraps around north.
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(3, 5), inputs: ["15:13"], tolerances: t), true)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(12, 3), inputs: ["359"], tolerances: t), false)
        XCTAssertEqual(NavigationAnswerChecker.isCorrect(step(12, 3), inputs: ["8"], tolerances: t), true)
    }

    func testNavigationPartMustBePassedInTheSeaExam() {
        let rules = ExamRules(format: .see, includeNavigation: true)
        XCTAssertEqual(rules.navigationCount, 9)
        XCTAssertFalse(rules.excludesNavigationTask)
        XCTAssertTrue(rules.result(correct: [.shared: 7, .see: 23], navigationCorrect: 7).passed)
        XCTAssertFalse(rules.result(correct: [.shared: 7, .see: 23], navigationCorrect: 6).passed)
        XCTAssertEqual(ExamRules(format: .binnenMotor, includeNavigation: true).navigationCount, 0, "Sea exam only")
    }

    func testExamFlowShowsTheNavigationTaskAfterTheQuestions() {
        let defaults = UserDefaults(suiteName: "NavigationExamFlow")!
        defaults.removePersistentDomain(forName: "NavigationExamFlow")
        let vm = QuizViewModel(progress: UserProgress(testDefaults: defaults))
        vm.setupExam(format: .see, includeNavigation: true)
        XCTAssertNotNil(vm.navigationPart)
        while vm.state != .navigation && vm.state != .finished {
            guard let q = vm.current else { break }
            vm.select(vm.shuffledOptions(for: q)[0].key)
            vm.next()
        }
        XCTAssertEqual(vm.state, .navigation)
        vm.finish()
        XCTAssertEqual(vm.state, .finished)
        XCTAssertEqual(vm.examResult?.navigationCorrect, 0)
    }
}

final class NavigationDrillTests: XCTestCase {
    func testEveryDrillAcceptsItsOwnAnswer() {
        for kind in NavigationDrill.Kind.allCases {
            for _ in 0..<200 {
                let drill = NavigationDrill.make(kind)
                if kind == .light {
                    XCTAssertTrue(drill.check(choice: drill.light!))
                    XCTAssertEqual(drill.choices.count, 4)
                    XCTAssertEqual(Set(drill.choices.map(\.code)).count, 4)
                    XCTAssertEqual(Set(drill.choices.map(\.colour)).count, 1, "colour must not give the answer away")
                } else if drill.isClock {
                    let m = Int(drill.answer)
                    XCTAssertTrue(drill.check(String(format: "%02d:%02d", (m / 60) % 24, m % 60)), drill.prompt)
                } else {
                    XCTAssertTrue(drill.check(String(format: "%.2f", drill.answer)), drill.prompt)
                    XCTAssertFalse(drill.check(String(format: "%.2f", drill.answer + 5)), drill.prompt)
                }
            }
        }
    }

    func testLightCharactersHaveTheRightRhythm() {
        for code in LightCharacter.drillCodes {
            XCTAssertNotNil(LightCharacter(code), code)
        }
        let iso = LightCharacter("Iso.W.8s")!
        XCTAssertEqual(iso.period, 8)
        XCTAssertTrue(iso.isOn(at: 1))
        XCTAssertFalse(iso.isOn(at: 5))
        let oc3 = LightCharacter("Oc(3).Y.12s")!
        XCTAssertEqual(oc3.period, 12, accuracy: 0.001)
        XCTAssertEqual(oc3.phases.filter { !$0.on }.count, 3, "three eclipses")
        XCTAssertEqual(LightCharacter("Q(3).W.10s")!.phases.filter(\.on).count, 3)
        XCTAssertEqual(LightCharacter("Fl.Y.4s")!.colour, .yellow)
        XCTAssertNil(LightCharacter("Xyz.W.4s"))
    }
}
