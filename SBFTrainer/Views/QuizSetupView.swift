import SwiftUI

struct QuizSetupView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var selectedType: ExamType = .all
    @State private var selectedCategory: String? = nil
    @State private var questionCount: Int = 20
    @State private var fromWrong = false
    @State private var examSimulation = false
    @State private var showQuiz = false
    @StateObject private var vm = QuizViewModel()

    let counts = [10, 20, 30, 50]

    var availableCount: Int {
        if examSimulation { return store.questions(for: selectedType == .all ? .binnen : selectedType).count }
        if fromWrong { return progress.wrongAnswerCount }
        return store.questions(for: selectedType, category: selectedCategory).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero
                        heroCard
                        // Options
                        VStack(spacing: 16) {
                            modeSection
                            if examSimulation { examSimSection }
                            if !fromWrong && !examSimulation { examTypeSection }
                            if !fromWrong && !examSimulation { categorySection }
                            if !examSimulation { questionCountSection }
                        }
                        .padding(.horizontal, 20)

                        startButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Quiz Setup")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showQuiz) {
                NavigationStack { QuizView(vm: vm) }
            }
        }
    }

    private var heroCard: some View {
        ZStack {
            NavyGradient().frame(height: 160)
            VStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.gold)
                Text("Configure Your Quiz")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("\(availableCount) questions available")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }

    private var modeSection: some View {
        sectionCard(title: "Quiz Mode", icon: "slider.horizontal.3") {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    modeButton(active: !fromWrong && !examSimulation,
                               label: "All Questions", icon: "rectangle.stack") {
                        withAnimation { fromWrong = false; examSimulation = false }
                    }
                    modeButton(active: fromWrong,
                               label: "Mistakes Only", icon: "xmark.circle",
                               badge: progress.wrongAnswerCount > 0 ? "\(progress.wrongAnswerCount)" : nil) {
                        withAnimation { fromWrong = true; examSimulation = false }
                    }
                }
                examSimButton
            }
        }
    }

    private var examSimButton: some View {
        Button {
            withAnimation { examSimulation.toggle(); fromWrong = false }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(examSimulation ? .white : Color.gold)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exam Simulation")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(examSimulation ? .white : Color.navy)
                    Text("30 questions · 30 min · 70% to pass")
                        .font(.caption)
                        .foregroundStyle(examSimulation ? Color.white.opacity(0.8) : Color.navyMid)
                }
                Spacer()
                if examSimulation {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(14)
            .background(examSimulation ? Color.navy.gradient : Color.gold.opacity(0.12).gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(examSimulation ? Color.clear : Color.gold.opacity(0.4), lineWidth: 1.5))
        }
    }

    private var examSimSection: some View {
        sectionCard(title: "Choose Exam", icon: "doc.text.magnifyingglass") {
            VStack(spacing: 8) {
                ForEach([ExamType.binnen, ExamType.see]) { type in
                    Button {
                        withAnimation { selectedType = type }
                    } label: {
                        HStack {
                            Image(systemName: type.icon).frame(width: 24)
                                .foregroundStyle(selectedType == type ? Color.navy : .secondary)
                            Text(type == .binnen ? "SBF Binnen Motor" : "SBF See")
                                .font(.subheadline)
                                .foregroundStyle(Color.navy)
                            Spacer()
                            if selectedType == type {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.navy)
                            }
                        }
                        .padding(12)
                        .background(selectedType == type ? Color.navy.opacity(0.08) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func modeButton(active: Bool, label: String, icon: String, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(active ? .white : Color.navyMid)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.errorRed)
                            .clipShape(Circle())
                            .offset(x: 8, y: -8)
                    }
                }
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(active ? .white : Color.navyMid)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(active ? Color.navy.gradient : Color.navyLight.opacity(0.1).gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var examTypeSection: some View {
        sectionCard(title: "Exam Type", icon: "list.bullet") {
            VStack(spacing: 8) {
                ForEach(ExamType.allCases) { type in
                    examTypeRow(type)
                }
            }
        }
    }

    private func examTypeRow(_ type: ExamType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedType = type
                selectedCategory = nil
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .frame(width: 24)
                    .foregroundStyle(selectedType == type ? Color.navy : .secondary)
                Text(type.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(Color.navy)
                Spacer()
                Text("\(store.questions(for: type).count) Qs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if selectedType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.navy)
                }
            }
            .padding(12)
            .background(selectedType == type ? Color.navy.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var categorySection: some View {
        sectionCard(title: "Category (optional)", icon: "tag") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryPill(nil, label: "All")
                    ForEach(store.categories(for: selectedType), id: \.self) { cat in
                        categoryPill(cat, label: cat)
                    }
                }
            }
        }
    }

    private func categoryPill(_ value: String?, label: String) -> some View {
        Button {
            withAnimation { selectedCategory = value }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(selectedCategory == value ? .white : Color.navyMid)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(selectedCategory == value ? Color.navyMid : Color.navyLight.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var questionCountSection: some View {
        sectionCard(title: "Number of Questions", icon: "number.circle") {
            HStack(spacing: 10) {
                ForEach(counts, id: \.self) { n in
                    countButton(n)
                }
                Spacer()
            }
        }
    }

    private func countButton(_ n: Int) -> some View {
        let effective = min(n, availableCount)
        return Button {
            withAnimation { questionCount = n }
        } label: {
            Text("\(n)")
                .font(.subheadline.bold())
                .foregroundStyle(questionCount == n ? .white : Color.navyMid)
                .frame(width: 50, height: 40)
                .background(questionCount == n ? Color.navy.gradient : Color.navyLight.opacity(0.12).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(effective == 0)
        .opacity(effective == 0 ? 0.4 : 1)
    }

    private var startButton: some View {
        let examType = examSimulation ? (selectedType == .all ? ExamType.binnen : selectedType) : selectedType
        let count = examSimulation ? min(30, availableCount) : min(questionCount, availableCount)
        return Button {
            vm.setup(type: examType, count: count, category: examSimulation ? nil : selectedCategory,
                     fromWrong: fromWrong, examMode: examSimulation)
            showQuiz = true
        } label: {
            HStack {
                Image(systemName: examSimulation ? "timer" : "play.fill")
                Text(examSimulation ? "Start Exam Simulation" : "Start Quiz · \(count) Questions")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(count > 0 ? (examSimulation ? Color.errorRed.gradient : Color.navy.gradient) : Color.gray.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: (examSimulation ? Color.errorRed : Color.navy).opacity(0.3), radius: 8, y: 4)
        }
        .disabled(count == 0)
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.navyMid)
            content()
        }
        .padding(16)
        .cardStyle()
    }
}
