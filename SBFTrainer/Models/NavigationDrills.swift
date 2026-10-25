import Foundation

// MARK: - Light characters

/// A light character such as "Oc(3).Y.12s", turned into on/off phases for the animation.
struct LightCharacter: Equatable {
    let code: String
    let colour: Colour
    /// Alternating phases starting with light on; durations in seconds, one full period.
    let phases: [(on: Bool, seconds: Double)]

    enum Colour: String { case white = "W", red = "R", green = "G", yellow = "Y" }

    static func == (lhs: LightCharacter, rhs: LightCharacter) -> Bool { lhs.code == rhs.code }

    var period: Double { phases.reduce(0) { $0 + $1.seconds } }

    /// Short notation for display: "Oc(3) Y 12s".
    var notation: String { code.replacingOccurrences(of: ".", with: " ") }

    /// Parses codes like "Fl.W.5s", "LFl(2).R.10s", "Q(3).W.10s", "IQ.R.13s", "Mo(A).W.8s", "F.G".
    init?(_ code: String) {
        let parts = code.split(separator: ".").map(String.init)
        guard let head = parts.first, let match = head.firstMatch(of: /^([A-Za-z]+)(?:\((\w+)\))?$/) else { return nil }
        let kind = String(match.1)
        let group = match.2.map(String.init)
        let colour = Colour(rawValue: parts.count > 1 ? String(parts[1].prefix(1)) : "W") ?? .white
        let period = parts.count > 2 ? Double(parts[2].dropLast()) : nil
        let count = group.flatMap(Int.init) ?? 1

        var phases: [(on: Bool, seconds: Double)] = []
        func flashes(_ n: Int, on: Double, off: Double, total: Double?) {
            for i in 0..<n {
                phases.append((true, on))
                if i < n - 1 { phases.append((false, off)) }
            }
            let used = Double(n) * on + Double(n - 1) * off
            phases.append((false, max(off, (total ?? used + off * 2) - used)))
        }
        switch kind {
        case "F":
            phases = [(true, 4)]
        case "Fl":
            flashes(count, on: 0.6, off: 1.0, total: period ?? 5)
        case "LFl":
            flashes(count, on: 2.0, off: 1.5, total: period ?? 10)
        case "Iso":
            let p = period ?? 4
            phases = [(true, p / 2), (false, p / 2)]
        case "Oc":
            // Light longer than dark: short eclipses.
            let p = period ?? 4
            if count == 1 {
                phases = [(true, p - 1), (false, 1)]
            } else {
                let lit = p - Double(count) * 1.0 - Double(count - 1) * 1.0
                phases = [(true, lit)]
                for i in 0..<count {
                    phases.append((false, 1))
                    if i < count - 1 { phases.append((true, 1)) }
                }
            }
        case "Q":
            if let group, let n = Int(group) { flashes(n, on: 0.3, off: 0.7, total: period) } else { phases = [(true, 0.3), (false, 0.7)] }
        case "VQ":
            if let group, let n = Int(group) { flashes(n, on: 0.2, off: 0.3, total: period) } else { phases = [(true, 0.2), (false, 0.3)] }
        case "IQ":
            let p = period ?? 13
            flashes(9, on: 0.3, off: 0.7, total: p)
        case "Mo":
            phases = LightCharacter.morse(group ?? "A", total: period ?? 8)
        default:
            return nil
        }
        self.code = code
        self.colour = colour
        self.phases = phases
    }

    private static let morseTable: [Character: String] = ["A": ".-", "U": "..-", "D": "-..", "N": "-.", "K": "-.-"]

    private static func morse(_ letters: String, total: Double) -> [(on: Bool, seconds: Double)] {
        var phases: [(on: Bool, seconds: Double)] = []
        let symbols = Array(letters.compactMap { morseTable[$0] }.joined())
        for (i, s) in symbols.enumerated() {
            phases.append((true, s == "." ? 0.5 : 1.5))
            if i < symbols.count - 1 { phases.append((false, 0.5)) }
        }
        let used = phases.reduce(0) { $0 + $1.seconds }
        phases.append((false, max(1, total - used)))
        return phases
    }

    /// Whether the light is on `t` seconds into the cycle.
    func isOn(at t: Double) -> Bool {
        var remaining = t.truncatingRemainder(dividingBy: max(period, 0.1))
        for phase in phases {
            if remaining < phase.seconds { return phase.on }
            remaining -= phase.seconds
        }
        return phases.last?.on ?? false
    }

