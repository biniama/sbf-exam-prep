import SwiftUI

// MARK: - Task list

/// The 15 official navigation tasks of the SBF See (feature flag: navigationTasks).
struct NavigationTasksView: View {
    @StateObject private var nav = NavigationStore.shared
    @EnvironmentObject var flags: FeatureFlags
    @Environment(\.horizontalSizeClass) private var hSize

    private let columns = [GridItem(.adaptive(minimum: 300), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                chartCard
                if flags.isOn(.navigationDrills) {
                    NavigationLink {
                        NavigationDrillsView()
                    } label: {
                        Label("Navigation drills", systemImage: "dial.medium")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .cardStyle()
                    }
                    .buttonStyle(.plain)
                }
                NavigationLink {
                    NavigationGlossaryView()
                } label: {
                    Label("Terms and abbreviations", systemImage: "character.book.closed")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .cardStyle()
                }
                .buttonStyle(.plain)
                SectionHeader(title: "Tasks", systemImage: "map")
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(nav.tasks) { task in
                        NavigationLink { NavigationTaskView(task: task) } label: { taskRow(task) }
                            .buttonStyle(.plain)
                    }
                }
                Text("Source: ELWIS navigation tasks, status August 2023. English translations are unofficial.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .readableWidth(Layout.wideWidth)
        }
        .background(Color.surfaceBG)
        .navigationTitle("Navigation tasks")
    }

    private var chartCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "map.fill")
                .font(.title2)
                .foregroundStyle(Color.gold)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("You need practice chart D49")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text("In the exam the 9 navigation questions are solved on paper chart D49 with a plotting triangle and dividers. The app explains every step and the arithmetic.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func taskRow(_ task: NavigationTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(task.number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.navyLight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text("Task \(task.number)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                Text(task.introDE)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Task detail

struct NavigationTaskView: View {
    let task: NavigationTask
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var flags: FeatureFlags
    @State private var revealed: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                bilingual(task.introDE, task.introEN)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.navyLight.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if let mw = task.values.mw {
                    Label {
                        Text("Variation (Mw) on this chart excerpt: \(signedDegrees(mw))")
                    } icon: {
                        Image(systemName: "safari")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                ForEach(task.steps) { step in
                    stepCard(step)
                }
                if !task.notesDE.isEmpty {
                    bilingual(task.notesDE, task.notesEN)
                        .font(.caption)
                        .padding(12)
                        .background(Color.errorRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                Button(revealed.count == task.steps.count ? "Hide all answers" : "Show all answers") {
                    withAnimation {
                        revealed = revealed.count == task.steps.count ? [] : Set(task.steps.map(\.number))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.surfaceBG)
        .navigationTitle("Task \(task.number)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepCard(_ step: NavigationStep) -> some View {
        let isOpen = revealed.contains(step.number)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(step.number)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.navy)
                    .frame(width: 26, height: 26)
                    .background(Color.gold.opacity(0.35))
                    .clipShape(Circle())
                bilingual(step.questionDE, step.questionEN)
            }
            if step.isPlot {
                Label("Chart work: draw this on chart D49.", systemImage: "pencil.and.ruler")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.oceanTeal)
            }
            if isOpen {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Official result")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.successGreen)
                        bilingual(step.answerDE, step.answerEN, emphasis: true)
                    }
                    if flags.isOn(.navigationDrills), let code = step.code, let light = LightCharacter(code) {
                        LightBeaconView(light: light, size: 70)
                    }
                    if !step.solution.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("How to solve it")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.inkSecondary)
                            ForEach(Array(step.solution.enumerated()), id: \.offset) { _, line in
                                Text(line.localized)
                                    .font(line.localized.contains("=") ? .callout.monospacedDigit().weight(.medium) : .callout)
                                    .foregroundStyle(Color.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.successGreen.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity)
            }
            Button {
                withAnimation(.spring(response: 0.35)) {
                    if isOpen { revealed.remove(step.number) } else { revealed.insert(step.number) }
                }
            } label: {
                Label(isOpen ? "Hide solution" : "Show solution", systemImage: isOpen ? "eye.slash" : "eye")
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    /// German text as in the exam, with the English translation below when enabled.
    @ViewBuilder
    private func bilingual(_ de: String, _ en: String?, emphasis: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(de)
                .font(emphasis ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            if progress.showEnglish, let en, !en.isEmpty {
                Text(en)
                    .font(.footnote.italic())
                    .foregroundStyle(Color.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func signedDegrees(_ v: Double) -> String {
        v == 0 ? "0°" : String(format: "%+.0f°", v)
    }
}

// MARK: - Glossary

struct NavigationGlossaryView: View {
    @StateObject private var nav = NavigationStore.shared

    var body: some View {
        List {
            Section {
                ForEach(nav.catalog?.glossary ?? []) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.abbr).font(.headline.monospaced()).foregroundStyle(Color.navy)
                            Text(AppLanguage.isGerman ? entry.de : "\(entry.de) – \(entry.en)")
                                .font(.subheadline.weight(.semibold))
                        }
                        Text(AppLanguage.isGerman ? entry.explanationDE : entry.explanationEN)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            } footer: {
                Text("Signs: east variation and deviation are positive (+), west negative (−).")
            }
            Section("Exam question types") {
                ForEach(nav.catalog?.questionTypes ?? []) { type in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: "\(type.number). \(type.de)").font(.subheadline)
                        if !AppLanguage.isGerman {
                            Text(type.en).font(.caption.italic()).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Terms and abbreviations")
    }
}
