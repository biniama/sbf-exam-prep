import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var progress: UserProgress
    @State private var page = 0
    @State private var notificationGranted = false

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
                pageIndicator
                    .padding(.bottom, 8)
                nextButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sailboat.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.gold)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 10) {
                Text("SBF Exam Prep")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Sportbootführerschein · Exam Prep")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("Master the German Boating Licence")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text("466 official ELWIS questions · bilingual German/English\nExam simulation · Spaced review · Progress tracking")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private var featuresPage: some View {
        VStack(spacing: 24) {
            Text("Everything You Need")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            VStack(spacing: 16) {
                featureRow(icon: "checkmark.seal.fill", color: .successGreen,
                           title: "Official Questions",
                           body: "All 466 questions from the ELWIS Aug 2023 catalog — Binnen Motor & SBF See")
                featureRow(icon: "timer", color: .gold,
                           title: "Exam Simulation",
                           body: "30-question timed exam mode that matches the real passing threshold (70%)")
                featureRow(icon: "photo.fill", color: .oceanTeal,
                           title: "Diagrams & Signals",
                           body: "141 official navigation signs, light configurations, and sound signal images")
                featureRow(icon: "brain.head.profile", color: Color(red: 0.7, green: 0.4, blue: 0.9),
                           title: "Smart Review",
                           body: "Wrong answers are tracked and surfaced again until you master them")
            }
            .padding(.horizontal, 28)


            Spacer()
        }
        .padding(.top, 60)
        .padding(.bottom, 120)
    }

    private var notificationPage: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.gold)
            }

            VStack(spacing: 10) {
                Text("Stay on Track")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Get a gentle daily reminder at 6 PM to keep your study streak alive.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            Button {
                Task {
                    notificationGranted = await NotificationManager.shared.requestPermission()
                    if notificationGranted {
                        NotificationManager.shared.scheduleDailyReminder()
                    }
                    withAnimation { page = 3 }
                }
            } label: {
                Label("Enable Daily Reminders", systemImage: "bell.fill")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)

            Button("Maybe Later") { withAnimation { page = 3 } }
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.5))

            Spacer()
            Spacer()
        }
    }

    private var languagePage: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: "globe")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.oceanTeal)
            }

            VStack(spacing: 10) {
                Text("Language Preference")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Show English translations below each German question and answer option.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }

            HStack(spacing: 14) {
                langButton(label: "German Only", icon: "textformat.abc", active: !progress.showEnglish) {
                    if progress.showEnglish { progress.toggleEnglish() }
                }
                langButton(label: "Bilingual", icon: "globe", active: progress.showEnglish) {
                    if !progress.showEnglish { progress.toggleEnglish() }
                }
            }
            .padding(.horizontal, 28)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func langButton(label: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(active ? Color.navy : Color.white.opacity(0.7))
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(active ? Color.navy : Color.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(active ? AnyShapeStyle(AppGradient.gold) : AnyShapeStyle(Color.white.opacity(0.1)))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.gold : Color.white.opacity(0.25))
                    .frame(width: i == page ? 20 : 6, height: 6)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }

    private var nextButton: some View {
        Group {
            if page < 2 {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    HStack {
                        Text("Continue")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else if page == 3 {
                Button {
                    UserDefaults.standard.set(true, forKey: "onboardingDone")
                    isPresented = false
                } label: {
                    HStack {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "checkmark")
                    }
                    .foregroundStyle(Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppGradient.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
