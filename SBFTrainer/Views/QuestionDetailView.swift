import SwiftUI

struct QuestionDetailView: View {
    let questions: [Question]
    @State private var currentIndex: Int
    @EnvironmentObject var progress: UserProgress
    @State private var revealAnswer = false
    @State private var picked: String? = nil

    /// Single question (results, review lists).
    init(question: Question) {
        self.questions = [question]
        self._currentIndex = State(initialValue: 0)
    }

    /// Browse a list starting at ``startIndex``.
    init(questions: [Question], startIndex: Int) {
        self.questions = questions
        self._currentIndex = State(initialValue: min(max(0, startIndex), max(0, questions.count - 1)))
    }

    var question: Question { questions[currentIndex] }
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex == questions.count - 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                questionText
                if question.hasMedia {
                    QuestionImageView(question: question)
                }
                Text("Tap an answer to check yourself")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                ForEach(question.displayOptions, id: \.key) { item in
                    optionRow(key: item.key, option: item.value, isCorrect: item.isCorrect)
                }
                if revealAnswer {
                    ExplanationCard(question: question)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button {
                        withAnimation(.spring(response: 0.4)) { revealAnswer = true }
                    } label: {
                        Label("Show correct answer", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppGradient.navy)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                if questions.count > 1 && !isLast {
                    Button(action: advance) {
                        Label("Next question", systemImage: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.navyLight.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.surfaceBG)
        .navigationTitle(questions.count > 1 ? Text("\(currentIndex + 1) of \(questions.count)")
                                              : Text("Question \(question.questionNumber)"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if questions.count > 1 {
                    Button {
                        guard !isFirst else { return }
                        withAnimation { currentIndex -= 1 }
                    } label: { Image(systemName: "chevron.left") }
                    .disabled(isFirst)
                    .accessibilityLabel(Text("Previous question"))
                    .keyboardShortcut(.leftArrow, modifiers: [])

                    Button(action: advance) { Image(systemName: "chevron.right") }
                        .disabled(isLast)
                        .accessibilityLabel(Text("Next question"))
                        .keyboardShortcut(.rightArrow, modifiers: [])
                }
                Button {
                    withAnimation { progress.toggleBookmark(question.uniqueId) }
                } label: {
                    Image(systemName: progress.isBookmarked(question.uniqueId) ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(progress.isBookmarked(question.uniqueId) ? Color.gold : Color.inkSecondary)
                }
                .accessibilityLabel(progress.isBookmarked(question.uniqueId) ? Text("Remove from saved") : Text("Save question"))
            }
        }
        .onChange(of: currentIndex) {
            revealAnswer = false
            picked = nil
            SoundSignalPlayer.shared.stop()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                ExamTypeBadge(type: question.examType)
                CategoryBadge(text: question.localizedCategory)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("No. \(question.questionNumber)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.inkSecondary)
                if let box = progress.box(for: question.uniqueId) {
                    Text("Review box \(box) of 5")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var questionText: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.germanText)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.locale, Locale(identifier: "de"))
                .accessibilityAddTraits(.isHeader)
            if progress.showEnglish && !question.englishText.isEmpty {
                Text(question.englishText)
                    .font(.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.navyLight.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func advance() {
        guard !isLast else { return }
        withAnimation { currentIndex += 1 }
    }

    private func optionRow(key: String, option: QuestionOption, isCorrect: Bool) -> some View {
        let showState = revealAnswer || picked != nil
        let highlightCorrect = showState && isCorrect
        let highlightWrong = picked == key && !isCorrect
        let tint: Color = highlightCorrect ? .successGreen : highlightWrong ? .errorRed : .clear

        return Button {
            withAnimation(.spring(response: 0.35)) {
                picked = key
                revealAnswer = true
            }
        } label: {
            HStack(spacing: 12) {
                Text(key)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint == .clear ? Color.inkSecondary : tint)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tint == .clear ? Color.navyLight.opacity(0.12) : tint.opacity(0.15)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.german)
                        .font(.subheadline)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if progress.showEnglish && !option.english.isEmpty {
                        Text(option.english)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if highlightCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successGreen)
                } else if highlightWrong {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.errorRed)
                }
            }
            .padding(12)
            .background(tint == .clear ? Color.cardBG : tint.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(tint == .clear ? Color.hairline.opacity(0.5) : tint.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!revealAnswer)
        .accessibilityLabel(Text("Answer \(key): \(option.german)"))
        .accessibilityValue(highlightCorrect ? Text("Correct answer") : highlightWrong ? Text("Wrong") : Text(verbatim: ""))
    }
}

/// Shows the correct answer and, when available, why it is correct.
struct ExplanationCard: View {
    let question: Question
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Correct answer", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.successGreen)
            Text(question.options[question.correctOption]?.german ?? "")
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let explanation = question.localizedExplanation {
                Divider()
                Label("Why?", systemImage: "lightbulb.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.gold)
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.successGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.successGreen.opacity(0.3), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}
