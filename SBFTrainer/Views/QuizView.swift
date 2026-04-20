import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: QuizViewModel
    @EnvironmentObject var progress: UserProgress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if vm.state == .finished {
                QuizResultView(vm: vm, onDismiss: { dismiss() })
            } else if let q = vm.current {
                questionScreen(q)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.navyMid)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("\(vm.currentIndex + 1) / \(vm.questions.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.navy)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { progress.toggleBookmark(vm.current?.uniqueId ?? "") }
                } label: {
                    Image(systemName: progress.isBookmarked(vm.current?.uniqueId ?? "") ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(Color.gold)
                }
            }
        }
    }

    @ViewBuilder
    private func questionScreen(_ q: Question) -> some View {
        ZStack {
            Color.surfaceBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Question card
                        questionCard(q)

                        // Options
                        optionsGrid(q)

                        // Next / Continue
                        if vm.state == .revealed {
                            nextButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.navyLight.opacity(0.15)
                    Color.navy
                        .frame(width: geo.size.width * vm.progressFraction)
                        .animation(.spring(response: 0.5), value: vm.progressFraction)
                }
            }
            .frame(height: 4)

            if vm.examMode {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Color.errorRed.opacity(0.15)
                        (vm.timeRemaining > 300 ? Color.successGreen : Color.errorRed)
                            .frame(width: geo.size.width * vm.timeFraction)
                            .animation(.linear(duration: 1), value: vm.timeFraction)
                    }
                }
                .frame(height: 3)
                .overlay(alignment: .trailing) {
                    Text(vm.formattedTime)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(vm.timeRemaining > 300 ? Color.successGreen : Color.errorRed)
                        .padding(.trailing, 8)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Badges
            HStack {
                ExamTypeBadge(type: q.examType)
                CategoryBadge(text: q.category)
                Spacer()
            }

            // German question
            Text(q.germanText)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.navy)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut, value: vm.currentIndex)

            // English translation (toggleable)
            if progress.showEnglish && !q.englishText.isEmpty {
                Divider()
                Text(q.englishText)
                    .font(.subheadline)
                    .foregroundStyle(Color.navyMid.opacity(0.8))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Question image
            if q.hasImage {
                QuestionImageView(question: q)
            }
        }
        .padding(18)
        .cardStyle()
    }

    private func optionsGrid(_ q: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(vm.shuffledOptions(for: q), id: \.key) { key, option in
                OptionButton(
                    key: key,
                    german: option.german,
                    english: option.english,
                    showEnglish: progress.showEnglish,
                    bgColor: vm.optionColor(key),
                    icon: vm.optionIcon(key),
                    isEnabled: vm.state == .answering,
                    action: { vm.select(key) }
                )
            }
        }
    }

    private var nextButton: some View {
        Button(action: vm.next) {
            HStack {
                Text(vm.isLast ? "See Results" : "Next Question")
                    .font(.headline)
                Image(systemName: vm.isLast ? "flag.checkered" : "arrow.right")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradient.navy)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.navy.opacity(0.25), radius: 6, y: 3)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct OptionButton: View {
    let key: String
    let german: String
    let english: String
    let showEnglish: Bool
    let bgColor: Color
    let icon: String?
    let isEnabled: Bool
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Key circle
                Text(key)
                    .font(.subheadline.bold())
                    .foregroundStyle(keyFG)
                    .frame(width: 32, height: 32)
                    .background(keyBG)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(german)
                        .font(.subheadline)
                        .foregroundStyle(Color.navy)
                        .fixedSize(horizontal: false, vertical: true)
                    if showEnglish && !english.isEmpty {
                        Text(english)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(bgColor == Color.successGreen ? Color.successGreen : Color.errorRed)
                }
            }
            .padding(14)
            .background(bgColor == .clear ? Color.cardBG : bgColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(bgColor == .clear ? Color.gray.opacity(0.12) : bgColor.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled)
        .animation(.spring(response: 0.3), value: bgColor)
    }

    var keyFG: Color { bgColor == .clear ? Color.navyMid : bgColor == Color.successGreen ? Color.successGreen : Color.errorRed }
    var keyBG: Color { bgColor == .clear ? Color.navyLight.opacity(0.12) : bgColor.opacity(0.12) }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
