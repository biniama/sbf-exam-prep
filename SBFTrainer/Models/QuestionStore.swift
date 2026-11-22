import Foundation

@MainActor
final class QuestionStore: ObservableObject {
    static let shared = QuestionStore()

    private(set) var allQuestions: [Question] = []
    private(set) var sections: [ExamSection] = []
    private(set) var loadError: String?
    private var byId: [String: Question] = [:]
    /// Inland, sailing and sea questions that are free without a purchase (about 1 in 7 per topic).
    private(set) var freeSampleIds: Set<String> = []

    /// Every Nth question of each topic is part of the free sample.
    static let freeSampleInterval = 7

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
            freeSampleIds = Self.makeFreeSample(from: allQuestions)
        } catch {
            loadError = "Could not load questions: \(error)"
            assertionFailure(loadError!)
        }
    }

    // MARK: - Free vs full version

    /// Fixed sample: within each exam part and topic, sorted by question number, the 1st, 8th,
    /// 15th … question is free. Never changes between launches. Must match the Android app.
    static func makeFreeSample(from questions: [Question]) -> Set<String> {
        let paid = questions.filter { $0.examType != .shared }
        let groups = Dictionary(grouping: paid) { "\($0.examType.rawValue)|\($0.category)" }
        var ids: Set<String> = []
        for group in groups.values {
            let sorted = group.sorted { $0.questionNumber < $1.questionNumber }
            for (index, q) in sorted.enumerated() where index % freeSampleInterval == 0 {
                ids.insert(q.uniqueId)
            }
        }
        return ids
    }

    /// Basic questions are always free; the rest needs the matching purchase unless it is in
    /// the free sample.
    func isUnlocked(_ question: Question) -> Bool {
        question.examType == .shared
            || freeSampleIds.contains(question.uniqueId)
            || EntitlementManager.shared.hasAccess(to: question.examType)
    }

    /// Questions the user can practise right now.
    func availableQuestions(for type: ExamType, category: String? = nil) -> [Question] {
        questions(for: type, category: category).filter { isUnlocked($0) }
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
