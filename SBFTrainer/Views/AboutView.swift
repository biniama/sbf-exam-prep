import SwiftUI

struct AboutView: View {
    @EnvironmentObject var store: QuestionStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                hero
                card(icon: "book.closed.fill", color: .navyLight, title: "About this app") {
                    Text("SBF Exam Prep helps you prepare for the theory exam of the German recreational boating licence — Sportbootführerschein Binnen (motor and sail) and See.")
                    Text("Every question is shown in German, as in the exam, with an optional English translation.")
                }
                card(icon: "list.bullet.clipboard.fill", color: .oceanTeal, title: "Question catalogue") {
                    row("Basic questions", store.specificQuestions(for: .shared).count)
                    row("SBF Inland (specific)", store.specificQuestions(for: .binnen).count)
                    row("SBF Sea (specific)", store.specificQuestions(for: .see).count)
                    Divider()
                    row("Total", store.allQuestions.count, bold: true)
                    row("Illustrated questions", store.allQuestions.filter(\.hasImage).count)
                }
                card(icon: "star.fill", color: .gold, title: "Features") {
                    feature("checklist", "Practice quizzes with instant feedback")
                    feature("timer", "Exam simulation with the official pass marks")
                    feature("arrow.triangle.2.circlepath", "Spaced repetition and mistake review")
                    feature("speaker.wave.2", "Sound signals you can listen to")
                    feature("icloud", "Progress sync via iCloud")
                }
                card(icon: "doc.text.fill", color: .navyLight, title: "Sources & legal") {
                    Text("Questions and answers: official question catalogue for the Sportbootführerschein, published on ELWIS by the Generaldirektion Wasserstraßen und Schifffahrt (status: August 2023).")
                    Text("Illustrations were drawn for this app following the official figures. English translations are unofficial study aids; only the German text is valid in the exam.")
                    Text("This app is an independent study aid and is not affiliated with or endorsed by the GDWS, ELWIS, the DMYV or the DSV. Always check the current regulations.")
                    Link(destination: AppLinks.elwis) {
                        Label("Official information on ELWIS", systemImage: "arrow.up.right.square")
                    }
                    .font(.subheadline.weight(.semibold))
                    Link(destination: AppLinks.privacy) {
                        Label("Privacy policy", systemImage: "hand.raised")
                    }
                    .font(.subheadline.weight(.semibold))
                    Text("© 2026 SBF Exam Prep")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .readableWidth()
        }
        .background(Color.surfaceBG.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "sailboat.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.gold)
                .frame(width: 96, height: 96)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.navy))
                .accessibilityHidden(true)
            Text("SBF Exam Prep")
                .font(.title2.bold())
                .fontDesign(.rounded)
                .foregroundStyle(Color.ink)
            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func card<Content: View>(icon: String, color: Color, title: LocalizedStringKey,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            VStack(alignment: .leading, spacing: 10) { content() }
                .font(.subheadline)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func row(_ label: LocalizedStringKey, _ count: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label).fontWeight(bold ? .semibold : .regular)
            Spacer()
            Text("\(count)").monospacedDigit().fontWeight(bold ? .bold : .semibold)
        }
    }

    private func feature(_ icon: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon).foregroundStyle(Color.gold)
        }
    }
}
