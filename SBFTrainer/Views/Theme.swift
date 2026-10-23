import SwiftUI
import UIKit

// MARK: - Colours

extension Color {
    /// Brand colours — used for filled surfaces (headers, primary buttons, badges).
    static let navy        = Color(red: 0.04, green: 0.14, blue: 0.26)
    static let navyMid     = Color(red: 0.10, green: 0.23, blue: 0.37)
    static let navyLight   = Color(red: 0.16, green: 0.35, blue: 0.54)
    static let gold        = Color(red: 0.79, green: 0.66, blue: 0.30)
    static let goldLight   = Color(red: 0.95, green: 0.85, blue: 0.55)
    static let oceanTeal   = Color(red: 0.10, green: 0.60, blue: 0.66)

    /// Text colours — adapt to light and dark mode.
    static let ink = adaptive(light: (0.04, 0.14, 0.26), dark: (0.93, 0.95, 0.98))
    static let inkSecondary = adaptive(light: (0.10, 0.23, 0.37), dark: (0.70, 0.78, 0.88))

    /// Feedback colours, slightly brighter in dark mode for contrast.
    static let successGreen = adaptive(light: (0.18, 0.49, 0.20), dark: (0.36, 0.78, 0.42))
    static let errorRed     = adaptive(light: (0.77, 0.16, 0.16), dark: (0.96, 0.40, 0.40))

    /// Surfaces.
    static let cardBG    = Color(.secondarySystemGroupedBackground)
    static let surfaceBG = Color(.systemGroupedBackground)
    static let hairline  = Color(.separator)

    private static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}

// Use these instead of Color.xxx.gradient — avoids UIColor out-of-range warnings
// caused by SwiftUI's .gradient shorthand using extended Oklab color space
enum AppGradient {
    static let navy = LinearGradient(colors: [.navyMid, .navy], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gold = LinearGradient(colors: [.goldLight, .gold], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let errorRed = LinearGradient(colors: [Color(red: 0.87, green: 0.30, blue: 0.30), Color(red: 0.77, green: 0.16, blue: 0.16)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
    static let successGreen = LinearGradient(colors: [Color(red: 0.28, green: 0.62, blue: 0.30), Color(red: 0.18, green: 0.49, blue: 0.20)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gray = LinearGradient(colors: [Color(white: 0.62), Color(white: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct NavyGradient: View {
    var body: some View {
        LinearGradient(colors: [.navy, .navyMid], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

// MARK: - Layout helpers

enum Layout {
    /// Comfortable reading width for question content on iPad / landscape.
    static let readableWidth: CGFloat = 760
    /// Width for dashboards (home, setup) on large screens.
    static let wideWidth: CGFloat = 1000
}

extension View {
    /// Centres the content and limits its width on wide screens (iPad, landscape).
    func readableWidth(_ width: CGFloat = Layout.readableWidth) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }

    func goldBadge() -> some View { modifier(GoldBadge()) }

    func cardStyle() -> some View {
        self
            .background(Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

struct GoldBadge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppGradient.gold)
            .clipShape(Capsule())
    }
}

// MARK: - Badges

struct ExamTypeBadge: View {
    let type: ExamType
    var body: some View {
        Text(type.title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor)
            .clipShape(Capsule())
    }
    var badgeColor: Color {
        switch type {
        case .all:    return .navyLight
        case .shared: return Color(red: 0.62, green: 0.50, blue: 0.16)
        case .binnen: return Color(red: 0.05, green: 0.47, blue: 0.53)
        case .see:    return .navyLight
        case .segeln: return Color(red: 0.66, green: 0.27, blue: 0.20)
        }
    }
}

struct CategoryBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.inkSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.navyLight.opacity(0.14))
            .clipShape(Capsule())
    }
}

// MARK: - Stat card

struct StatCard: View {
    let value: String
    let label: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section header used across screens

struct SectionHeader: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage).foregroundStyle(Color.gold).accessibilityHidden(true)
            }
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}
