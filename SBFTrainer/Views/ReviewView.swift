import SwiftUI

struct ReviewView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var showingQuiz = false
    @StateObject private var vm = QuizViewModel()
    @State private var sortByCount = true

    var wrongQuestions: [Question] {
        let sorted = progress.wrongAnswerIds.sorted {
            sortByCount ? $0.value > $1.value : $0.key < $1.key
        }
        return sorted.compactMap { store.question(id: $0.key) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if wrongQuestions.isEmpty {
                    emptyState
                } else {
                    // Header stats
                    reviewHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    List {
                        ForEach(wrongQuestions) { q in
                            NavigationLink(destination: QuestionDetailView(question: q)) {
                                wrongRow(q)
                            }
                            .listRowBackground(Color.cardBG)
                            .listRowSeparatorTint(Color.navyLight.opacity(0.15))
                            .swipeActions(edge: .leading) {
                                Button {
                                    withAnimation { progress.markMastered(q.uniqueId) }
                                } label: {
                                    Label("Mastered", systemImage: "checkmark.circle")
                                }
                                .tint(Color.successGreen)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { progress.clearWrongAnswer(q.uniqueId) }
                                } label: {
                                    Label("Clear", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.surfaceBG)
                }
            }
            .background(Color.surfaceBG)
            .navigationTitle("Review Mistakes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { sortByCount = true  } label: { Label("Most wrong first", systemImage: "arrow.down.circle") }
                        Button { sortByCount = false } label: { Label("By ID", systemImage: "textformat.abc") }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(Color.navyMid)
                    }
                }
                if !wrongQuestions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            vm.setup(type: .all, count: min(wrongQuestions.count, 30), fromWrong: true)
                            showingQuiz = true
                        } label: {
                            Label("Practice All", systemImage: "play.circle")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(Color.navy)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingQuiz) {
                NavigationStack { QuizView(vm: vm) }
            }
        }
    }

    private var reviewHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(wrongQuestions.count) questions to review")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.navy)
                Text("Swipe left to mark as mastered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                vm.setup(type: .all, count: min(wrongQuestions.count, 20), fromWrong: true)
                showingQuiz = true
            } label: {
                Label("Start", systemImage: "play.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppGradient.errorRed)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .cardStyle()
    }

    private func wrongRow(_ q: Question) -> some View {
        let count = progress.wrongAnswerIds[q.uniqueId] ?? 0
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.errorRed.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.errorRed)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(q.germanText)
                    .font(.subheadline)
                    .foregroundStyle(Color.navy)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    ExamTypeBadge(type: q.examType)
                    CategoryBadge(text: q.category)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.successGreen.opacity(0.3))
            Text("All Clear!")
                .font(.title2.bold())
                .foregroundStyle(Color.navy)
            Text("You have no wrong answers to review. Keep taking quizzes to track your progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
