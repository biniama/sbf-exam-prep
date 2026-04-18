import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // Learning preferences
                Section {
                    Toggle(isOn: Binding(
                        get: { progress.showEnglish },
                        set: { _ in progress.toggleEnglish() }
                    )) {
                        Label("Show English Translation", systemImage: "globe")
                    }
                    .tint(Color.navy)

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Default Quiz Length", systemImage: "number.circle")
                        HStack(spacing: 10) {
                            ForEach([10, 20, 30, 50], id: \.self) { n in
                                Button {
                                    progress.setQuizCount(n)
                                } label: {
                                    Text("\(n)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(progress.quizCount == n ? .white : Color.navyMid)
                                        .frame(width: 46, height: 36)
                                        .background(progress.quizCount == n ? Color.navy : Color.navyLight.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Learning") }

                // Statistics
                Section {
                    statRow("Total Questions Answered", value: "\(progress.totalAnswered)")
                    statRow("Overall Accuracy", value: "\(Int(progress.overallAccuracy * 100))%")
                    statRow("Questions to Review", value: "\(progress.wrongAnswerCount)")
                    statRow("Bookmarked Questions", value: "\(progress.bookmarks.count)")
                    statRow("Quizzes Completed", value: "\(progress.quizHistory.count)")
                } header: { Text("Statistics") }

                // Question counts
                Section {
                    statRow("Total Questions", value: "\(store.allQuestions.count)")
                    statRow("Shared (Basisfragen)", value: "\(store.questions(for: .shared).count)")
                    statRow("Binnen Motor", value: "\(store.questions(for: .binnen).count)")
                    statRow("SBF See", value: "\(store.questions(for: .see).count)")
                } header: { Text("Question Bank") }

                // About
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("About SBF Trainer")
                                    .foregroundStyle(Color.primary)
                                Text("Version \(appVersion) · ELWIS 2023")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.navyLight)
                        }
                    }
                } header: { Text("About") }

                // Danger zone
                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Progress", systemImage: "trash")
                            .foregroundStyle(Color.errorRed)
                    }
                } header: { Text("Data") }
            }
            .navigationTitle("Settings")
            .alert("Reset Progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { progress.resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will erase all quiz history, bookmarks, and wrong answer tracking. This cannot be undone.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.primary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.navyMid)
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
