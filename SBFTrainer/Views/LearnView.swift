import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: QuestionStore
    @EnvironmentObject var progress: UserProgress
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var selectedType: ExamType = .all
    @State private var selectedCategory: String? = nil
    @State private var searchText: String = ""
    @State private var showOnlyWrong = false
    @State private var showOnlyBookmarked = false
    @State private var showTopicPicker = false
    #if DEBUG
    @State private var showDebugQuestion = DebugLaunchOptions.selectedQuestion != nil
    #endif
    @State private var selection: String? = {
        #if DEBUG
        return DebugLaunchOptions.selectedQuestion
        #else
        return nil
        #endif
    }()

    var filteredQuestions: [Question] {
        var q = store.questions(for: selectedType, category: selectedCategory)
        if showOnlyWrong      { q = q.filter { progress.isWrong($0.uniqueId) } }
        if showOnlyBookmarked { q = q.filter { progress.isBookmarked($0.uniqueId) } }
        let s = searchText.trimmingCharacters(in: .whitespaces)
        if !s.isEmpty {
            q = q.filter {
                $0.germanText.localizedCaseInsensitiveContains(s) ||
                $0.englishText.localizedCaseInsensitiveContains(s) ||
                $0.localizedCategory.localizedCaseInsensitiveContains(s) ||
                "\($0.questionNumber)" == s
            }
        }
        return q
    }

    var body: some View {
        if hSize == .regular {
            NavigationSplitView {
                listScreen(selectable: true)
                    .navigationSplitViewColumnWidth(min: 340, ideal: 400, max: 480)
            } detail: {
                NavigationStack {
                    let qs = filteredQuestions
                    if let id = selection, let index = qs.firstIndex(where: { $0.uniqueId == id }) {
                        QuestionDetailView(questions: qs, startIndex: index)
                            .id(id)
                    } else {
                        ContentUnavailableView("Select a question", systemImage: "text.book.closed",
                                               description: Text("Choose a question from the list to study it."))
                    }
                }
            }
        } else {
            NavigationStack {
                listScreen(selectable: false)
                    #if DEBUG
                    .navigationDestination(isPresented: $showDebugQuestion) {
                        let qs = filteredQuestions
                        if let id = selection, let index = qs.firstIndex(where: { $0.uniqueId == id }) {
                            QuestionDetailView(questions: qs, startIndex: index)
                        }
                    }
                    #endif
            }
        }
    }

    private func listScreen(selectable: Bool) -> some View {
        let qs = filteredQuestions
        return VStack(spacing: 0) {
            filterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.surfaceBG)
            Divider().opacity(0.5)
            if qs.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if selectable {
                List(selection: $selection) {
                    ForEach(qs) { q in
                        QuestionRowView(question: q)
                            .tag(q.uniqueId)
                            .listRowBackground(selection == q.uniqueId ? Color.gold.opacity(0.18) : Color.cardBG)
                    }
                }
                .listStyle(.plain)
            } else {
                List {
                    ForEach(Array(qs.enumerated()), id: \.element.uniqueId) { index, q in
                        NavigationLink(destination: QuestionDetailView(questions: qs, startIndex: index)) {
                            QuestionRowView(question: q)
                        }
                        .listRowBackground(Color.cardBG)
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Color.surfaceBG)
        .searchable(text: $searchText, prompt: Text("Search questions"))
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(qs.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gold.opacity(0.35))
                    .clipShape(Capsule())
                    .accessibilityLabel(Text("\(qs.count) questions"))
            }
        }
        .sheet(isPresented: $showTopicPicker) {
            TopicPickerSheet(selectedType: $selectedType, selectedCategory: $selectedCategory)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            Button { showTopicPicker = true } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(filterTitle)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isFiltered ? .white : Color.inkSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isFiltered ? Color.navy : Color.navyLight.opacity(0.12))
                .clipShape(Capsule())
            }
            .accessibilityHint(Text("Choose exam and topic"))

            Spacer(minLength: 4)

            filterToggle(active: showOnlyWrong,
                         icon: showOnlyWrong ? "xmark.circle.fill" : "xmark.circle",
                         label: "Show only mistakes") {
                showOnlyWrong.toggle()
                if showOnlyWrong { showOnlyBookmarked = false }
            }
            filterToggle(active: showOnlyBookmarked,
                         icon: showOnlyBookmarked ? "bookmark.fill" : "bookmark",
                         label: "Show only saved questions") {
                showOnlyBookmarked.toggle()
                if showOnlyBookmarked { showOnlyWrong = false }
            }
        }
    }

    private var isFiltered: Bool { selectedType != .all || selectedCategory != nil }

    private var filterTitle: String {
        if let cat = selectedCategory { return store.categoryName(cat) }
        if selectedType != .all { return selectedType.licenceName }
        return String(localized: "All topics")
    }

    private func filterToggle(active: Bool, icon: String, label: LocalizedStringKey,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(active ? Color.navy : Color.inkSecondary)
                .frame(width: 40, height: 40)
                .background(active ? Color.gold.opacity(0.35) : Color.navyLight.opacity(0.12))
                .clipShape(Circle())
        }
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

