import Foundation
import SwiftUI
import UIKit

enum QuizState { case answering, revealed, finished }

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentIndex: Int = 0
    @Published var selectedOption: String? = nil
    @Published var state: QuizState = .answering
    @Published var correctCount: Int = 0
    @Published var wrongIds: [String] = []
    @Published var examType: ExamType = .all
    @Published var animateCard: Bool = false
    @Published var examMode: Bool = false
    @Published var timeRemaining: Int = 1800  // 30 minutes

    private let store = QuestionStore.shared
    private let progress = UserProgress.shared
    // Maps questionId → (displayKey → originalKey), so A/B/C/D order is fixed but content is shuffled
    private var keyRemaps: [String: [String: String]] = [:]
    private var timerTask: Task<Void, Never>?

    var current: Question? { questions.indices.contains(currentIndex) ? questions[currentIndex] : nil }
    var isLast: Bool { currentIndex >= questions.count - 1 }
    var progressFraction: Double { questions.isEmpty ? 0 : Double(currentIndex) / Double(questions.count) }

    var examPassed: Bool {
        guard examMode, !questions.isEmpty else { return false }
        return Double(correctCount) / Double(questions.count) >= 0.7
    }

    var formattedTime: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%d:%02d", m, s)
    }

    var timeFraction: Double {
        guard examMode else { return 1 }
        return Double(timeRemaining) / 1800.0
    }

    // MARK: - Setup

    func setup(type: ExamType, count: Int, category: String? = nil,
               fromWrong: Bool = false, examMode: Bool = false, shuffle: Bool = true) {
        timerTask?.cancel()
        self.examMode = examMode
        self.examType = type
        self.timeRemaining = 1800

        var pool: [Question]
        if fromWrong {
            let ids = Array(progress.wrongAnswerIds.keys)
            pool = ids.compactMap { store.question(id: $0) }
            if shuffle { pool = pool.shuffled() }
        } else {
            pool = store.questions(for: type, category: category)
            if shuffle { pool = pool.shuffled() }
        }
        questions = Array(pool.prefix(count))
        currentIndex = 0
        selectedOption = nil
        state = .answering
        correctCount = 0
        wrongIds = []
        keyRemaps = [:]
        for q in questions {
            let displayKeys = q.sortedOptions.map(\.key)          // ["A","B","C","D"] — fixed display order
            let shuffledOriginals = displayKeys.shuffled()         // original keys assigned randomly to each slot
            var remap: [String: String] = [:]
            for (i, displayKey) in displayKeys.enumerated() {
                remap[displayKey] = shuffledOriginals[i]
            }
            keyRemaps[q.uniqueId] = remap
        }

        if examMode { startTimer() }
    }

    func shuffledOptions(for question: Question) -> [(key: String, value: QuestionOption)] {
        guard let remap = keyRemaps[question.uniqueId] else {
            return question.sortedOptions
        }
        // Always return A, B, C, D in order; content is taken from the remapped original key
        return question.sortedOptions.map(\.key).compactMap { displayKey in
            guard let originalKey = remap[displayKey],
                  let opt = question.options[originalKey] else { return nil }
            return (key: displayKey, value: opt)
        }
    }

    // MARK: - Answer

    func select(_ option: String) {
        guard state == .answering, let q = current else { return }
        selectedOption = option
        state = .revealed
        let originalKey = keyRemaps[q.uniqueId]?[option] ?? option
        let isCorrect = originalKey == q.correctOption

        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(isCorrect ? .success : .error)

        if isCorrect { correctCount += 1 } else { wrongIds.append(q.uniqueId) }
        progress.recordAnswer(questionId: q.uniqueId, category: q.category, correct: isCorrect)
        withAnimation(.spring(response: 0.4)) { animateCard = true }
    }

    // MARK: - Navigation

    func next() {
        withAnimation(.easeInOut(duration: 0.2)) { animateCard = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.isLast {
                self.state = .finished
                self.timerTask?.cancel()
                let record = QuizRecord(
                    date: Date(),
                    examType: self.examType.rawValue,
                    totalQuestions: self.questions.count,
                    correctAnswers: self.correctCount
                )
                self.progress.saveQuizRecord(record)
            } else {
                self.currentIndex += 1
                self.selectedOption = nil
                self.state = .answering
            }
        }
    }

    // MARK: - Option colours / icons

    func optionColor(_ option: String) -> Color {
        guard state == .revealed, let q = current else { return .clear }
        let originalKey = keyRemaps[q.uniqueId]?[option] ?? option
        if originalKey == q.correctOption { return Color.successGreen }
        if option == selectedOption        { return Color.errorRed }
        return .clear
    }

    func optionIcon(_ option: String) -> String? {
        guard state == .revealed, let q = current else { return nil }
        let originalKey = keyRemaps[q.uniqueId]?[option] ?? option
        if originalKey == q.correctOption { return "checkmark.circle.fill" }
        if option == selectedOption        { return "xmark.circle.fill" }
        return nil
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask = Task { @MainActor in
            while timeRemaining > 0 && state != .finished && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                timeRemaining -= 1
                if timeRemaining == 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    state = .finished
                    let record = QuizRecord(
                        date: Date(),
                        examType: examType.rawValue,
                        totalQuestions: questions.count,
                        correctAnswers: correctCount
                    )
                    progress.saveQuizRecord(record)
                }
            }
        }
    }
}
