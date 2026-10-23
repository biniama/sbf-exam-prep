import SwiftUI

struct QuizSetupView: View {
    enum Mode: Hashable { case practice, review, mistakes, exam }

    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var mode: Mode = .practice
    @State private var selectedType: ExamType = .all
    @State private var examFormat: ExamFormat = .binnenMotor
    @State private var selectedCategory: String? = nil
    @State private var questionCount: Int = 20
    @State private var showQuiz = false
    @StateObject private var vm = QuizViewModel()

    private let counts = [10, 20, 30, 50]

    private var availableCount: Int {
        switch mode {
        case .practice: return store.questions(for: selectedType, category: selectedCategory).count
        case .review:   return progress.dueCount
        case .mistakes: return progress.wrongAnswerCount
        case .exam:     return ExamRules(format: examFormat).totalCount
        }
    }

    private var startCount: Int {
        switch mode {
        case .practice: return min(questionCount, availableCount)
        case .review, .mistakes: return min(30, availableCount)
        case .exam: return availableCount
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    heroCard
                    if hSize == .regular {
                        HStack(alignment: .top, spacing: 16) {
                            modeSection.frame(maxWidth: .infinity)
                            VStack(spacing: 16) { optionSections }.frame(maxWidth: .infinity)
                        }
                    } else {
                        modeSection
                        optionSections
                    }
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .readableWidth(Layout.wideWidth)
            }
            .background(Color.surfaceBG)
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showQuiz) {
                NavigationStack { QuizView(vm: vm) }
            }
            .onAppear {
                questionCount = progress.quizCount
                if !progress.licenceGoal.examFormats.contains(examFormat) {
                    examFormat = progress.licenceGoal.examFormats.first ?? .binnenMotor
                }
            }
        }
    }

    @ViewBuilder
    private var optionSections: some View {
        switch mode {
        case .practice:
            examTypeSection
            categorySection
            questionCountSection
        case .exam:
            examSection
        case .review:
            infoCard(icon: "arrow.triangle.2.circlepath", title: "Spaced repetition",
                     text: "Questions you answered come back after 1, 3, 7, 14 and 30 days. A wrong answer starts the cycle again.")
        case .mistakes:
            infoCard(icon: "xmark.circle", title: "Your mistakes",
                     text: "Questions you answered wrongly, most frequent first. Answer one correctly to reduce its count.")
        }
    }

    private var heroCard: some View {
        VStack(spacing: 8) {
            Image(systemName: mode == .exam ? "timer" : "brain.head.profile")
                .font(.largeTitle)
                .foregroundStyle(Color.gold)
                .accessibilityHidden(true)
            Text(mode == .exam ? "Exam simulation" : "Configure your quiz")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("\(availableCount) questions available")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(NavyGradient())
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mode

    private var modeSection: some View {
        sectionCard(title: "Mode", icon: "slider.horizontal.3") {
            VStack(spacing: 8) {
                modeRow(.practice, icon: "rectangle.stack", title: "Practice",
                        subtitle: "Random questions with instant feedback")
                modeRow(.review, icon: "arrow.triangle.2.circlepath", title: "Due for review",
                        subtitle: "\(progress.dueCount) questions due today", badge: progress.dueCount)
                modeRow(.mistakes, icon: "xmark.circle", title: "Mistakes",
                        subtitle: "\(progress.wrongAnswerCount) questions answered wrongly", badge: progress.wrongAnswerCount)
                modeRow(.exam, icon: "timer", title: "Exam simulation",
                        subtitle: "Official composition, time limit and pass marks")
            }
        }
    }

    private func modeRow(_ value: Mode, icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey,
                         badge: Int = 0) -> some View {
        let active = mode == value
        return Button {
            withAnimation(.spring(response: 0.3)) { mode = value }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(active ? .white : Color.navyLight)
                    .frame(width: 36, height: 36)
                    .background(active ? AnyShapeStyle(AppGradient.navy) : AnyShapeStyle(Color.navyLight.opacity(0.12)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if active {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.gold)
                }
            }
            .padding(10)
            .background(active ? Color.gold.opacity(0.12) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    // MARK: - Exam

    private var examSection: some View {
        let rules = ExamRules(format: examFormat)
        let formats = progress.licenceGoal.examFormats
        return sectionCard(title: "Exam", icon: "doc.text.magnifyingglass") {
            VStack(alignment: .leading, spacing: 12) {
                if formats.count > 1 {
                    Picker("Exam", selection: $examFormat) {
                        ForEach(formats) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Label(examFormat.title, systemImage: examFormat.icon)
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                }

                ruleRow("list.number", Text(rules.summary))
                ruleRow("checkmark.seal", Text(passText(rules)))
                ruleRow("timer", Text("Time limit: \(rules.minutes) minutes"))
                ruleRow("eye.slash", Text("No feedback until the end, like the real exam"))
                if rules.excludesNavigationTask {
                    ruleRow("map", Text("The navigation task of the SBF See exam is not included"))
                }
                if rules.totalPassMark == nil && rules.parts.count > 1 {
                    ruleRow("square.split.2x1", Text("Each part is assessed separately and must be passed."))
                }
                Text("Source: ELWIS scoring key for the SBF theory exam.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func passText(_ rules: ExamRules) -> String {
        if let total = rules.totalPassMark {
            return String(localized: "Pass: at least \(total) of \(rules.totalCount) correct in total")
        }
        let parts = rules.parts.compactMap { part in
            part.passMark.map { String(localized: "\($0) of \(part.count) \(part.type.partNoun)") }
        }
        return String(localized: "Pass: at least \(parts.formatted(.list(type: .and)))")
    }

    private func ruleRow(_ icon: String, _ text: Text) -> some View {
        Label {
            text.font(.subheadline).foregroundStyle(Color.ink).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.gold)
        }
    }

    // MARK: - Practice options

    private var examTypeSection: some View {
        sectionCard(title: "Exam", icon: "list.bullet") {
            VStack(spacing: 6) {
                ForEach(ExamType.allCases) { type in
                    let active = selectedType == type
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedType = type; selectedCategory = nil }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.icon).frame(width: 24)
                                .foregroundStyle(active ? Color.gold : .secondary)
                            Text(type.licenceName).font(.subheadline).foregroundStyle(Color.ink)
                            Spacer()
                            Text("\(store.questions(for: type).count)")
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            if active { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.gold) }
                        }
                        .padding(10)
                        .background(active ? Color.gold.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
        }
    }

    private var categorySection: some View {
        sectionCard(title: "Topic (optional)", icon: "tag") {
            Picker("Topic", selection: $selectedCategory) {
                Text("All topics").tag(String?.none)
                ForEach(store.categories(for: selectedType), id: \.self) { cat in
                    Text(store.categoryName(cat)).tag(String?.some(cat))
                }
            }
            .pickerStyle(.menu)
            .tint(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var questionCountSection: some View {
        sectionCard(title: "Number of questions", icon: "number.circle") {
            Picker("Number of questions", selection: $questionCount) {
                ForEach(counts, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func infoCard(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        sectionCard(title: title, icon: icon) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Start

    private var startButton: some View {
        Button {
            switch mode {
            case .practice: vm.setup(type: selectedType, count: startCount, category: selectedCategory)
            case .review: vm.setupDueReview()
            case .mistakes: vm.setupMistakes()
            case .exam: vm.setupExam(format: examFormat)
            }
            showQuiz = true
        } label: {
            Label(mode == .exam ? "Start exam simulation" : "Start · \(startCount) questions",
                  systemImage: mode == .exam ? "timer" : "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(startCount > 0 ? (mode == .exam ? AppGradient.errorRed : AppGradient.navy) : AppGradient.gray)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(startCount == 0)
    }

    private func sectionCard<Content: View>(title: LocalizedStringKey, icon: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
