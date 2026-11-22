import Foundation

@MainActor
final class QuestionStore: ObservableObject {
    static let shared = QuestionStore()

    private(set) var allQuestions: [Question] = []
    private(set) var sections: [ExamSection] = []
    /// Binnen/See questions that are free without a purchase (about 1 in 7 per category).
    private(set) var freeSampleIds: Set<String> = []

    /// Every Nth question of each Binnen/See category is part of the free sample.
    static let freeSampleInterval = 7

    private init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "sbf_exam_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let examData = try? JSONDecoder().decode(ExamData.self, from: data)
        else { return }

        sections = examData.examSections
        allQuestions = examData.examSections.flatMap { $0.questions }
        freeSampleIds = Self.makeFreeSample(from: allQuestions)
    }

    /// Fixed, deterministic sample: within each exam type and category, sorted by question
    /// number, the 1st, 8th, 15th … question is free. Never changes between launches.
    private static func makeFreeSample(from questions: [Question]) -> Set<String> {
        var ids: Set<String> = []
        let paid = questions.filter { $0.examType == .binnen || $0.examType == .see }
        let groups = Dictionary(grouping: paid) { "\($0.examType.rawValue)|\($0.category)" }
        for (_, group) in groups {
            let sorted = group.sorted { $0.questionNumber < $1.questionNumber }
            for (index, q) in sorted.enumerated() where index % freeSampleInterval == 0 {
                ids.insert(q.uniqueId)
            }
        }
        return ids
    }

    // MARK: - Free vs Pro

    /// Basisfragen are always free; Binnen/See questions need the matching purchase
    /// unless they are in the free sample.
    func isUnlocked(_ question: Question) -> Bool {
        switch question.examType {
        case .shared, .all: return true
        case .binnen, .see:
            return freeSampleIds.contains(question.uniqueId)
                || EntitlementManager.shared.hasAccess(to: question.examType)
        }
    }

    /// Questions the user can practise right now.
    func availableQuestions(for type: ExamType, category: String? = nil) -> [Question] {
        questions(for: type, category: category).filter(isUnlocked)
    }

    func questions(for type: ExamType) -> [Question] {
        switch type {
        case .all:    return allQuestions
        case .shared: return allQuestions.filter { $0.examType == .shared }
        case .binnen: return allQuestions.filter { $0.examType == .binnen || $0.examType == .shared }
        case .see:    return allQuestions.filter { $0.examType == .see    || $0.examType == .shared }
        }
    }

    func categories(for type: ExamType) -> [String] {
        Array(Set(questions(for: type).map { $0.category })).sorted()
    }

    func questions(for type: ExamType, category: String?) -> [Question] {
        let base = questions(for: type)
        guard let category else { return base }
        return base.filter { $0.category == category }
    }

    func question(id: String) -> Question? {
        allQuestions.first { $0.uniqueId == id }
    }
}
