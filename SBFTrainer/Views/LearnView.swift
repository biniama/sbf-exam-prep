import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: QuestionStore
    @EnvironmentObject var progress: UserProgress

    @State private var selectedType: ExamType = .all
    @State private var selectedCategory: String? = nil
    @State private var searchText: String = ""
    @State private var showOnlyWrong = false
    @State private var showOnlyBookmarked = false

    var filteredQuestions: [Question] {
        var q = store.questions(for: selectedType, category: selectedCategory)
        if showOnlyWrong      { q = q.filter { progress.isWrong($0.uniqueId) } }
        if showOnlyBookmarked { q = q.filter { progress.isBookmarked($0.uniqueId) } }
        if !searchText.isEmpty {
            let s = searchText.lowercased()
            q = q.filter {
                $0.germanText.lowercased().contains(s) ||
                $0.englishText.lowercased().contains(s) ||
                $0.category.lowercased().contains(s) ||
                "\($0.questionNumber)".contains(s)
            }
        }
        return q
    }

    var categories: [String] {
        store.categories(for: selectedType)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type Picker
                examTypePicker
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Category scroll
                categoryScroll
                    .padding(.top, 8)

                // Filter chips
                filterChips
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                // Question list
                List {
                    ForEach(Array(filteredQuestions.enumerated()), id: \.element.uniqueId) { index, q in
                        NavigationLink(destination: QuestionDetailView(questions: filteredQuestions, startIndex: index)) {
                            QuestionRowView(question: q)
                        }
                        .listRowBackground(Color.cardBG)
                        .listRowSeparatorTint(Color.navyLight.opacity(0.15))
                    }
                }
                .listStyle(.plain)
                .background(Color.surfaceBG)
            }
            .background(Color.surfaceBG)
            .searchable(text: $searchText, prompt: "Search questions…")
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(filteredQuestions.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.navy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gold.opacity(0.3))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var examTypePicker: some View {
        HStack(spacing: 0) {
            ForEach(ExamType.allCases) { type in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedType = type
                        selectedCategory = nil
                    }
                } label: {
                    Text(type.rawValue)
                        .font(.caption.weight(.semibold))
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

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(nil, label: "All")
                ForEach(categories, id: \.self) { cat in
                    categoryChip(cat, label: cat)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func categoryChip(_ value: String?, label: String) -> some View {
        let mastery = value.flatMap { progress.masteryForCategory($0) }
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedCategory = value }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption.weight(.medium))
                if let pct = mastery {
                    Text("\(Int(pct * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(pct >= 0.8 ? Color.successGreen : pct >= 0.5 ? Color.gold : Color.errorRed)
                }
            }
            .foregroundStyle(selectedCategory == value ? .white : Color.navyMid)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedCategory == value ? Color.navyMid : Color.navyLight.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            filterToggle(active: showOnlyWrong, label: "Mistakes", icon: "xmark.circle") {
                showOnlyWrong.toggle()
                if showOnlyWrong { showOnlyBookmarked = false }
            }
            filterToggle(active: showOnlyBookmarked, label: "Saved", icon: "bookmark") {
                showOnlyBookmarked.toggle()
                if showOnlyBookmarked { showOnlyWrong = false }
            }
            Spacer()
        }
    }

    private func filterToggle(active: Bool, label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.medium))
                .foregroundStyle(active ? .white : Color.navyMid)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(active ? Color.navy : Color.navyLight.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}

struct QuestionRowView: View {
    let question: Question
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        HStack(spacing: 12) {
            // Number badge
            Text("\(question.questionNumber)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(typeColor.gradient)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(question.germanText)
                    .font(.subheadline)
                    .foregroundStyle(Color.navy)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    CategoryBadge(text: question.category)
                    if question.hasImage {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                if progress.isBookmarked(question.uniqueId) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(Color.gold)
                }
                if progress.isWrong(question.uniqueId) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.errorRed)
                }
            }
        }
        .padding(.vertical, 6)
    }

    var typeColor: Color {
        switch question.examType {
        case .shared: return .gold
        case .binnen: return .oceanTeal
        case .see:    return .navyLight
        case .all:    return .navy
        }
    }
}