// MARK: - Topic picker sheet

private struct TopicPickerSheet: View {
    @Binding var selectedType: ExamType
    @Binding var selectedCategory: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: QuestionStore
    @EnvironmentObject var progress: UserProgress

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Exam")
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(ExamType.allCases) { typeCard($0) }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Topic")
                        LazyVGrid(columns: columns, spacing: 10) {
                            topicCard(nil)
                            ForEach(store.categories(for: selectedType), id: \.self) { topicCard($0) }
                        }
                    }
                }
                .padding(16)
                .readableWidth()
            }
            .background(Color.surfaceBG)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation { selectedType = .all; selectedCategory = nil }
                    }
                    .disabled(selectedType == .all && selectedCategory == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func typeCard(_ type: ExamType) -> some View {
        let isSelected = selectedType == type
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedType = type
                selectedCategory = nil
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color.navyLight)
                    .frame(width: 36, height: 36)
                    .background(isSelected ? Color.navy : Color.navyLight.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.licenceName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                    Text("\(store.questions(for: type).count) questions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.gold.opacity(0.18) : Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.gold : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func topicCard(_ category: String?) -> some View {
        let isSelected = selectedCategory == category
        let count = store.questions(for: selectedType, category: category).count
        let mastery = category.flatMap { progress.masteryForCategory($0) }
        let label = category.map { store.categoryName($0) } ?? String(localized: "All topics")

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedCategory = category }
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text("\(count) questions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let pct = mastery {
                        Text(pct, format: .percent.precision(.fractionLength(0)))
                            .font(.caption2.bold())
                            .foregroundStyle(masteryColor(pct))
                    }
                }
                if let pct = mastery {
                    ProgressView(value: pct)
                        .tint(masteryColor(pct))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.gold.opacity(0.18) : Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(isSelected ? Color.gold : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func masteryColor(_ pct: Double) -> Color {
        pct >= 0.8 ? .successGreen : pct >= 0.5 ? .gold : .errorRed
    }
}

// MARK: - Row

struct QuestionRowView: View {
    let question: Question
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        HStack(spacing: 12) {
            Text("\(question.questionNumber)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(ExamTypeBadge(type: question.examType).badgeColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(question.germanText)
                    .font(.subheadline)
                    .foregroundStyle(Color.ink)
                    .lineLimit(3)
                HStack(spacing: 6) {
                    CategoryBadge(text: question.localizedCategory)
                    if question.hasImage {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if question.soundPattern != nil {
                        Image(systemName: "speaker.wave.2")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 4) {
                if progress.isBookmarked(question.uniqueId) {
                    Image(systemName: "bookmark.fill").font(.caption).foregroundStyle(Color.gold)
                }
                if progress.isWrong(question.uniqueId) {
                    Image(systemName: "exclamationmark.circle.fill").font(.caption).foregroundStyle(Color.errorRed)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Question \(question.questionNumber): \(question.germanText)"))
        .accessibilityValue(accessibilityStatus)
    }

    private var accessibilityStatus: Text {
        var parts: [String] = [question.localizedCategory]
        if progress.isBookmarked(question.uniqueId) { parts.append(String(localized: "Saved")) }
        if progress.isWrong(question.uniqueId) { parts.append(String(localized: "Answered wrongly")) }
        return Text(parts.joined(separator: ", "))
    }
}
