import Foundation
import StoreKit

/// Features that are built but not yet released. All flags are off by default.
///
/// Turn them on under Settings → Feature flags. The button is always visible in debug and TestFlight
/// builds; in App Store builds it appears after tapping the version number seven times.
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
    /// Shows the feature-flag settings (debug and TestFlight builds, or after seven taps on the version).
    @Published private(set) var unlocked = false

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = Set(FeatureFlag.allCases.filter { defaults.bool(forKey: $0.key) })
        #if DEBUG
        unlocked = true
        #else
        unlocked = defaults.bool(forKey: "ff.unlocked")
        if !unlocked {
            Task { if await Self.isTestFlight() { unlocked = true } }
        }
        #endif
    }

    /// TestFlight builds run in the App Store sandbox environment.
    private static func isTestFlight() async -> Bool {
        guard let result = try? await AppTransaction.shared else { return false }
        switch result {
        case .verified(let transaction), .unverified(let transaction, _):
            return transaction.environment == .sandbox
        }
    }

    var enabledCount: Int { enabled.count }

    func setAll(_ on: Bool) {
        FeatureFlag.allCases.forEach { set($0, on) }
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
