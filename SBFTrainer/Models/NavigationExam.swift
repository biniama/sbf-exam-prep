import Foundation

/// Input fields of one navigation sub-question in the exam simulation.
enum NavigationField: Hashable {
    case degrees(label: String)
    case nauticalMiles
    case minutes
    case knots
    case clock
    case latitudeDegrees, latitudeMinutes, longitudeDegrees, longitudeMinutes
    case text

    /// Fields for a sub-question; free text when the answer cannot be checked automatically.
    static func fields(for step: NavigationStep) -> [NavigationField] {
        guard let check = step.check else { return [.text] }
        switch check.type {
        case "degrees":
            let count = check.values?.count ?? 1
            return (0..<count).map { i in .degrees(label: count > 1 ? "\(i + 1)" : "") }
        case "nm":        return [.nauticalMiles]
        case "minutes":   return [.minutes]
        case "knots":     return [.knots]
        case "clock":     return [.clock]
        case "position":  return [.latitudeDegrees, .latitudeMinutes, .longitudeDegrees, .longitudeMinutes]
        case "set_drift": return [.degrees(label: ""), .nauticalMiles]
        default:          return [.text]
        }
    }
}

/// Checks typed answers against the official results within the practice tolerances.
enum NavigationAnswerChecker {
    /// `nil` when the sub-question has to be graded by the learner (chart work, descriptions).
    static func isCorrect(_ step: NavigationStep, inputs: [String], tolerances t: NavigationTolerances) -> Bool? {
        guard let check = step.check else { return nil }
        switch check.type {
        case "degrees":
            let expected = (check.values ?? []).compactMap(\.number)
            guard inputs.count >= expected.count else { return false }
            return zip(expected, inputs).allSatisfy { e, input in
                guard let v = number(input) else { return false }
                return angleDifference(v, e) <= t.degrees
            }
        case "nm":      return within(inputs.first, check.values?.first?.number, t.nm)
        case "minutes": return within(inputs.first, check.values?.first?.number, t.minutes)
        case "knots":   return within(inputs.first, check.values?.first?.number, t.knots)
        case "clock":
            guard let expected = check.values?.first?.text.flatMap(clockMinutes),
                  let given = inputs.first.flatMap(clockMinutes) else { return false }
            return abs(given - expected) <= t.minutes + 1
        case "position":
            guard let lat = check.lat, let lon = check.lon, inputs.count >= 4,
                  let latDeg = number(inputs[0]), let latMin = number(inputs[1]),
                  let lonDeg = number(inputs[2]), let lonMin = number(inputs[3]) else { return false }
            let dLat = abs((latDeg * 60 + latMin) - (lat[0] * 60 + lat[1]))
            let dLon = abs((lonDeg * 60 + lonMin) - (lon[0] * 60 + lon[1]))
            return dLat <= t.arcMinutes && dLon <= t.arcMinutes
        case "set_drift":
            guard let direction = check.direction, let nm = check.nm, inputs.count >= 2,
                  let d = number(inputs[0]), let n = number(inputs[1]) else { return false }
            // Small displacements make the direction sensitive; allow a little more there.
            return angleDifference(d, direction) <= t.degrees * 3 && abs(n - nm) <= t.nm
        default:
            return nil
        }
    }

    static func number(_ s: String) -> Double? {
        let cleaned = s.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "°", with: "")
        return Double(cleaned)
    }

    /// "15:12", "15.12" or "1512" → minutes after midnight.
    static func clockMinutes(_ s: String) -> Double? {
        let digits = s.filter(\.isNumber)
        guard digits.count == 3 || digits.count == 4, let value = Int(digits) else { return nil }
        let h = value / 100, m = value % 100
        guard h < 24, m < 60 else { return nil }
        return Double(h * 60 + m)
    }

    static func angleDifference(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    private static func within(_ input: String?, _ expected: Double?, _ tolerance: Double) -> Bool {
        guard let expected, let v = input.flatMap(number) else { return false }
        return abs(v - expected) <= tolerance + 1e-9
    }
}

/// The navigation part of an exam simulation: one task, 9 sub-questions, pass with 7.
@MainActor
final class NavigationExamPart: ObservableObject {
    nonisolated static let questionCount = 9
    nonisolated static let passMark = 7

    let task: NavigationTask
    let tolerances: NavigationTolerances
    @Published var inputs: [Int: [String]] = [:]
    /// Learner's own grading for sub-questions that cannot be checked automatically.
    @Published var selfGrades: [Int: Bool] = [:]

    init(task: NavigationTask, tolerances: NavigationTolerances) {
        self.task = task
        self.tolerances = tolerances
        for step in task.steps {
            inputs[step.number] = Array(repeating: "", count: NavigationField.fields(for: step).count)
        }
    }

    func autoResult(_ step: NavigationStep) -> Bool? {
        NavigationAnswerChecker.isCorrect(step, inputs: inputs[step.number] ?? [], tolerances: tolerances)
    }

    func isCorrect(_ step: NavigationStep) -> Bool {
        autoResult(step) ?? (selfGrades[step.number] ?? false)
    }

    var correctCount: Int { task.steps.filter(isCorrect).count }

    var needsSelfGrading: [NavigationStep] { task.steps.filter { autoResult($0) == nil } }
}
