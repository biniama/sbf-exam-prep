import Foundation

/// The 15 official navigation tasks of the SBF See (ELWIS, chart D49), from navigation_tasks.json.
struct NavigationCatalog: Decodable {
    let source: String
    let sourceURL: URL
    let chart: String
    let chartExcerpts: [String]
    let tolerances: NavigationTolerances
    let glossary: [GlossaryEntry]
    let questionTypes: [QuestionType]
    let tasks: [NavigationTask]

    enum CodingKeys: String, CodingKey {
        case source, chart, tolerances, glossary, tasks
        case sourceURL = "source_url"
        case chartExcerpts = "chart_excerpts"
        case questionTypes = "question_types"
    }

    struct GlossaryEntry: Decodable, Identifiable, Hashable {
        let abbr: String
        let de: String
        let en: String
        let explanationDE: String
        let explanationEN: String
        var id: String { abbr }

        enum CodingKeys: String, CodingKey {
            case abbr, de, en
            case explanationDE = "explanation_de"
            case explanationEN = "explanation_en"
        }
    }

    struct QuestionType: Decodable, Identifiable, Hashable {
        let number: Int
        let de: String
        let en: String
        var id: Int { number }
    }
}

/// Practice tolerances for typed answers (ELWIS publishes no official tolerances).
struct NavigationTolerances: Decodable, Equatable {
    let degrees: Double
    let nm: Double
    let minutes: Double
    let knots: Double
    let arcMinutes: Double

    enum CodingKeys: String, CodingKey {
        case degrees, nm, minutes, knots
        case arcMinutes = "arc_minutes"
    }
}

struct NavigationTask: Decodable, Identifiable, Hashable {
    let number: Int
    let introDE: String
    let introEN: String?
    let notesDE: String
    let notesEN: String?
    let values: TaskValues
    let steps: [NavigationStep]

    var id: Int { number }

    struct TaskValues: Decodable, Hashable {
        let mw: Double?
        let speedKn: Double?

        enum CodingKeys: String, CodingKey {
            case mw
            case speedKn = "speed_kn"
        }
    }

    enum CodingKeys: String, CodingKey {
        case number, values, steps
        case introDE = "intro_de"
        case introEN = "intro_en"
        case notesDE = "notes_de"
        case notesEN = "notes_en"
    }

    static func == (lhs: NavigationTask, rhs: NavigationTask) -> Bool { lhs.number == rhs.number }
    func hash(into hasher: inout Hasher) { hasher.combine(number) }
}

struct NavigationStep: Decodable, Identifiable, Hashable {
    let number: Int
    let questionDE: String
    let questionEN: String?
    let answerDE: String
    let answerEN: String?
    let kind: String
    let solution: [SolutionLine]
    let check: AnswerCheck?
    /// Light character code such as "Oc(3).Y.12s" (light descriptions only).
    let code: String?

    var id: Int { number }

    struct SolutionLine: Decodable, Hashable {
        let de: String
        let en: String
        var localized: String { AppLanguage.isGerman ? de : en }
    }

    enum CodingKeys: String, CodingKey {
        case number, kind, solution, check, code
        case questionDE = "question_de"
        case questionEN = "question_en"
        case answerDE = "answer_de"
        case answerEN = "answer_en"
    }

    /// Sub-questions that are answered by drawing on the chart.
    var isPlot: Bool { kind == "plot" }
}

/// How a typed answer is checked; positions as [degrees, minutes].
struct AnswerCheck: Decodable, Hashable {
    let type: String
    let values: [AnswerValue]?
    let lat: [Double]?
    let lon: [Double]?
    let direction: Double?
    let nm: Double?

    /// Numbers (degrees, miles, minutes, knots) or clock times ("15:12").
    enum AnswerValue: Decodable, Hashable {
        case number(Double)
        case text(String)

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let d = try? c.decode(Double.self) { self = .number(d) } else { self = .text(try c.decode(String.self)) }
        }

        var number: Double? { if case .number(let d) = self { return d } else { return nil } }
        var text: String? { if case .text(let s) = self { return s } else { return nil } }
    }
}

@MainActor
final class NavigationStore: ObservableObject {
    static let shared = NavigationStore()

    private(set) var catalog: NavigationCatalog?
    private(set) var loadError: String?

    var tasks: [NavigationTask] { catalog?.tasks ?? [] }

    private init() {
        do {
            guard let url = Bundle.main.url(forResource: "navigation_tasks", withExtension: "json") else {
                loadError = "navigation_tasks.json is missing from the app bundle"
                return
            }
            catalog = try JSONDecoder().decode(NavigationCatalog.self, from: Data(contentsOf: url))
        } catch {
            loadError = "Could not load navigation tasks: \(error)"
            assertionFailure(loadError!)
        }
    }

    func task(_ number: Int) -> NavigationTask? { tasks.first { $0.number == number } }
}
