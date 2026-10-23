import SwiftUI
import StoreKit
import UserNotifications

enum AppLinks {
    static let website = URL(string: "https://sbf-exam-prep.web.app")!
    static var privacy: URL { URL(string: AppLanguage.isGerman ? "https://sbf-exam-prep.web.app/datenschutz"
                                                              : "https://sbf-exam-prep.web.app/privacy")! }
    static var support: URL { URL(string: AppLanguage.isGerman ? "https://sbf-exam-prep.web.app/hilfe"
                                                              : "https://sbf-exam-prep.web.app/support")! }
    static let elwis = URL(string: "https://www.elwis.de/DE/Sportschifffahrt/Sportbootfuehrerscheine/Sportbootfuehrerscheine-node.html")!
}

struct SettingsView: View {
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var showResetConfirm = false
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack {
            Form {
                learningSection
                reminderSection
                syncSection
                statisticsSection
                questionBankSection
                aboutSection
                Section {
                    Button(role: .destructive) { showResetConfirm = true } label: {
                        Label("Reset all progress", systemImage: "trash")
                    }
                } header: { Text("Data") }
            }
            .scrollContentBackground(.hidden)
            .background(Color.surfaceBG)
            .navigationTitle("Settings")
            .alert("Reset progress?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) { progress.resetProgress() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This erases your quiz history, saved questions, mistakes and review schedule on all devices that use iCloud sync. This cannot be undone.")
            }
            .task { await refreshNotificationStatus() }
        }
    }

    // MARK: Sections

    private var learningSection: some View {
        Section {
            NavigationLink {
                LicenceSettingsView()
            } label: {
                LabeledContent {
                    Text(progress.licenceGoal.summary)
                } label: {
                    Label("My licence", systemImage: "sailboat")
                }
            }
            Toggle(isOn: Binding(get: { progress.showEnglish }, set: { progress.setShowEnglish($0) })) {
                Label("Show English translation", systemImage: "globe")
            }
            Picker(selection: Binding(get: { progress.quizCount }, set: { progress.setQuizCount($0) })) {
                ForEach([10, 20, 30, 50], id: \.self) { Text("\($0)").tag($0) }
            } label: {
                Label("Default quiz length", systemImage: "number.circle")
            }
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                LabeledContent {
                    Text(Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "en") ?? "")
                } label: {
                    Label("App language", systemImage: "character.bubble")
                }
            }
            .foregroundStyle(Color.ink)
        } header: {
            Text("Learning")
        } footer: {
            Text("Exam questions are always shown in German, as in the official exam. The app language can be changed in the system settings.")
        }
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: Binding(get: { progress.reminderEnabled }, set: { setReminder($0) })) {
                Label("Daily reminder", systemImage: "bell.badge")
            }
            if progress.reminderEnabled {
                DatePicker(selection: Binding(get: { reminderDate }, set: { setReminderTime($0) }),
                           displayedComponents: .hourAndMinute) {
                    Label("Time", systemImage: "clock")
                }
            }
            if notificationsDenied {
                Button("Allow notifications in Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("A local notification on this device. No data is sent anywhere.")
        }
    }

    private var syncSection: some View {
        Section {
            Toggle(isOn: Binding(get: { progress.iCloudSyncEnabled }, set: { progress.setICloudSync($0) })) {
                Label("Sync with iCloud", systemImage: "icloud")
            }
        } header: {
            Text("Sync")
        } footer: {
            Text("Keeps your progress in your own iCloud account so it follows you to your other devices. The developer has no access to it.")
        }
    }

    private var statisticsSection: some View {
        Section {
            statRow("Questions answered", value: "\(progress.totalAnswered)")
            statRow("Overall accuracy", value: progress.overallAccuracy.formatted(.percent.precision(.fractionLength(0))))
            statRow("Mastered", value: "\(progress.masteredCount)")
            statRow("Due for review", value: "\(progress.dueCount)")
            statRow("Mistakes to review", value: "\(progress.wrongAnswerCount)")
            statRow("Saved questions", value: "\(progress.bookmarks.count)")
            statRow("Quizzes completed", value: "\(progress.quizHistory.count)")
        } header: { Text("Statistics") }
    }

    private var questionBankSection: some View {
        Section {
            statRow("Basic questions", value: "\(store.specificQuestions(for: .shared).count)")
            statRow("SBF Inland (specific)", value: "\(store.specificQuestions(for: .binnen).count)")
            statRow("SBF Inland · sailing", value: "\(store.specificQuestions(for: .segeln).count)")
            statRow("SBF Sea (specific)", value: "\(store.specificQuestions(for: .see).count)")
            statRow("Total", value: "\(store.allQuestions.count)")
            // Store policies: government information must link to its original source.
            Link(destination: AppLinks.elwis) {
                Label("Official source: elwis.de", systemImage: "arrow.up.right.square")
            }
            .foregroundStyle(Color.ink)
        } header: {
            Text("Question catalogue")
        } footer: {
            Text("Questions from the official ELWIS catalogue (GDWS). Independent study aid, not a government app.")
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About SBF Exam Prep", systemImage: "info.circle")
            }
            Link(destination: AppLinks.support) {
                Label("Help & feedback", systemImage: "questionmark.circle")
            }
            Link(destination: AppLinks.privacy) {
                Label("Privacy policy", systemImage: "hand.raised")
            }
            Button {
                requestReview()
            } label: {
                Label("Rate the app", systemImage: "star")
            }
        } header: {
            Text("About")
        } footer: {
            Text("Version \(appVersion)")
        }
        .foregroundStyle(Color.ink)
    }

    // MARK: Helpers

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func statRow(_ label: LocalizedStringKey, value: String) -> some View {
        LabeledContent(label) {
            Text(value).monospacedDigit().foregroundStyle(Color.inkSecondary)
        }
    }

    private var reminderDate: Date {
        Calendar.current.date(bySettingHour: progress.reminderMinutes / 60, minute: progress.reminderMinutes % 60,
                              second: 0, of: .now) ?? .now
    }

    private func setReminderTime(_ date: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        progress.setReminder(enabled: true, minutes: (c.hour ?? 18) * 60 + (c.minute ?? 0))
    }

    private func setReminder(_ enabled: Bool) {
        guard enabled else { progress.setReminder(enabled: false); return }
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            progress.setReminder(enabled: granted)
            notificationsDenied = !granted
        }
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDenied = settings.authorizationStatus == .denied
        if notificationsDenied && progress.reminderEnabled { progress.setReminder(enabled: false) }
    }
}
