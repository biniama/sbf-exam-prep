import SwiftUI

struct LearnView: View {
    @EnvironmentObject var store: QuestionStore
    @EnvironmentObject var progress: UserProgress

    @State private var selectedType: ExamType = .all
    @State private var selectedCategory: String? = nil
    @State private var searchText: String = ""
    @State private var showOnlyWrong = false
    @State private var showOnlyBookmarked = false
    @State private var showTopicPicker = false

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

    var categories: [String] { store.categories(for: selectedType) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.surfaceBG)

                Divider().opacity(0.5)

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
            .sheet(isPresented: $showTopicPicker) {
                TopicPickerSheet(
                    categories: categories,
                    selectedType: $selectedType,
                    selectedCategory: $selectedCategory
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Filter bar (one row)

    private var filterBar: some View {
        HStack(spacing: 8) {
            // Exam type compact picker
            examTypePicker

            Spacer()

            // Topics button
            Button { showTopicPicker = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption.weight(.semibold))
                    Text(selectedCategory ?? "Topics")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(selectedCategory != nil ? .white : Color.navyMid)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selectedCategory != nil ? Color.navy : Color.navyLight.opacity(0.12))
                .clipShape(Capsule())
            }

            // Mistakes toggle
            filterToggle(
                active: showOnlyWrong,
                icon: showOnlyWrong ? "xmark.circle.fill" : "xmark.circle"
            ) {
                showOnlyWrong.toggle()
                if showOnlyWrong { showOnlyBookmarked = false }
            }

            // Saved toggle
            filterToggle(
                active: showOnlyBookmarked,
                icon: showOnlyBookmarked ? "bookmark.fill" : "bookmark"
            ) {
                showOnlyBookmarked.toggle()
                if showOnlyBookmarked { showOnlyWrong = false }
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
                    Text(type == .all ? "All" : type.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedType == type ? .white : Color.navyMid)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedType == type ? Color.navy : Color.clear)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(3)
        .background(Color.navyLight.opacity(0.10))
        .clipShape(Capsule())
    }

    private func filterToggle(active: Bool, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(active ? Color.navy : Color.navyMid)
                .frame(width: 32, height: 32)
                .background(active ? Color.gold.opacity(0.25) : Color.navyLight.opacity(0.10))
                .clipShape(Circle())
        }
    }
}

// MARK: - Topic picker sheet

private struct TopicPickerSheet: View {
    let categories: [String]
    @Binding var selectedType: ExamType
    @Binding var selectedCategory: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: QuestionStore
    @EnvironmentObject var progress: UserProgress

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Exam type grid
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Exam Type")
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(ExamType.allCases) { type in
                                typeCard(type)
                            }
                        }
                    }

                    // Topic grid
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Topic")
                        LazyVGrid(columns: columns, spacing: 10) {
                            topicCard(nil)
                            ForEach(categories, id: \.self) { cat in
                                topicCard(cat)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.surfaceBG)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        withAnimation { selectedCategory = nil }
                    }
                    .foregroundStyle(selectedCategory != nil ? Color.errorRed : Color.secondary)
                    .disabled(selectedCategory == nil)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.navy)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .tracking(0.8)
    }

    private func typeCard(_ type: ExamType) -> some View {
        let isSelected = selectedType == type
        let count = store.questions(for: type).count
        return Button {
            withAnimation(.spring(response: 0.3)) {
                selectedType = type
                selectedCategory = nil
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : typeAccentColor(type))
                    .frame(width: 36, height: 36)
                    .background(isSelected ? typeAccentColor(type) : typeAccentColor(type).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.navy : Color.navy)
                    Text("\(count) q")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.navy)
                        .font(.subheadline)
                }
            }
            .padding(12)
            .background(isSelected ? Color.gold.opacity(0.18) : Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func topicCard(_ category: String?) -> some View {
        let isSelected = selectedCategory == category
        let allQ = store.questions(for: selectedType, category: category)
        let count = allQ.count
        let mastery = category.flatMap { progress.masteryForCategory($0) }
        let label = category ?? "All Topics"

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedCategory = category }
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.navy : Color.navy)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.navy)
                            .font(.subheadline)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(count) questions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let pct = mastery {
                        Spacer()
                        masteryBadge(pct)
                    }
                }

                if let pct = mastery {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.navyLight.opacity(0.12))
                            Capsule().fill(masteryColor(pct))
                                .frame(width: geo.size.width * CGFloat(pct))
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(12)
            .background(isSelected ? Color.gold.opacity(0.18) : Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.gold : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func masteryBadge(_ pct: Double) -> some View {
        Text("\(Int(pct * 100))%")
            .font(.caption2.bold())
            .foregroundStyle(masteryColor(pct))
    }

    private func masteryColor(_ pct: Double) -> Color {
        pct >= 0.8 ? Color.successGreen : pct >= 0.5 ? Color.gold : Color.errorRed
    }

    private func typeAccentColor(_ type: ExamType) -> Color {
        switch type {
        case .all:    return .navyLight
        case .shared: return .gold
        case .binnen: return .oceanTeal
        case .see:    return .navyLight
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
                .background(typeColor)
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
