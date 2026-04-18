import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var selectedType: ExamType = .all
    @State private var showingQuiz = false
    @StateObject private var vm = QuizViewModel()

    var bookmarkedQuestions: [Question] {
        store.questions(for: selectedType)
            .filter { progress.isBookmarked($0.uniqueId) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if bookmarkedQuestions.isEmpty {
                    emptyState
                } else {
                    // Type filter
                    examTypePicker
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    List {
                        ForEach(Array(bookmarkedQuestions.enumerated()), id: \.element.uniqueId) { index, q in
                            NavigationLink(destination: QuestionDetailView(questions: bookmarkedQuestions, startIndex: index)) {
                                QuestionRowView(question: q)
                            }
                            .listRowBackground(Color.cardBG)
                            .listRowSeparatorTint(Color.navyLight.opacity(0.15))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    withAnimation { progress.toggleBookmark(q.uniqueId) }
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash")
                                }
                                .tint(Color.gold)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.surfaceBG)
                }
            }
            .background(Color.surfaceBG)
            .navigationTitle("Saved Questions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !bookmarkedQuestions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            vm.setup(type: .all, count: min(bookmarkedQuestions.count, 30))
                            // Override with bookmarked only
                            vm.questions = Array(bookmarkedQuestions.shuffled().prefix(30))
                            showingQuiz = true
                        } label: {
                            Label("Quiz", systemImage: "play.circle")
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

    private var examTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(ExamType.allCases) { type in
                let count = store.questions(for: type).filter { progress.isBookmarked($0.uniqueId) }.count
                Button {
                    withAnimation(.spring(response: 0.3)) { selectedType = type }
                } label: {
                    VStack(spacing: 2) {
                        Text(type.rawValue)
                            .font(.caption.weight(.semibold))
                        Text("\(count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(selectedType == type ? .white : Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedType == type ? Color.navy : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color.navy.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundStyle(Color.navyLight.opacity(0.3))
            Text("No Saved Questions")
                .font(.title3.bold())
                .foregroundStyle(Color.navy)
            Text("Tap the bookmark icon while browsing or during a quiz to save questions here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}
