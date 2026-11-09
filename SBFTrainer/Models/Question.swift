import Foundation
import SwiftUI

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
    let categoryDE: String?
    let germanText: String
    let englishText: String
    let options: [String: QuestionOption]
    let correctOption: String
    let hasImage: Bool
    let imageReference: String?
    let imageReferences: [String]?
    let soundPattern: String?
    let explanationDE: String?
    let explanationEN: String?

    var id: String { uniqueId }

    enum CodingKeys: String, CodingKey {
        case category, options
        case uniqueId = "unique_id"
        case questionNumber = "question_number"
        case categoryDE = "category_de"
        case germanText = "german_text"
        case englishText = "english_text"
        case correctOption = "correct_option"
        case hasImage = "has_image"
        case imageReference = "image_reference"
        case imageReferences = "image_references"
        case soundPattern = "sound_pattern"
        case explanationDE = "explanation_de"
        case explanationEN = "explanation_en"
    }

    var examType: ExamType {
        if uniqueId.hasPrefix("shared") { return .shared }
        if uniqueId.hasPrefix("binnen") { return .binnen }
        if uniqueId.hasPrefix("segeln") { return .segeln }
        return .see
    }

    /// Category name in the app's display language.
    var localizedCategory: String { AppLanguage.isGerman ? (categoryDE ?? category) : category }

    /// Explanation in the app's display language (falls back to the other language).
    var localizedExplanation: String? {
        AppLanguage.isGerman ? (explanationDE ?? explanationEN) : (explanationEN ?? explanationDE)
    }

    var imageURLs: [URL] {
        let refs = imageReferences ?? (imageReference.map { [$0] } ?? [])
        return refs.compactMap { ref in
            let parts = ref.split(separator: "/").map(String.init)
            guard parts.count == 3 else { return nil }
            return Bundle.main.url(forResource: (parts[2] as NSString).deletingPathExtension,
                                   withExtension: "png",
                                   subdirectory: "assets/\(parts[1])")
        }
    }

    var imageURL: URL? { imageURLs.first }

    /// True when the question has an illustration or a playable sound signal.
    var hasMedia: Bool { hasImage || soundPattern != nil }

    /// Options in catalogue order (in the official catalogue A is always correct).
    var sortedOptions: [(key: String, value: QuestionOption)] {
        options.sorted { $0.key < $1.key }
    }

    /// Options in a stable, per-question shuffled order, relabelled A–D.
    /// Used when browsing so the correct answer is not always "A".
    var displayOptions: [(key: String, value: QuestionOption, isCorrect: Bool)] {
        let keys = sortedOptions.map(\.key)
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: uniqueId.stableHash))
        let shuffled = keys.shuffled(using: &rng)
        return keys.enumerated().compactMap { index, label in
            let original = shuffled[index]
            guard let option = options[original] else { return nil }
            return (key: label, value: option, isCorrect: original == correctOption)
        }
    }

    static func == (lhs: Question, rhs: Question) -> Bool { lhs.uniqueId == rhs.uniqueId }
    func hash(into hasher: inout Hasher) { hasher.combine(uniqueId) }
}

struct QuestionOption: Codable, Hashable {
    let german: String
    let english: String
}

enum ExamType: String, CaseIterable, Identifiable, Codable {
    case all    = "All"
    case shared = "Shared"
    case binnen = "Binnen"
    case segeln = "Segeln"
    case see    = "See"

    var id: String { rawValue }

    /// Localised name (German official terms: Basisfragen, Binnen, See, Segeln).
    var title: String {
        switch self {
        case .all:    return String(localized: "All", comment: "Exam type: all questions")
        case .shared: return String(localized: "Basic", comment: "Exam type: Basisfragen shared by both licences")
        case .binnen: return String(localized: "Inland", comment: "Exam type: SBF Binnen")
        case .see:    return String(localized: "Sea", comment: "Exam type: SBF See")
        case .segeln: return String(localized: "Sailing", comment: "Exam type: sailing questions of the SBF Binnen")
        }
    }

    /// Full licence name.
    var licenceName: String {
        switch self {
        case .all:    return String(localized: "All questions")
        case .shared: return String(localized: "Basic questions")
        case .binnen: return String(localized: "SBF Inland")
        case .see:    return String(localized: "SBF Sea")
        case .segeln: return String(localized: "SBF Inland · sailing")
        }
    }

    /// Short noun for an exam part, e.g. "7 basic + 23 inland".
    var partNoun: String {
        switch self {
        case .all:    return String(localized: "questions", comment: "Exam part noun")
        case .shared: return String(localized: "basic", comment: "Exam part noun: 7 basic + 23 inland")
        case .binnen: return String(localized: "inland", comment: "Exam part noun: 7 basic + 23 inland")
        case .see:    return String(localized: "sea", comment: "Exam part noun: 7 basic + 23 sea")
        case .segeln: return String(localized: "sailing", comment: "Exam part noun: 7 basic + 23 inland + 7 sailing")
        }
    }

    /// Heading of an exam part in the result.
    var partTitle: String {
        switch self {
        case .all, .shared: return String(localized: "Basic questions")
        case .binnen:       return String(localized: "Inland questions")
        case .see:          return String(localized: "Sea questions")
        case .segeln:       return String(localized: "Sailing questions")
        }
    }

    var icon: String {
        switch self {
        case .all:    return "rectangle.stack"
        case .shared: return "star.circle"
        case .binnen: return "water.waves"
        case .see:    return "wind"
        case .segeln: return "sailboat"
        }
    }
}

enum AppLanguage {
    /// True when the app is running with its German localisation.
    static var isGerman: Bool { Bundle.main.preferredLocalizations.first?.hasPrefix("de") ?? false }
}

// MARK: - Deterministic shuffling

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {          // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

extension String {
    /// FNV-1a hash that is stable across launches (unlike `hashValue`).
    var stableHash: UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