    /// German and English description of the rhythm.
    var description: String {
        let kind = code.split(separator: ".").first.map(String.init) ?? code
        let base: String
        switch kind.prefix(while: { $0.isLetter }) {
        case "F":   base = String(localized: "Fixed light: shines continuously")
        case "Fl":  base = String(localized: "Flashing: short flashes, longer darkness")
        case "LFl": base = String(localized: "Long-flashing: flashes of at least 2 seconds")
        case "Iso": base = String(localized: "Isophase: light and dark of equal length")
        case "Oc":  base = String(localized: "Occulting: light longer than dark")
        case "Q":   base = String(localized: "Quick: 50–60 flashes per minute")
        case "VQ":  base = String(localized: "Very quick: 100–120 flashes per minute")
        case "IQ":  base = String(localized: "Interrupted quick: quick flashes, then a pause")
        case "Mo":  base = String(localized: "Morse code letter")
        default:    base = notation
        }
        return base
    }

    /// Characters used by the light drill (including all cardinal marks).
    static let drillCodes = [
        "F.R", "Fl.W.5s", "Fl(2).R.6s", "LFl.W.10s", "Iso.W.8s", "Iso.W.4s", "Oc.G.4s", "Oc(2).G.9s",
        "Oc(3).Y.12s", "Q.W", "Q(3).W.10s", "Q(9).W.15s", "VQ.W", "IQ.R.13s", "Mo(A).W.8s",
    ]
}

// MARK: - Drills

