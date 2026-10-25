import SwiftUI

struct QuizView: View {
    @ObservedObject var vm: QuizViewModel
    @EnvironmentObject var progress: UserProgress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var confirmQuit = false

    var body: some View {
        Group {
            if vm.state == .finished {
                QuizResultView(vm: vm, onDismiss: { dismiss() })
            } else if vm.state == .navigation, let part = vm.navigationPart {
                VStack(spacing: 0) {
                    progressBar
                    NavigationExamView(part: part, onFinish: { vm.finish() })
                }
            } else if let q = vm.current {
                questionScreen(q)
            } else {
                ContentUnavailableView("No questions", systemImage: "tray",
                                       description: Text("There are no questions for this selection."))
            }
        }
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.state != .finished {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if vm.examMode && vm.currentIndex > 0 { confirmQuit = true } else { close() }
                    } label: {
                        Image(systemName: "xmark").font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(Text("Close quiz"))
                }
                ToolbarItem(placement: .principal) {
                    Group {
                        if vm.state == .navigation {
                            Text("Navigation task")
                        } else {
                            Text("\(vm.currentIndex + 1) / \(vm.questions.count)")
                        }
                    }
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.ink)
                        .accessibilityLabel(Text("Question \(vm.currentIndex + 1) of \(vm.questions.count)"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { progress.toggleBookmark(vm.current?.uniqueId ?? "") }
                    } label: {
                        Image(systemName: progress.isBookmarked(vm.current?.uniqueId ?? "") ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Color.gold)
                    }
                    .accessibilityLabel(progress.isBookmarked(vm.current?.uniqueId ?? "")
                                        ? Text("Remove from saved") : Text("Save question"))
                }
            }
        }
        .alert("End the exam?", isPresented: $confirmQuit) {
            Button("Finish and see result") { vm.finish() }
            Button("Quit without result", role: .destructive) { close() }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Unanswered questions count as wrong.")
        }
    }

    private func close() {
        SoundSignalPlayer.shared.stop()
        dismiss()
    }

    // MARK: - Question screen

    @ViewBuilder
    private func questionScreen(_ q: Question) -> some View {
        VStack(spacing: 0) {
            progressBar
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    Group {
                        if hSize == .regular && geo.size.width > 900 {
                            HStack(alignment: .top, spacing: 20) {
                                questionCard(q).frame(maxWidth: .infinity)
                                VStack(spacing: 14) { answerColumn(q) }.frame(maxWidth: .infinity)
                            }
                            .padding(24)
                            .readableWidth(1200)
                        } else {
                            VStack(spacing: 16) {
                                questionCard(q)
                                answerColumn(q)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                            .readableWidth()
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .background(Color.surfaceBG.ignoresSafeArea())
        .id(q.uniqueId)
    }

    @ViewBuilder
    private func answerColumn(_ q: Question) -> some View {
        VStack(spacing: 10) {
            ForEach(vm.shuffledOptions(for: q), id: \.key) { key, option in
                OptionButton(
                    key: key,
                    german: option.german,
                    english: option.english,
                    showEnglish: progress.showEnglish,
                    tint: vm.examMode ? (vm.selectedOption == key ? .gold : .clear) : vm.optionColor(key),
                    icon: vm.examMode ? (vm.selectedOption == key ? "circle.inset.filled" : nil) : vm.optionIcon(key),
                    stateDescription: stateDescription(for: key),
                    isEnabled: vm.state == .answering,
                    action: { vm.select(key) }
                )
            }
        }
        if vm.state == .revealed {
            if !vm.examMode, let explanation = q.localizedExplanation {
                Label {
                    Text(explanation).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Color.gold)
                }
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gold.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity)
            }
            nextButton
        }
    }

    private func stateDescription(for key: String) -> LocalizedStringKey? {
        guard vm.state == .revealed, let q = vm.current else { return nil }
        if vm.examMode { return vm.selectedOption == key ? "Selected" : nil }
        if vm.isCorrect(key, for: q) { return "Correct answer" }
        if vm.selectedOption == key { return "Your answer, wrong" }
        return nil
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            ProgressView(value: vm.progressFraction)
                .tint(Color.navyLight)
                .accessibilityHidden(true)
            if vm.examMode {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                    Text(vm.formattedTime)
                        .monospacedDigit()
                    Spacer()
                    if let rules = vm.examRules {
                        Text("Exam simulation · \(rules.format.title)")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(vm.timeRemaining > 300 ? Color.successGreen : Color.errorRed)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.cardBG)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text("Time remaining: \(vm.formattedTime)"))
            }
        }
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ExamTypeBadge(type: q.examType)
                CategoryBadge(text: q.localizedCategory)
                Spacer()
            }
            Text(q.germanText)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.locale, Locale(identifier: "de"))
                .accessibilityAddTraits(.isHeader)
            if progress.showEnglish && !q.englishText.isEmpty {
                Divider()
                Text(q.englishText)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            if q.hasMedia {
                QuestionImageView(question: q)
            }
        }
        .padding(18)
        .cardStyle()
    }

    private var nextButton: some View {
        Button(action: vm.next) {
            HStack {
                Text(vm.isLast ? "See results" : "Next question")
                    .font(.headline)
                Image(systemName: vm.isLast ? "flag.checkered" : "arrow.right")
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradient.navy)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .keyboardShortcut(.return, modifiers: [])
        .transition(.opacity)
    }
}

struct OptionButton: View {
    let key: String
    let german: String
    let english: String
    let showEnglish: Bool
    let tint: Color
    let icon: String?
    let stateDescription: LocalizedStringKey?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(key)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint == .clear ? Color.inkSecondary : tint)
                    .frame(width: 32, height: 32)
                    .background(tint == .clear ? Color.navyLight.opacity(0.12) : tint.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(german)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if showEnglish && !english.isEmpty {
                        Text(english)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(tint)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint == .clear ? Color.cardBG : tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(tint == .clear ? Color.hairline.opacity(0.5) : tint.opacity(0.6), lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .allowsHitTesting(isEnabled)
        .accessibilityLabel(Text("Answer \(key): \(german)"))
        .accessibilityValue(stateDescription.map { Text($0) } ?? Text(verbatim: ""))
    }
}

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}
