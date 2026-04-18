import Foundation

struct ExamData: Codable {
    let metadata: Metadata
    let examSections: [ExamSection]

    enum CodingKeys: String, CodingKey {
        case metadata
        case examSections = "exam_sections"
    }
}

struct Metadata: Codable {
    let title: String
    let catalogDate: String
    let totalQuestions: Int
    let languages: [String]
    let note: String

    enum CodingKeys: String, CodingKey {
        case title, note, languages
        case catalogDate = "catalog_date"
        case totalQuestions = "total_questions"
    }
}

struct ExamSection: Codable, Identifiable {
    var id: String { examType }
    let examType: String
    let description: String
    let questionCount: Int
    let questions: [Question]

    enum CodingKeys: String, CodingKey {
        case description, questions
        case examType = "exam_type"
        case questionCount = "total"
    }
}

struct Question: Codable, Identifiable, Hashable {
    let uniqueId: String
    let questionNumber: Int
    let category: String
    let germanText: String
    let englishText: String
    let options: [String: QuestionOption]
    let correctOption: String
    let hasImage: Bool
    let imageReference: String?

    var id: String { uniqueId }

    enum CodingKeys: String, CodingKey {
        case category, options
        case uniqueId = "unique_id"
        case questionNumber = "question_number"
        case germanText = "german_text"
        case englishText = "english_text"
        case correctOption = "correct_option"
        case hasImage = "has_image"
        case imageReference = "image_reference"
    }

    var examType: ExamType {
        if uniqueId.hasPrefix("shared") { return .shared }
        if uniqueId.hasPrefix("binnen") { return .binnen }
        return .see
    }

    var imageURL: URL? {
        guard let ref = imageReference else { return nil }
        // ref is like "assets/shared/shared_016.png"
        let parts = ref.split(separator: "/").map(String.init)
        guard parts.count == 3 else { return nil }
        return Bundle.main.url(forResource: parts[2].replacingOccurrences(of: ".png", with: ""),
                               withExtension: "png",
                               subdirectory: "assets/\(parts[1])")
    }

    var sortedOptions: [(key: String, value: QuestionOption)] {
        options.sorted { $0.key < $1.key }
    }

    static func == (lhs: Question, rhs: Question) -> Bool { lhs.uniqueId == rhs.uniqueId }
    func hash(into hasher: inout Hasher) { hasher.combine(uniqueId) }
}

struct QuestionOption: Codable {
    let german: String
    let english: String
}

enum ExamType: String, CaseIterable, Identifiable {
    case all    = "All"
    case shared = "Shared"
    case binnen = "Binnen"
    case see    = "See"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:    return "rectangle.stack"
        case .shared: return "star.circle"
        case .binnen: return "water.waves"
        case .see:    return "wind.snow"
        }
    }

    var color: String {
        switch self {
        case .all:    return "ocean"
        case .shared: return "gold"
        case .binnen: return "teal"
        case .see:    return "navy"
        }
    }
}
