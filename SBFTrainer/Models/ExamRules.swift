import Foundation

/// Exam formats of the multiple-choice theory exam that the app simulates
/// (Bewertungsschlüssel, ELWIS, as of 31 Oct 2022).
enum ExamFormat: String, CaseIterable, Identifiable, Codable {
    case binnenMotor     = "binnen-motor"
    case binnenSail      = "binnen-sail"
    case binnenMotorSail = "binnen-motor-sail"
    case sailAddOn       = "sail-addon"
    case see             = "see"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .binnenMotor:     return String(localized: "Inland · motor")
        case .binnenSail:      return String(localized: "Inland · sail")
        case .binnenMotorSail: return String(localized: "Inland · motor + sail")
        case .sailAddOn:       return String(localized: "Sailing add-on")
        case .see:             return String(localized: "Sea")
        }
    }

    /// For tight spaces such as the result stat card.
    var shortTitle: String {
        switch self {
        case .binnenMotor:     return String(localized: "Motor")
        case .binnenSail:      return String(localized: "Sail")
        case .binnenMotorSail: return String(localized: "Motor + sail")
        case .sailAddOn:       return String(localized: "Sailing add-on")
        case .see:             return String(localized: "Sea")
        }
    }

    var icon: String {
        switch self {
        case .binnenMotor:              return "water.waves"
        case .binnenSail, .sailAddOn:   return "sailboat"
        case .binnenMotorSail:          return "sailboat.fill"
        case .see:                      return "wind"
        }
    }
}

/// One separately counted part of an exam (basic, inland, sailing or sea questions).
struct ExamPart: Equatable, Identifiable {
    let type: ExamType
    let count: Int
    /// Minimum correct answers for this part; `nil` when only the total counts.
    let passMark: Int?

    var id: ExamType { type }
}

struct ExamRules: Equatable {
    let format: ExamFormat
    let parts: [ExamPart]
    /// Minimum correct answers over all parts (SBF Binnen under sail only).
    let totalPassMark: Int?
    let minutes: Int

    init(format: ExamFormat) {
        self.format = format
        switch format {
        case .binnenMotor:
            parts = [ExamPart(type: .shared, count: 7, passMark: 5), ExamPart(type: .binnen, count: 23, passMark: 18)]
            totalPassMark = nil
            minutes = 45
        case .binnenSail:
            parts = [ExamPart(type: .shared, count: 4, passMark: nil), ExamPart(type: .binnen, count: 14, passMark: nil),
                     ExamPart(type: .segeln, count: 7, passMark: nil)]
            totalPassMark = 20
            minutes = 35
        case .binnenMotorSail:
            parts = [ExamPart(type: .shared, count: 7, passMark: 5), ExamPart(type: .binnen, count: 23, passMark: 18),
                     ExamPart(type: .segeln, count: 7, passMark: 5)]
            totalPassMark = nil
            minutes = 60
        case .sailAddOn:
            parts = [ExamPart(type: .segeln, count: 7, passMark: 5)]
            totalPassMark = nil
            minutes = 15
        case .see:
            parts = [ExamPart(type: .shared, count: 7, passMark: 5), ExamPart(type: .see, count: 23, passMark: 18)]
            totalPassMark = nil
            minutes = 60
        }
    }

    var totalCount: Int { parts.reduce(0) { $0 + $1.count } }

    /// The navigation task (9 written questions) is part of the SBF See exam but not of this app.
    var excludesNavigationTask: Bool { format == .see }

    /// "7 basic + 23 inland questions · 45 min"
    var summary: String {
        let composition = parts.map { "\($0.count) \($0.type.partNoun)" }.joined(separator: " + ")
        return String(localized: "\(composition) · \(minutes) min",
                      comment: "Exam composition and time limit, e.g. 7 basic + 23 inland · 45 min")
    }

    func result(correct: [ExamType: Int]) -> ExamResult {
        ExamResult(rules: self, correct: correct)
    }
}

struct ExamResult: Equatable {
    let rules: ExamRules
    /// Correct answers per part.
    let correct: [ExamType: Int]

    func correct(in part: ExamPart) -> Int { correct[part.type] ?? 0 }

    /// A part without its own pass mark always counts as passed; the total decides.
    func passed(_ part: ExamPart) -> Bool { part.passMark.map { correct(in: part) >= $0 } ?? true }

    var totalCorrect: Int { rules.parts.reduce(0) { $0 + correct(in: $1) } }

    var totalPassed: Bool { rules.totalPassMark.map { totalCorrect >= $0 } ?? true }

    /// Every part with a pass mark and the total (if any) must be passed.
    var passed: Bool { totalPassed && rules.parts.allSatisfy(passed) }
}

/// The licences the learner is preparing for ("My licence"). Decides which exam simulations are offered.
struct LicenceGoal: Codable, Equatable {
    enum Inland: String, Codable, CaseIterable, Identifiable {
        case none, motor, sail, motorAndSail, sailAddOn

        var id: String { rawValue }

        var title: String {
            switch self {
            case .none:         return String(localized: "Not needed")
            case .motor:        return String(localized: "Motor")
            case .sail:         return String(localized: "Sail")
            case .motorAndSail: return String(localized: "Motor + sail")
            case .sailAddOn:    return String(localized: "Sail only – I already hold SBF Inland (motor)")
            }
        }

        var format: ExamFormat? {
            switch self {
            case .none:         return nil
            case .motor:        return .binnenMotor
            case .sail:         return .binnenSail
            case .motorAndSail: return .binnenMotorSail
            case .sailAddOn:    return .sailAddOn
            }
        }
    }

    var inland: Inland = .motor
    var sea: Bool = true

    /// Motor on inland waters and sea – what the app offered before the sailing questions.
    static let standard = LicenceGoal()

    var isValid: Bool { inland != .none || sea }

    var includesSailing: Bool { inland == .sail || inland == .motorAndSail || inland == .sailAddOn }

    var examFormats: [ExamFormat] {
        let formats = [inland.format].compactMap { $0 } + (sea ? [.see] : [])
        return formats.isEmpty ? [.binnenMotor, .see] : formats
    }

    /// "SBF Inland (motor + sail) · SBF Sea"
    var summary: String {
        var parts: [String] = []
        if inland != .none { parts.append(inland.format?.title ?? "") }
        if sea { parts.append(ExamFormat.see.title) }
        return parts.joined(separator: " · ")
    }
}
