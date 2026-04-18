import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var showingQuiz = false
    @StateObject private var quizVM = QuizViewModel()

    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // ── Header ──
                    headerSection
                        .padding(.bottom, 24)

                    // ── Stats ──
                    VStack(spacing: 16) {
                        statsRow
                        studyCalendarSection
                        quickActions
                        reviewSection
                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.surfaceBG.ignoresSafeArea())
            .ignoresSafeArea(edges: .top)
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingQuiz) {
                NavigationStack {
                    QuizView(vm: quizVM)
                }
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        ZStack {
            NavyGradient()
            VStack(spacing: 0) {
                // Wave decoration
                GeometryReader { geo in
                    Path { p in
                        p.move(to: .init(x: 0, y: geo.size.height))
                        p.addCurve(
                            to: .init(x: geo.size.width, y: geo.size.height),
                            control1: .init(x: geo.size.width * 0.3, y: geo.size.height - 30),
                            control2: .init(x: geo.size.width * 0.7, y: geo.size.height + 10)
                        )
                        p.addLine(to: .init(x: geo.size.width, y: 0))
                        p.addLine(to: .init(x: 0, y: 0))
                    }
                    .fill(Color.white.opacity(0.04))
                }
                .frame(height: 40)
            }

            VStack(spacing: 16) {
                Spacer().frame(height: topSafeArea + 20)

                Image(systemName: "sailboat")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.gold)

                Text("SBF Trainer")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Sportbootführerschein Exam Prep")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))

                accuracyRing
                    .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(height: topSafeArea + 300)
    }

    private var accuracyRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
                .frame(width: 110, height: 110)
            Circle()
                .trim(from: 0, to: progress.overallAccuracy)
                .stroke(Color.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 110, height: 110)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress.overallAccuracy)
            VStack(spacing: 2) {
                Text("\(Int(progress.overallAccuracy * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Accuracy")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }

    // MARK: Study Calendar

    private var studyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Study Streak", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Spacer()
                Text("\(progress.dailyStreak) day\(progress.dailyStreak == 1 ? "" : "s")")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(progress.dailyStreak > 0 ? Color.gold.gradient : Color.gray.gradient)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(progress.last7Days, id: \.date) { day in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(day.studied ? Color.gold : Color.navyLight.opacity(0.15))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: day.studied ? "checkmark" : "")
                                    .font(.caption2.bold())
                                    .foregroundStyle(day.studied ? Color.navy : Color.clear)
                            )
                        Text(dayLabel(day.date))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(day.studied ? Color.navy : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
            .cardStyle()
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return String(fmt.string(from: date).prefix(2))
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(progress.totalAnswered)",
                     label: "Answered",
                     icon: "checkmark.circle",
                     color: .successGreen)
            StatCard(value: "\(progress.wrongAnswerCount)",
                     label: "To Review",
                     icon: "exclamationmark.circle",
                     color: .errorRed)
            StatCard(value: "\(progress.currentStreak)",
                     label: "Streak",
                     icon: "flame",
                     color: .gold)
        }
    }

    // MARK: Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.headline)
                .foregroundStyle(Color.navy)

            VStack(spacing: 10) {
                quickActionRow(
                    icon: "play.circle.fill",
                    title: "Quick Quiz",
                    subtitle: "\(progress.quizCount) random questions",
                    color: .navy
                ) {
                    quizVM.setup(type: .all, count: progress.quizCount)
                    showingQuiz = true
                }

                if progress.wrongAnswerCount > 0 {
                    quickActionRow(
                        icon: "arrow.counterclockwise.circle.fill",
                        title: "Review Mistakes",
                        subtitle: "\(progress.wrongAnswerCount) questions to retry",
                        color: .errorRed
                    ) {
                        quizVM.setup(type: .all, count: min(progress.wrongAnswerCount, 30), fromWrong: true)
                        showingQuiz = true
                    }
                }

                quickActionRow(
                    icon: "water.waves",
                    title: "Binnen Motor",
                    subtitle: "\(store.questions(for: .binnen).count) questions · in order",
                    color: .oceanTeal
                ) {
                    quizVM.setup(type: .binnen, count: store.questions(for: .binnen).count, shuffle: false)
                    showingQuiz = true
                }

                quickActionRow(
                    icon: "wind",
                    title: "SBF See",
                    subtitle: "\(store.questions(for: .see).count) questions · in order",
                    color: .navyLight
                ) {
                    quizVM.setup(type: .see, count: store.questions(for: .see).count, shuffle: false)
                    showingQuiz = true
                }
            }
        }
    }

    private func quickActionRow(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.navy)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: Review

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Review Mistakes")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Spacer()
                if progress.wrongAnswerCount > 0 {
                    Text("\(progress.wrongAnswerCount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.errorRed.gradient)
                        .clipShape(Capsule())
                }
            }

            NavigationLink(destination: ReviewView()) {
                HStack(spacing: 14) {
                    Image(systemName: progress.wrongAnswerCount > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background((progress.wrongAnswerCount > 0 ? Color.errorRed : Color.successGreen).gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(progress.wrongAnswerCount > 0 ? "Questions to Review" : "All Clear!")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.navy)
                        Text(progress.wrongAnswerCount > 0
                             ? "\(progress.wrongAnswerCount) missed — swipe to master"
                             : "No wrong answers right now")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .cardStyle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Recent

    private var recentSection: some View {
        Group {
            if !progress.quizHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Quizzes")
                        .font(.headline)
                        .foregroundStyle(Color.navy)

                    ForEach(progress.quizHistory.prefix(3), id: \.date) { record in
                        recentRow(record: record)
                    }
                }
            }
        }
    }

    private func recentRow(record: QuizRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.accuracy >= 0.8 ? "star.fill" : record.accuracy >= 0.6 ? "star.leadinghalf.filled" : "star")
                .foregroundStyle(record.accuracy >= 0.8 ? Color.gold : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.examType)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.navy)
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
    }
}
