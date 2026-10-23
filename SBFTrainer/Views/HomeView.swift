import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @Environment(\.horizontalSizeClass) private var hSize
    @StateObject private var quizVM = QuizViewModel()
    @State private var showingQuiz = false
    @State private var showingLicence = false

    init(selectedTab: Binding<AppTab> = .constant(.home)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header(topInset: geo.safeAreaInsets.top)
                            .padding(.bottom, 20)
                        content
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                            .readableWidth(Layout.wideWidth)
                    }
                }
                .background(Color.surfaceBG)
                .ignoresSafeArea(edges: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showingQuiz) {
                NavigationStack { QuizView(vm: quizVM) }
            }
            .sheet(isPresented: $showingLicence) {
                NavigationStack { LicenceSettingsView(isSheet: true) }
            }
            #if DEBUG
            .task {
                switch DebugLaunchOptions.autoQuiz {
                case "exam-binnen": quizVM.setupExam(format: .binnenMotor); showingQuiz = true
                case "exam-segeln": quizVM.setupExam(format: .binnenMotorSail); showingQuiz = true
                case "exam-see": quizVM.setupExam(format: .see); showingQuiz = true
                case "practice": quizVM.setup(type: .all, count: 20); showingQuiz = true
                default: break
                }
            }
            #endif
        }
    }

    // MARK: Layout

    @ViewBuilder
    private var content: some View {
        if hSize == .regular {
            VStack(spacing: 16) {
                licencePrompt
                statsRow
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 16) { todayCard; quickActions }
                    VStack(spacing: 16) { streakSection; recentSection }
                }
            }
        } else {
            VStack(spacing: 16) {
                licencePrompt
                statsRow
                todayCard
                streakSection
                quickActions
                recentSection
            }
        }
    }

    // MARK: Header

    private func header(topInset: CGFloat) -> some View {
        ZStack {
            NavyGradient()
            VStack(spacing: 12) {
                Image(systemName: "sailboat")
                    .font(.largeTitle.weight(.medium))
                    .foregroundStyle(Color.gold)
                    .accessibilityHidden(true)
                Text("SBF Exam Prep")
                    .font(.title.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text("Sportbootführerschein Binnen & See")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))
                accuracyRing
                    .padding(.top, 6)
            }
            .padding(.top, topInset + 20)
            .padding(.bottom, 28)
            .padding(.horizontal, 24)
        }
    }

    private var accuracyRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress.overallAccuracy)
                .stroke(Color.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress.overallAccuracy)
            VStack(spacing: 2) {
                Text(progress.overallAccuracy, format: .percent.precision(.fractionLength(0)))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Accuracy")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .frame(width: 110, height: 110)
        .accessibilityElement(children: .combine)
    }

    // MARK: Licence prompt

    /// Shown until the learner has picked a licence – also announces the sailing questions to existing users.
    @ViewBuilder
    private var licencePrompt: some View {
        if !progress.hasChosenLicence {
            Button { showingLicence = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "sailboat.fill")
                        .font(.title2)
                        .foregroundStyle(Color.navy)
                        .frame(width: 44, height: 44)
                        .background(AppGradient.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("New: sailing questions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.ink)
                        Text("Choose your licence to get the right exam simulation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(14)
                .cardStyle()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(progress.totalAnswered)", label: "Answered",
                     icon: "checkmark.circle", color: .successGreen)
            StatCard(value: "\(progress.masteredCount)", label: "Mastered",
                     icon: "star.circle", color: .gold)
            StatCard(value: "\(progress.dailyStreak)", label: "Day streak",
                     icon: "flame", color: .errorRed)
        }
    }

    // MARK: Today (spaced repetition)

    private var todayCard: some View {
        let due = progress.dueCount
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Today", systemImage: "calendar")
            HStack(spacing: 14) {
                Image(systemName: due > 0 ? "arrow.triangle.2.circlepath.circle.fill" : "checkmark.seal.fill")
                    .font(.title)
                    .foregroundStyle(due > 0 ? Color.gold : Color.successGreen)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(due > 0 ? "\(due) questions due for review" : "Nothing due right now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    Text(due > 0
                         ? "Questions come back at growing intervals until you know them for good."
                         : "Answer new questions — anything you get wrong will come back for review.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button {
                if due > 0 { quizVM.setupDueReview() } else { quizVM.setup(type: .all, count: progress.quizCount) }
                showingQuiz = true
            } label: {
                Label(due > 0 ? "Start review" : "Start a quick quiz",
                      systemImage: due > 0 ? "play.fill" : "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AppGradient.navy)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: Streak

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Study streak", systemImage: "flame.fill")
                Text("^[\(progress.dailyStreak) day](inflect: true)")
                    .font(.caption.bold())
                    .foregroundStyle(progress.dailyStreak > 0 ? Color.navy : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(progress.dailyStreak > 0 ? AppGradient.gold : AppGradient.gray)
                    .clipShape(Capsule())
                    .fixedSize()
            }
            HStack(spacing: 6) {
                ForEach(progress.last7Days, id: \.date) { day in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(day.studied ? Color.gold : Color.navyLight.opacity(0.15))
                            .frame(width: 34, height: 34)
                            .overlay {
                                if day.studied {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.navy)
                                }
                            }
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(day.studied ? Color.ink : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide)))
                    .accessibilityValue(day.studied ? Text("Studied") : Text("Not studied"))
                }
            }
            .padding(14)
            .cardStyle()
        }
    }

    // MARK: Quick actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick start", systemImage: "bolt.fill")
            VStack(spacing: 10) {
                quickActionRow(icon: "play.circle.fill", title: Text("Quick quiz"),
                               subtitle: Text("\(progress.quizCount) random questions"), color: .navy) {
                    quizVM.setup(type: .all, count: progress.quizCount)
                    showingQuiz = true
                }
                ForEach(progress.licenceGoal.examFormats) { format in
                    quickActionRow(icon: "timer", title: Text("Exam simulation · \(format.title)"),
                                   subtitle: Text(ExamRules(format: format).summary),
                                   color: format == .see ? .navyLight : .oceanTeal) {
                        quizVM.setupExam(format: format)
                        showingQuiz = true
                    }
                }
                if progress.wrongAnswerCount > 0 {
                    quickActionRow(icon: "arrow.counterclockwise.circle.fill", title: Text("Practise mistakes"),
                                   subtitle: Text("\(progress.wrongAnswerCount) questions to retry"), color: .errorRed) {
                        quizVM.setupMistakes()
                        showingQuiz = true
                    }
                }
                quickActionRow(icon: "list.number", title: Text("All questions in order"),
                               subtitle: Text("Go through the whole catalogue"), color: .gold) {
                    selectedTab = .browse
                }
            }
        }
    }

    private func quickActionRow(icon: String, title: Text, subtitle: Text,
                                color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ink)
                    subtitle
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .cardStyle()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Recent

    @ViewBuilder
    private var recentSection: some View {
        if !progress.quizHistory.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Recent quizzes", systemImage: "clock")
                ForEach(progress.quizHistory.prefix(4), id: \.self) { record in
                    recentRow(record)
                }
            }
        }
    }

    private func recentRow(_ record: QuizRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.isExam == true
                  ? (record.passed == true ? "checkmark.seal.fill" : "xmark.seal.fill")
                  : (record.accuracy >= 0.8 ? "star.fill" : record.accuracy >= 0.6 ? "star.leadinghalf.filled" : "star"))
                .foregroundStyle(record.isExam == true
                                 ? (record.passed == true ? Color.successGreen : Color.errorRed)
                                 : (record.accuracy >= 0.8 ? Color.gold : .secondary))
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.isExam == true ? "Exam · \(record.title)" : "Quiz · \(record.title)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.ink)
                Text(record.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.correctAnswers)/\(record.totalQuestions)")
                .font(.subheadline.bold())
                .foregroundStyle(record.accuracy >= 0.6 ? Color.successGreen : Color.errorRed)
        }
        .padding(12)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}
