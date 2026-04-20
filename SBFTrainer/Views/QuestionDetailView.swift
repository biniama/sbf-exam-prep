import SwiftUI

struct QuestionDetailView: View {
    let questions: [Question]
    @State private var currentIndex: Int
    @EnvironmentObject var progress: UserProgress
    @State private var revealAnswer = false
    @State private var selectedOption: String? = nil

    // Convenience init for single-question contexts (results, bookmarks from external)
    init(question: Question) {
        self.questions = [question]
        self._currentIndex = State(initialValue: 0)
    }

    // Full init for Browse/Bookmarks list navigation
    init(questions: [Question], startIndex: Int) {
        self.questions = questions
        self._currentIndex = State(initialValue: startIndex)
    }

    var question: Question { questions[currentIndex] }
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex == questions.count - 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        ExamTypeBadge(type: question.examType)
                        CategoryBadge(text: question.category)
                    }
                    Spacer()
                    Text("Q\(question.questionNumber)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.navyMid)
                }

                // Question text (German)
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.germanText)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.navy)
                        .fixedSize(horizontal: false, vertical: true)

                    if progress.showEnglish && !question.englishText.isEmpty {
                        Text(question.englishText)
                            .font(.subheadline)
                            .foregroundStyle(Color.navyMid.opacity(0.8))
                            .italic()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.navyLight.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Image
                if question.hasImage {
                    QuestionImageView(question: question)
                }

                // Options
                Text("Answer Options")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(question.sortedOptions, id: \.key) { key, option in
                    optionRow(key: key, option: option)
                }

                // Reveal button
                if !revealAnswer {
                    Button {
                        withAnimation(.spring(response: 0.4)) { revealAnswer = true }
                    } label: {
                        Label("Show Correct Answer", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppGradient.navy)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.successGreen)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Correct: Option \(question.correctOption)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.successGreen)
                            Text(question.options[question.correctOption]?.german ?? "")
                                .font(.caption)
                                .foregroundStyle(Color.navy)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.successGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.successGreen.opacity(0.3), lineWidth: 1)
                    )
                    .transition(.scale.combined(with: .opacity))
                }

                // Next question button (when list has multiple questions)
                if questions.count > 1 && !isLast {
                    Button {
                        advance()
                    } label: {
                        Label("Next Question", systemImage: "arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.navy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(20)
        }
        .background(Color.surfaceBG)
        .navigationTitle(questions.count > 1 ? "\(currentIndex + 1) / \(questions.count)" : "Question \(question.questionNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if questions.count > 1 {
                        Button {
                            guard !isFirst else { return }
                            withAnimation { currentIndex -= 1 }
                            revealAnswer = false
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(isFirst ? Color.secondary : Color.navyMid)
                        }
                        .disabled(isFirst)

                        Button {
                            guard !isLast else { return }
                            advance()
                        } label: {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(isLast ? Color.secondary : Color.navyMid)
                        }
                        .disabled(isLast)
                    }

                    Button {
                        withAnimation { progress.toggleBookmark(question.uniqueId) }
                    } label: {
                        Image(systemName: progress.isBookmarked(question.uniqueId) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(progress.isBookmarked(question.uniqueId) ? Color.gold : Color.navyMid)
                    }
                }
            }
        }
        .onChange(of: currentIndex) {
            revealAnswer = false
            selectedOption = nil
        }
    }

    private func advance() {
        withAnimation { currentIndex += 1 }
        revealAnswer = false
    }

    private func optionRow(key: String, option: QuestionOption) -> some View {
        let isCorrect = revealAnswer && key == question.correctOption
        return HStack(spacing: 12) {
            Text(key)
                .font(.caption.weight(.bold))
                .foregroundStyle(isCorrect ? Color.successGreen : .secondary)
                .frame(width: 26, height: 26)
                .background(
                    Circle().fill(
                        isCorrect ? Color.successGreen.opacity(0.15) : Color.gray.opacity(0.1)
                    )
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(option.german)
                    .font(.subheadline)
                    .foregroundStyle(Color.navy)
                    .fixedSize(horizontal: false, vertical: true)
                if progress.showEnglish && !option.english.isEmpty {
                    Text(option.english)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.successGreen)
            }
        }
        .padding(12)
        .background(isCorrect ? Color.successGreen.opacity(0.06) : Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Color.successGreen.opacity(0.4) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: revealAnswer)
    }
}