/// One randomly generated practice exercise with its worked solution.
struct NavigationDrill: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case course, timeSpeedDistance, arrival, light
        var id: String { rawValue }

        var title: String {
            switch self {
            case .course:            return String(localized: "Course conversion")
            case .timeSpeedDistance: return String(localized: "Time, distance, speed")
            case .arrival:           return String(localized: "Arrival time")
            case .light:             return String(localized: "Light characters")
            }
        }

        var icon: String {
            switch self {
            case .course:            return "safari"
            case .timeSpeedDistance: return "speedometer"
            case .arrival:           return "clock"
            case .light:             return "light.beacon.max"
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let prompt: String
    /// Unit shown next to the answer field (empty for multiple choice).
    let unit: String
    let solution: [String]
    /// Numeric answer and tolerance, or clock time in minutes.
    let answer: Double
    let tolerance: Double
    let isClock: Bool
    /// Light drill: the character shown and the choices.
    let light: LightCharacter?
    let choices: [LightCharacter]

    func check(_ input: String) -> Bool {
        if isClock {
            guard let given = NavigationAnswerChecker.clockMinutes(input) else { return false }
            return abs(given - answer) <= tolerance
        }
        if kind == .course {
            guard let v = NavigationAnswerChecker.number(input) else { return false }
            return NavigationAnswerChecker.angleDifference(v, answer) <= tolerance
        }
        guard let v = NavigationAnswerChecker.number(input) else { return false }
        return abs(v - answer) <= tolerance + 1e-9
    }

    func check(choice: LightCharacter) -> Bool { choice == light }

    static func make(_ kind: Kind) -> NavigationDrill {
        switch kind {
        case .course:            return course()
        case .timeSpeedDistance: return timeSpeedDistance()
        case .arrival:           return arrival()
        case .light:             return lightDrill()
        }
    }

    private static func deg(_ v: Int) -> String { String(format: "%03d°", ((v % 360) + 360) % 360) }
    private static func signed(_ v: Int) -> String { v == 0 ? "0°" : String(format: "%+d°", v).replacingOccurrences(of: "-", with: "−") }
    private static func dec(_ v: Double) -> String { v.formatted(.number.precision(.fractionLength(0...1))) }

    private static func course() -> NavigationDrill {
        let mw = Int.random(in: -3...3), abl = Int.random(in: -8...8)
        switch Int.random(in: 0..<3) {
        case 0:
            let rwk = Int.random(in: 0..<360)
            let mgk = ((rwk - mw - abl) % 360 + 360) % 360
            return NavigationDrill(
                kind: .course,
                prompt: String(localized: "rwK = \(deg(rwk)), Mw = \(signed(mw)), Abl = \(signed(abl)). What is the MgK?"),
                unit: "°",
                solution: [String(localized: "From true to compass: subtract variation and deviation."),
                           "MgK = rwK − Mw − Abl = \(deg(rwk)) − (\(signed(mw))) − (\(signed(abl))) = \(deg(mgk))"],
                answer: Double(mgk), tolerance: 0, isClock: false, light: nil, choices: [])
        case 1:
            let mgk = Int.random(in: 0..<360)
            let rwk = ((mgk + abl + mw) % 360 + 360) % 360
            return NavigationDrill(
                kind: .course,
                prompt: String(localized: "MgK = \(deg(mgk)), Abl = \(signed(abl)), Mw = \(signed(mw)). What is the rwK?"),
                unit: "°",
                solution: [String(localized: "From compass to true: add deviation and variation."),
                           "rwK = MgK + Abl + Mw = \(deg(mgk)) + (\(signed(abl))) + (\(signed(mw))) = \(deg(rwk))"],
                answer: Double(rwk), tolerance: 0, isClock: false, light: nil, choices: [])
        default:
            let mgp = Int.random(in: 0..<360)
            let ablHand = Bool.random() ? 0 : abl
            let rwp = ((mgp + ablHand + mw) % 360 + 360) % 360
            return NavigationDrill(
                kind: .course,
                prompt: String(localized: "MgP = \(deg(mgp)), Abl = \(signed(ablHand)), Mw = \(signed(mw)). What is the rwP?"),
                unit: "°",
                solution: [String(localized: "Bearings are converted like courses: add deviation and variation."),
                           "rwP = MgP + Abl + Mw = \(deg(mgp)) + (\(signed(ablHand))) + (\(signed(mw))) = \(deg(rwp))"],
                answer: Double(rwp), tolerance: 0, isClock: false, light: nil, choices: [])
        }
    }

    private static func timeSpeedDistance() -> NavigationDrill {
        let speed = Double(Int.random(in: 8...24)) / 2          // 4–12 kn in half knots
        let minutes = Int.random(in: 10...120)
        let distance = (speed * Double(minutes) / 60 * 10).rounded() / 10
        switch Int.random(in: 0..<3) {
        case 0:
            let t = distance / speed * 60
            return NavigationDrill(
                kind: .timeSpeedDistance,
                prompt: String(localized: "Distance \(dec(distance)) nm at \(dec(speed)) kn. How many minutes?"),
                unit: "min",
                solution: [String(localized: "Time = distance ÷ speed × 60"),
                           "t = \(dec(distance)) ÷ \(dec(speed)) × 60 = \(dec((t * 10).rounded() / 10)) min"],
                answer: t, tolerance: 1, isClock: false, light: nil, choices: [])
        case 1:
            let v = distance / Double(minutes) * 60
            return NavigationDrill(
                kind: .timeSpeedDistance,
                prompt: String(localized: "\(dec(distance)) nm in \(minutes) min. What is the speed?"),
                unit: "kn",
                solution: [String(localized: "Speed = distance ÷ time (in hours)"),
                           "v = \(dec(distance)) ÷ \(minutes) × 60 = \(dec((v * 10).rounded() / 10)) kn"],
                answer: v, tolerance: 0.15, isClock: false, light: nil, choices: [])
        default:
            return NavigationDrill(
                kind: .timeSpeedDistance,
                prompt: String(localized: "\(minutes) min at \(dec(speed)) kn. What distance?"),
                unit: String(localized: "nm"),
                solution: [String(localized: "Distance = speed × time (in hours)"),
                           "d = \(dec(speed)) × \(minutes) ÷ 60 = \(dec(distance)) nm"],
                answer: distance, tolerance: 0.1, isClock: false, light: nil, choices: [])
        }
    }

    private static func arrival() -> NavigationDrill {
        let start = Int.random(in: 72...204) * 5            // 06:00–17:00 in 5-minute steps
        let speed = Double(Int.random(in: 8...24)) / 2
        let distance = Double(Int.random(in: 15...150)) / 10
        let minutes = (distance / speed * 60).rounded()
        let arrival = start + Int(minutes)
        func clock(_ m: Int) -> String { String(format: "%02d:%02d", (m / 60) % 24, m % 60) }
        return NavigationDrill(
            kind: .arrival,
            prompt: String(localized: "Departure \(clock(start)), distance \(dec(distance)) nm, speed \(dec(speed)) kn. When do you arrive?"),
            unit: "",
            solution: [String(localized: "Time = distance ÷ speed × 60, then add it to the departure time."),
                       "t = \(dec(distance)) ÷ \(dec(speed)) × 60 ≈ \(Int(minutes)) min",
                       "\(clock(start)) + \(Int(minutes)) min = \(clock(arrival))"],
            answer: Double(arrival), tolerance: 1, isClock: true, light: nil, choices: [])
    }

    private static func lightDrill() -> NavigationDrill {
        let all = LightCharacter.drillCodes.compactMap(LightCharacter.init)
        let correct = all.randomElement()!
        // Wrong options get the same colour, so the rhythm has to be read, not the colour.
        let rhythm = { (code: String) in code.split(separator: ".").first.map(String.init) ?? code }
        var seen: Set<String> = [rhythm(correct.code)]
        var others: [LightCharacter] = []
        for code in LightCharacter.drillCodes.shuffled() where others.count < 3 && !seen.contains(rhythm(code)) {
            var parts = code.split(separator: ".").map(String.init)
            if parts.count > 1 { parts[1] = correct.colour.rawValue }
            if let light = LightCharacter(parts.joined(separator: ".")) {
                others.append(light)
                seen.insert(rhythm(code))
            }
        }
        return NavigationDrill(
            kind: .light,
            prompt: String(localized: "Watch the light. Which character is it?"),
            unit: "",
            solution: ["\(correct.notation): \(correct.description)"],
            answer: 0, tolerance: 0, isClock: false, light: correct,
            choices: ([correct] + others).shuffled())
    }
}
