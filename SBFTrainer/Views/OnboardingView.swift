import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var progress: UserProgress
    @EnvironmentObject var store: QuestionStore
    @State private var page = 0
    private let pageCount = 4

    var body: some View {
        ZStack {
            Color.navy.ignoresSafeArea()

            TabView(selection: $page) {
                welcomePage.tag(0)
                featuresPage.tag(1)
                notificationPage.tag(2)
                languagePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            VStack {
                Spacer()
                pageIndicator.padding(.bottom, 8)
                if page != 2 {
                    nextButton
                        .padding(.horizontal, 28)
                        .padding(.bottom, 40)
                        .frame(maxWidth: 520)
                } else {
                    Color.clear.frame(height: 96)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sailboat.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.gold)
                .symbolEffect(.pulse, options: .repeating)
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text("SBF Exam Prep")
                    .font(.largeTitle.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                Text("Sportbootführerschein Binnen & See")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            VStack(spacing: 8) {
                Text("Pass your German boating licence exam")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("All \(store.allQuestions.count) official questions, exam simulation and spaced repetition.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                // Store policies: government information must link to its original source.
                Text("Questions from the official ELWIS catalogue (GDWS). Independent study aid, not a government app.")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                Link("Official source: elwis.de", destination: AppLinks.elwis)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.goldLight)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: 560)
    }

    private var featuresPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Everything you need")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 18) {
                    featureRow(icon: "checkmark.seal.fill", color: .green, title: "Official questions",
                               body: "The complete ELWIS catalogue (August 2023) for SBF Binnen and SBF See, in German with English translations.")
                    featureRow(icon: "timer", color: .orange, title: "Real exam simulation",
                               body: "7 basic + 23 specific questions with the official pass marks and time limit.")
                    featureRow(icon: "photo.fill", color: .teal, title: "Signs, lights & sound signals",
                               body: "Clear illustrations for every image question — and sound signals you can listen to.")
                    featureRow(icon: "arrow.triangle.2.circlepath", color: .purple, title: "Spaced repetition",
                               body: "Questions come back at growing intervals until you know them for good.")
                }
                .padding(.horizontal, 28)
            }
            .padding(.top, 60)
            .padding(.bottom, 140)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }

    private var notificationPage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.gold)
                .frame(width: 110, height: 110)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text("Stay on track")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Get a daily reminder at 6 pm to keep your streak going. You can change the time or turn it off in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Button {
                Task {
                    let granted = await NotificationManager.shared.requestPermission()
                    progress.setReminder(enabled: granted, minutes: 18 * 60)
                    withAnimation { page = 3 }
                }
            } label: {
                Label("Enable daily reminder", systemImage: "bell.fill")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)
            Button("Not now") { withAnimation { page = 3 } }
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.7))
            Spacer()
            Spacer()
        }
        .frame(maxWidth: 520)
    }

    private var languagePage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "globe")
                .font(.system(size: 52))
                .foregroundStyle(Color.oceanTeal)
                .frame(width: 110, height: 110)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .accessibilityHidden(true)
            VStack(spacing: 10) {
                Text("Translations")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("The exam is in German. Show an English translation below each question and answer?")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            HStack(spacing: 14) {
                langButton(label: "German only", icon: "textformat", active: !progress.showEnglish) {
                    progress.setShowEnglish(false)
                }
                langButton(label: "German + English", icon: "globe", active: progress.showEnglish) {
                    progress.setShowEnglish(true)
                }
            }
            .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, title: LocalizedStringKey, body: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func langButton(label: LocalizedStringKey, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption.weight(.semibold)).multilineTextAlignment(.center)
            }
            .foregroundStyle(active ? Color.navy : Color.white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(active ? AnyShapeStyle(AppGradient.gold) : AnyShapeStyle(Color.white.opacity(0.1)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.gold : Color.white.opacity(0.25))
                    .frame(width: i == page ? 20 : 6, height: 6)
            }
        }
        .animation(.spring(response: 0.3), value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(page + 1) of \(pageCount)"))
    }

    private var nextButton: some View {
        Button {
            if page < pageCount - 1 {
                withAnimation { page += 1 }
            } else {
                UserDefaults.standard.set(true, forKey: "onboardingDone")
                isPresented = false
            }
        } label: {
            HStack {
                Text(page < pageCount - 1 ? "Continue" : "Get started").font(.headline)
                Image(systemName: page < pageCount - 1 ? "arrow.right" : "checkmark")
            }
            .foregroundStyle(Color.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppGradient.gold)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
