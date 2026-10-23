import Foundation
import SwiftUI
import UIKit

enum QuizState { case answering, revealed, finished }

enum QuizMode: Equatable {
    case practice
    case exam(ExamRules)
    case review         // spaced-repetition questions that are due
    case mistakes
    case saved

    var isExam: Bool { if case .exam = self { return true } else { return false } }
}

@MainActor
final class QuizViewModel: ObservableObject {
    @Published private(set) var questions: [Question] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var selectedOption: String? = nil
    @Published private(set) var state: QuizState = .answering
    @Published private(set) var correctCount: Int = 0
    @Published private(set) var wrongIds: [String] = []
    @Published private(set) var examType: ExamType = .all
    @Published private(set) var mode: QuizMode = .practice
    @Published private(set) var timeRemaining: Int = 0

    private let store: QuestionStore
    private let progress: UserProgress
    /// questionId → (displayKey → originalKey): A–D stay in order, content is shuffled.
    private var keyRemaps: [String: [String: String]] = [:]
    private var answers: [String: Bool] = [:]
    private var timerTask: Task<Void, Never>?

    init(store: QuestionStore = .shared, progress: UserProgress = .shared) {
        self.store = store
        self.progress = progress
    }

    var current: Question? { questions.indices.contains(currentIndex) ? questions[currentIndex] : nil }
    var isLast: Bool { currentIndex >= questions.count - 1 }
    var progressFraction: Double { questions.isEmpty ? 0 : Double(currentIndex) / Double(questions.count) }
    var examMode: Bool { mode.isExam }

    var examRules: ExamRules? { if case .exam(let r) = mode { return r } else { return nil } }

    /// Official scoring: correct answers are counted per exam part.
    var examResult: ExamResult? {
        guard let rules = examRules else { return nil }
        var correct: [ExamType: Int] = [:]
        for q in questions where answers[q.uniqueId] == true { correct[q.examType, default: 0] += 1 }
        return rules.result(correct: correct)
    }

    var examPassed: Bool { examResult?.passed ?? false }

    var formattedTime: String { String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60) }

    var timeFraction: Double {
        guard let rules = examRules else { return 1 }
        return Double(timeRemaining) / Double(rules.minutes * 60)
    }

    // MARK: - Setup

    /// Practice quiz from the catalogue.
    func setup(type: ExamType, count: Int, category: String? = nil, shuffle: Bool = true) {
        var pool = store.questions(for: type, category: category)
        if shuffle { pool.shuffle() }
        start(Array(pool.prefix(count)), type: type, mode: .practice)
    }

    /// Quiz over the questions answered wrongly so far.
    func setupMistakes(limit: Int = 30) {
        let ids = progress.wrongAnswerIds.sorted { $0.value > $1.value }.map(\.key)
        let qs = ids.compactMap { store.question(id: $0) }
        start(Array(qs.prefix(limit)).shuffled(), type: .all, mode: .mistakes)
    }

    /// Spaced-repetition session with the questions that are due today.
    func setupDueReview(limit: Int = 30) {
        let qs = progress.dueQuestionIds().compactMap { store.question(id: $0) }
        start(Array(qs.prefix(limit)), type: .all, mode: .review)
    }

    /// Quiz over an explicit list (e.g. saved questions).
    func setup(questions qs: [Question], mode: QuizMode = .saved, shuffle: Bool = true) {
        start(shuffle ? qs.shuffled() : qs, type: .all, mode: mode)
    }

    /// Exam simulation following the official composition, e.g. 7 basic + 23 inland questions.
    func setupExam(format: ExamFormat) {
        let rules = ExamRules(format: format)
        let qs = rules.parts.flatMap { store.specificQuestions(for: $0.type).shuffled().prefix($0.count) }
        start(qs, type: rules.parts.last?.type ?? .all, mode: .exam(rules))
    }

    /// Same questions again, answer order reshuffled.
    func retry() {
        if let rules = examRules {
            setupExam(format: rules.format)
        } else {
            start(questions.shuffled(), type: examType, mode: mode)
        }
    }

    private func start(_ qs: [Question], type: ExamType, mode: QuizMode) {
        timerTask?.cancel()
        self.mode = mode
        examType = type
        questions = qs
        currentIndex = 0
        selectedOption = nil
        state = .answering
        correctCount = 0
        wrongIds = []
        answers = [:]
        keyRemaps = [:]
        for q in qs {
            let displayKeys = q.sortedOptions.map(\.key)
            let shuffled = displayKeys.shuffled()
            keyRemaps[q.uniqueId] = Dictionary(uniqueKeysWithValues: zip(displayKeys, shuffled))
        }
        if let rules = examRules {
            timeRemaining = rules.minutes * 60
            startTimer()
        } else {
            timeRemaining = 0
        }
    }

    func shuffledOptions(for question: Question) -> [(key: String, value: QuestionOption)] {
        guard let remap = keyRemaps[question.uniqueId] else { return question.sortedOptions }
        return question.sortedOptions.map(\.key).compactMap { displayKey in
            guard let original = remap[displayKey], let opt = question.options[original] else { return nil }
            return (key: displayKey, value: opt)
        }
    }

    func isCorrect(_ displayKey: String, for question: Question) -> Bool {
        (keyRemaps[question.uniqueId]?[displayKey] ?? displayKey) == question.correctOption
    }

    // MARK: - Answer

    func select(_ option: String) {
        guard state == .answering, let q = current else { return }
        selectedOption = option
        state = .revealed
        let correct = isCorrect(option, for: q)
        answers[q.uniqueId] = correct

        if correct { correctCount += 1 } else { wrongIds.append(q.uniqueId) }
        progress.recordAnswer(questionId: q.uniqueId, category: q.category, correct: correct)

        // Like the real exam, a simulation gives no feedback until the end.
        if examMode {
            UISelectionFeedbackGenerator().selectionChanged()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
            let announcement = correct ? String(localized: "Correct") : String(localized: "Wrong")
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    // MARK: - Navigation

    func next() {
        if isLast {
            finish()
        } else {
            currentIndex += 1
            selectedOption = nil
            state = .answering
        }
    }

    /// Ends the quiz (also used when the exam time runs out).
    func finish() {
        guard state != .finished else { return }
        state = .finished
        timerTask?.cancel()
        guard !questions.isEmpty else { return }
        var record = QuizRecord(date: .now, examType: examType.rawValue,
                                totalQuestions: questions.count, correctAnswers: correctCount)
        if let result = examResult {
            record.isExam = true
            record.passed = result.passed
            record.examFormat = result.rules.format.rawValue
        }
        progress.saveQuizRecord(record)
    }

    // MARK: - Option colours / icons

    func optionColor(_ option: String) -> Color {
        guard state == .revealed, let q = current else { return .clear }
        if isCorrect(option, for: q) { return .successGreen }
        if option == selectedOption { return .errorRed }
        return .clear
    }

    func optionIcon(_ option: String) -> String? {
        guard state == .revealed, let q = current else { return nil }
        if isCorrect(option, for: q) { return "checkmark.circle.fill" }
        if option == selectedOption { return "xmark.circle.fill" }
        return nil
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask = Task { @MainActor [weak self] in
            while let self, self.timeRemaining > 0, self.state != .finished, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                self.timeRemaining -= 1
                if self.timeRemaining == 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    self.finish()
                }
            }
        }
    }
}
