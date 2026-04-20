import SwiftUI
import StoreKit

struct QuizResultView: View {
    @ObservedObject var vm: QuizViewModel
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    let onDismiss: () -> Void
    @State private var showingReview = false
    @State private var animateRing = false
    @Environment(\.requestReview) private var requestReview

    var accuracy: Double { vm.questions.isEmpty ? 0 : Double(vm.correctCount) / Double(vm.questions.count) }
    var grade: String {
        switch accuracy {
        case 0.9...: return "Excellent!"
        case 0.75...: return "Great Job!"
        case 0.6...: return "Good Effort"
        default: return "Keep Practicing"
        }
    }
    var gradeColor: Color {
        switch accuracy {
        case 0.8...: return .successGreen
        case 0.6...: return .gold
        default: return .errorRed
        }
    }

    var body: some View {
        ZStack {
            Color.surfaceBG.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Hero result card
                    heroCard
                    // Stats row
                    statsRow
                    // Wrong answers list
                    if !vm.wrongIds.isEmpty { wrongAnswersSection }
                    // Actions
                    actionButtons
                }
                .padding(20)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { onDismiss() }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.navy)
            }
        }
        .overlay(alignment: .top) {
            if vm.examMode && vm.examPassed {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1).delay(0.3)) { animateRing = true }
            if accuracy >= 0.7 && progress.quizHistory.count >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { requestReview() }
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 20) {
            // Exam pass/fail banner
            if vm.examMode {
                HStack(spacing: 8) {
                    Image(systemName: vm.examPassed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    Text(vm.examPassed ? "BESTANDEN · PASSED" : "NICHT BESTANDEN · FAILED")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: vm.examPassed ? "checkmark.seal.fill" : "xmark.seal.fill")
                }
                .foregroundStyle(vm.examPassed ? Color.successGreen : Color.errorRed)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background((vm.examPassed ? Color.successGreen : Color.errorRed).opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke((vm.examPassed ? Color.successGreen : Color.errorRed).opacity(0.4), lineWidth: 1.5))
            }

            // Result ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 14)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: animateRing ? accuracy : 0)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text("\(Int(accuracy * 100))%")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(grade)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }

            Text(grade)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("\(vm.correctCount) correct out of \(vm.questions.count) questions")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.navy, .navyMid], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.navy.opacity(0.3), radius: 12, y: 6)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(vm.correctCount)",    label: "Correct",   icon: "checkmark.circle.fill", color: .successGreen)
            StatCard(value: "\(vm.wrongIds.count)",  label: "Wrong",     icon: "xmark.circle.fill",     color: .errorRed)
            StatCard(value: vm.examType.rawValue,    label: "Mode",      icon: "rectangle.stack",       color: .navyLight)
        }
    }

    private var wrongAnswersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Questions to Review", systemImage: "exclamationmark.circle")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Spacer()
                Text("\(vm.wrongIds.count)")
                    .goldBadge()
            }

            ForEach(vm.wrongIds.prefix(5), id: \.self) { id in
                if let q = store.question(id: id) {
                    NavigationLink(destination: QuestionDetailView(question: q)) {
                        wrongRow(q)
                    }
                }
            }

            if vm.wrongIds.count > 5 {
                Text("+ \(vm.wrongIds.count - 5) more — see Review on Home")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func wrongRow(_ q: Question) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(Color.errorRed)
            Text("Q\(q.questionNumber): \(q.germanText)")
                .font(.caption)
                .foregroundStyle(Color.navy)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .cardStyle()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                vm.setup(type: vm.examType, count: vm.questions.count)
            } label: {
                Label("Retry Same Quiz", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if !vm.wrongIds.isEmpty {
                Button {
                    vm.setup(type: .all, count: vm.wrongIds.count, fromWrong: true)
                } label: {
                    Label("Practice Mistakes (\(vm.wrongIds.count))", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.errorRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.errorRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.errorRed.opacity(0.3), lineWidth: 1))
                }
            }

            Button(action: onDismiss) {
                Text("Done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.navyMid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.navyLight.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
