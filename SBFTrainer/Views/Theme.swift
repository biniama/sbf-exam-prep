import SwiftUI
import UIKit

extension Color {
    static let navy        = Color(red: 0.04, green: 0.14, blue: 0.26)
    static let navyMid     = Color(red: 0.10, green: 0.23, blue: 0.37)
    static let navyLight   = Color(red: 0.16, green: 0.35, blue: 0.54)
    static let gold        = Color(red: 0.79, green: 0.66, blue: 0.30)
    static let goldLight   = Color(red: 0.95, green: 0.85, blue: 0.55)
    static let oceanTeal   = Color(red: 0.10, green: 0.60, blue: 0.66)
    static let successGreen = Color(red: 0.18, green: 0.49, blue: 0.20)
    static let errorRed    = Color(red: 0.77, green: 0.16, blue: 0.16)
    static let cardBG      = Color(.secondarySystemBackground)
    static let surfaceBG   = Color(.systemGroupedBackground)
}

struct NavyGradient: View {
    var body: some View {
        LinearGradient(
            colors: [.navy, .navyMid],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()
    }
}

struct GoldBadge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.gold.gradient)
            .clipShape(Capsule())
    }
}

extension View {
    func goldBadge() -> some View { modifier(GoldBadge()) }

    func cardStyle() -> some View {
        self
            .background(Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

struct ExamTypeBadge: View {
    let type: ExamType
    var body: some View {
        Text(type.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor.gradient)
            .clipShape(Capsule())
    }
    var badgeColor: Color {
        switch type {
        case .all:    return .navyLight
        case .shared: return .gold
        case .binnen: return .oceanTeal
        case .see:    return .navy
        }
    }
}

struct CategoryBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.navyMid)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.navyLight.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct QuestionImageView: View {
    let question: Question

    var body: some View {
        Group {
            if let url = question.imageURL,
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 220)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.navyLight.opacity(0.2), lineWidth: 1))
            } else {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.navyLight.opacity(0.35))
                        Text("Image question")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(20)
                .background(Color.navyLight.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.navy)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}
