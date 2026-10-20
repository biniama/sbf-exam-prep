import SwiftUI
import StoreKit

struct QuizResultView: View {
    @ObservedObject var vm: QuizViewModel
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    let onDismiss: () -> Void
    @State private var animateRing = false
    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var accuracy: Double { vm.questions.isEmpty ? 0 : Double(vm.correctCount) / Double(vm.questions.count) }

    var grade: LocalizedStringKey {
        if let result = vm.examResult { return result.passed ? "Passed" : "Not passed" }
        switch accuracy {
        case 0.9...: return "Excellent!"
        case 0.75...: return "Great job!"
        case 0.6...: return "Good effort"
        default: return "Keep practising"
        }
    }

    var gradeColor: Color {
        if let result = vm.examResult { return result.passed ? .successGreen : .errorRed }
        switch accuracy {
        case 0.8...: return .successGreen
        case 0.6...: return .gold
        default: return .errorRed
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                heroCard
                if let result = vm.examResult { examBreakdown(result) }
                statsRow
                if !vm.wrongIds.isEmpty { wrongAnswersSection }
                actionButtons
            }
            .padding(20)
            .padding(.top, 8)
            .readableWidth()
        }
        .background(Color.surfaceBG.ignoresSafeArea())
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done", action: onDismiss).fontWeight(.semibold)
            }
        }
        .overlay(alignment: .top) {
            if vm.examPassed && !reduceMotion { ConfettiView().allowsHitTesting(false) }
        }
        .onAppear {
            withAnimation(.easeOut(duration: reduceMotion ? 0 : 1).delay(0.3)) { animateRing = true }
            if accuracy >= 0.7 && progress.quizHistory.count >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { requestReview() }
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 18) {
            if let result = vm.examResult {
                HStack(spacing: 8) {
                    Image(systemName: result.passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    Text(result.passed ? "Exam passed" : "Exam not passed")
                        .font(.subheadline.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(result.passed ? AppGradient.successGreen : AppGradient.errorRed)
                .clipShape(Capsule())
            }
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: animateRing ? accuracy : 0)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(accuracy, format: .percent.precision(.fractionLength(0)))
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
            }
            .frame(width: 140, height: 140)
            .accessibilityHidden(true)

            Text(grade)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("\(vm.correctCount) of \(vm.questions.count) answered correctly")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(NavyGradient())
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private func examBreakdown(_ result: ExamResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Official scoring", systemImage: "list.clipboard")
            partRow(title: "Basic questions", correct: result.basicCorrect, total: result.rules.basicCount,
                    passMark: result.rules.basicPassMark, passed: result.basicPassed)
            partRow(title: "\(result.rules.type.title)-specific questions", correct: result.specificCorrect,
                    total: result.rules.specificCount, passMark: result.rules.specificPassMark,
                    passed: result.specificPassed)
            Text("Both parts are assessed separately and must each be passed.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if result.rules.excludesNavigationTask {
                Text("The real SBF See exam also includes a navigation task (9 questions, at least 7 correct), which is not part of this simulation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func partRow(title: LocalizedStringKey, correct: Int, total: Int, passMark: Int, passed: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? Color.successGreen : Color.errorRed)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text("Pass mark: \(passMark) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(correct)/\(total)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(passed ? Color.successGreen : Color.errorRed)
        }
        .accessibilityElement(children: .combine)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(vm.correctCount)", label: "Correct", icon: "checkmark.circle.fill", color: .successGreen)
            StatCard(value: "\(vm.wrongIds.count)", label: "Wrong", icon: "xmark.circle.fill", color: .errorRed)
            StatCard(value: vm.examType.title, label: "Exam", icon: vm.examType.icon, color: .navyLight)
        }
    }

    private var wrongAnswersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Review your mistakes", systemImage: "exclamationmark.circle")
                Text("\(vm.wrongIds.count)").goldBadge()
            }
            ForEach(vm.wrongIds, id: \.self) { id in
                if let q = store.question(id: id) {
                    NavigationLink(destination: QuestionDetailView(question: q)) {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.errorRed)
                            Text(q.germanText)
                                .font(.caption)
                                .foregroundStyle(Color.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { vm.retry() } label: {
                Label(vm.examMode ? "New exam simulation" : "Retry these questions",
                      systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            if !vm.wrongIds.isEmpty {
                Button {
                    vm.setup(questions: vm.wrongIds.compactMap { store.question(id: $0) }, mode: .mistakes)
                } label: {
                    Label("Practise the \(vm.wrongIds.count) mistakes", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.errorRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            Button(action: onDismiss) {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.navyLight.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
