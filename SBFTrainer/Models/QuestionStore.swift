import Foundation

@MainActor
final class QuestionStore: ObservableObject {
    static let shared = QuestionStore()

    private(set) var allQuestions: [Question] = []
    private(set) var sections: [ExamSection] = []

    private init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "sbf_exam_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let examData = try? JSONDecoder().decode(ExamData.self, from: data)
        else { return }

        sections = examData.examSections
        allQuestions = examData.examSections.flatMap { $0.questions }
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
