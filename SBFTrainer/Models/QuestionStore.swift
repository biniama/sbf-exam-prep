import Foundation

@MainActor
final class QuestionStore: ObservableObject {
    static let shared = QuestionStore()

    private(set) var allQuestions: [Question] = []
    private(set) var sections: [ExamSection] = []
    private(set) var loadError: String?
    private var byId: [String: Question] = [:]

    private init() { load() }

    private func load() {
        do {
            guard let url = Bundle.main.url(forResource: "sbf_exam_questions", withExtension: "json") else {
                loadError = "sbf_exam_questions.json is missing from the app bundle"
                assertionFailure(loadError!)
                return
            }
            let examData = try JSONDecoder().decode(ExamData.self, from: Data(contentsOf: url))
            sections = examData.examSections
            allQuestions = examData.examSections.flatMap { $0.questions }
            byId = Dictionary(uniqueKeysWithValues: allQuestions.map { ($0.uniqueId, $0) })
        } catch {
            loadError = "Could not load questions: \(error)"
            assertionFailure(loadError!)
        }
    }

    /// Questions of an exam. Basic questions (Basisfragen) belong to both licences;
    /// the sailing questions are an additional part of the SBF Binnen and are listed on their own.
    func questions(for type: ExamType) -> [Question] {
        switch type {
        case .all:    return allQuestions
        case .shared: return allQuestions.filter { $0.examType == .shared }
        case .binnen: return allQuestions.filter { $0.examType == .binnen || $0.examType == .shared }
        case .see:    return allQuestions.filter { $0.examType == .see    || $0.examType == .shared }
        case .segeln: return allQuestions.filter { $0.examType == .segeln }
        }
    }

    /// Questions of one exam part only (without the shared basic questions).
    func specificQuestions(for type: ExamType) -> [Question] {
        allQuestions.filter { $0.examType == type }
    }

    /// Canonical (English) category keys, sorted by their localised name.
    func categories(for type: ExamType) -> [String] {
        Array(Set(questions(for: type).map(\.category)))
            .sorted { categoryName($0).localizedStandardCompare(categoryName($1)) == .orderedAscending }
    }

    /// Localised display name for a canonical category key.
    func categoryName(_ key: String) -> String {
        allQuestions.first { $0.category == key }?.localizedCategory ?? key
    }

    func questions(for type: ExamType, category: String?) -> [Question] {
        let base = questions(for: type)
        guard let category else { return base }
        return base.filter { $0.category == category }
    }

    func question(id: String) -> Question? { byId[id] }
}
