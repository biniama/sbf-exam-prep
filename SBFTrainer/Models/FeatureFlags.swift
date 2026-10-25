import Foundation

/// Features that are built but not yet released. All flags are off by default.
///
/// Turn them on under Settings → Experimental features. The section is always visible in debug
/// builds; in release builds (TestFlight) it appears after tapping the version number seven times.
/// For UI checks they can also be set as launch arguments, e.g. `-ff.navigationTasks YES`.
enum FeatureFlag: String, CaseIterable, Identifiable {
    case navigationTasks
    case navigationExam
    case navigationDrills
    case navigationDiagrams
    case navigationVideos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .navigationTasks:    return String(localized: "Navigation tasks")
        case .navigationExam:     return String(localized: "Navigation part in the Sea exam")
        case .navigationDrills:   return String(localized: "Navigation drills")
        case .navigationDiagrams: return String(localized: "Solution diagrams")
        case .navigationVideos:   return String(localized: "Technique videos")
        }
    }

    var summary: String {
        switch self {
        case .navigationTasks:    return String(localized: "The 15 official chart tasks with worked solutions.")
        case .navigationExam:     return String(localized: "Adds 9 navigation questions to the SBF Sea exam simulation.")
        case .navigationDrills:   return String(localized: "Unlimited course, time and light character practice.")
        case .navigationDiagrams: return String(localized: "Step-by-step plot of each solution with narration.")
        case .navigationVideos:   return String(localized: "Links to videos about working on the chart.")
        }
    }

    fileprivate var key: String { "ff." + rawValue }
}

@MainActor
final class FeatureFlags: ObservableObject {
    static let shared = FeatureFlags()

    @Published private(set) var enabled: Set<FeatureFlag> = []
    /// Shows the experimental settings in release builds.
    @Published private(set) var unlocked = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = Set(FeatureFlag.allCases.filter { defaults.bool(forKey: $0.key) })
        #if DEBUG
        unlocked = true
        #else
        unlocked = defaults.bool(forKey: "ff.unlocked")
        #endif
    }

    func isOn(_ flag: FeatureFlag) -> Bool { enabled.contains(flag) }

    func set(_ flag: FeatureFlag, _ on: Bool) {
        if on { enabled.insert(flag) } else { enabled.remove(flag) }
        defaults.set(on, forKey: flag.key)
    }

    func unlock() {
        unlocked = true
        defaults.set(true, forKey: "ff.unlocked")
    }
}
