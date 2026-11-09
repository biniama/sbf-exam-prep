import SwiftUI

/// "Saved" tab: bookmarked questions and the list of mistakes.
struct BookmarksView: View {
    enum Segment: Hashable { case saved, mistakes }

    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var segment: Segment = .saved
    @State private var showingQuiz = false
    @StateObject private var vm = QuizViewModel()

    var savedQuestions: [Question] {
        store.allQuestions.filter { progress.isBookmarked($0.uniqueId) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("List", selection: $segment) {
                    Text("Saved (\(progress.bookmarks.count))").tag(Segment.saved)
                    Text("Mistakes (\(progress.wrongAnswerCount))").tag(Segment.mistakes)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .readableWidth()

                switch segment {
                case .saved: savedList
                case .mistakes: MistakesList()
                }
            }
            .background(Color.surfaceBG)
            .navigationTitle(segment == .saved ? "Saved questions" : "Mistakes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if segment == .saved {
                            vm.setup(questions: Array(savedQuestions.shuffled().prefix(30)), mode: .saved)
                        } else {
                            vm.setupMistakes()
                        }
                        showingQuiz = true
                    } label: {
                        Label("Practise", systemImage: "play.circle")
                    }
                    .disabled(segment == .saved ? savedQuestions.isEmpty : progress.wrongAnswerCount == 0)
                }
            }
            .fullScreenCover(isPresented: $showingQuiz) {
                NavigationStack { QuizView(vm: vm) }
            }
        }
    }

    @ViewBuilder
    private var savedList: some View {
        let qs = savedQuestions
        if qs.isEmpty {
            ContentUnavailableView {
                Label("No saved questions", systemImage: "bookmark")
            } description: {
                Text("Tap the bookmark while browsing or during a quiz to collect questions here.")
            }
        } else {
            List {
                ForEach(Array(qs.enumerated()), id: \.element.uniqueId) { index, q in
                    NavigationLink(destination: QuestionDetailView(questions: qs, startIndex: index)) {
                        QuestionRowView(question: q)
                    }
                    .listRowBackground(Color.cardBG)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation { progress.toggleBookmark(q.uniqueId) }
                        } label: {
                            Label("Remove", systemImage: "bookmark.slash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}

/// Questions answered wrongly, most frequent first.
struct MistakesList: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore

    var questions: [(question: Question, count: Int)] {
        progress.wrongAnswerIds.sorted { $0.value > $1.value }
            .compactMap { id, count in store.question(id: id).map { ($0, count) } }
    }

    var body: some View {
        let items = questions
        if items.isEmpty {
            ContentUnavailableView {
                Label("No mistakes", systemImage: "checkmark.circle")
            } description: {
                Text("Questions you answer wrongly will appear here.")
            }
        } else {
            List {
                Section {
                    ForEach(items, id: \.question.uniqueId) { item in
                        NavigationLink(destination: QuestionDetailView(question: item.question)) {
                            HStack(spacing: 12) {
                                Text("\(item.count)×")
                                    .font(.caption.bold().monospacedDigit())
                                    .foregroundStyle(Color.errorRed)
                                    .frame(width: 40, height: 36)
                                    .background(Color.errorRed.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .accessibilityLabel(Text("Answered wrongly \(item.count) times"))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.question.germanText)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.ink)
                                        .lineLimit(2)
                                    HStack(spacing: 6) {
                                        ExamTypeBadge(type: item.question.examType)
                                        CategoryBadge(text: item.question.localizedCategory)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.cardBG)
                        .swipeActions(edge: .leading) {
                            Button {
                                withAnimation { progress.markMastered(item.question.uniqueId) }
                            } label: {
                                Label("Mastered", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { progress.clearWrongAnswer(item.question.uniqueId) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                } footer: {
                    Text("Swipe right to mark a question as mastered, swipe left to remove it.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }
}
