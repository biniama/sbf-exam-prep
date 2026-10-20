import SwiftUI

struct AboutView: View {
    @EnvironmentObject var store: QuestionStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroSection
                    .padding(.bottom, 32)

                VStack(spacing: 16) {
                    descriptionCard
                    catalogCard
                    featuresCard
                    legalCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.surfaceBG.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Hero

    private var heroSection: some View {
        ZStack {
            NavyGradient()
            VStack(spacing: 14) {
                Spacer().frame(height: 24)
                Image(uiImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 6)

                Text("SBF Exam Prep")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Sportbootführerschein · Exam Prep")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.75))

                Text("Version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.50))
                    .padding(.top, 2)

                Spacer().frame(height: 20)
            }
        }
        .frame(height: 240)
    }

    // MARK: Cards

    private var descriptionCard: some View {
        aboutCard(icon: "book.closed.fill", iconColor: .navy, title: "About This App") {
            VStack(alignment: .leading, spacing: 10) {
                bilingualRow(
                    de: "SBF Exam Prep hilft dir, die Prüfung zum Sportbootführerschein Binnen Motor und SBF See zu bestehen.",
                    en: "SBF Exam Prep helps you pass the Sportbootführerschein Binnen Motor and SBF See exam."
                )
                Divider()
                bilingualRow(
                    de: "Alle \(store.allQuestions.count) offiziellen ELWIS-Prüfungsfragen mit deutschen und englischen Übersetzungen.",
                    en: "All \(store.allQuestions.count) official ELWIS exam questions with German and English translations."
                )
            }
        }
    }

    private var catalogCard: some View {
        aboutCard(icon: "list.bullet.clipboard.fill", iconColor: .oceanTeal, title: "Question Catalog") {
            VStack(spacing: 8) {
                catalogRow("Shared (Basisfragen)", count: store.questions(for: .shared).count, color: .gold)
                catalogRow("Binnen Motor (specific)", count: store.questions(for: .binnen).count - store.questions(for: .shared).count, color: .oceanTeal)
                catalogRow("SBF See (specific)", count: store.questions(for: .see).count, color: .navy)
                Divider()
                    .padding(.vertical, 2)
                HStack {
                    Text("Total")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.navy)
                    Spacer()
                    Text("\(store.allQuestions.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.navy)
                }
            }
        }
    }

    private var featuresCard: some View {
        aboutCard(icon: "star.fill", iconColor: .gold, title: "Features") {
            VStack(alignment: .leading, spacing: 10) {
                featureRow("checklist", "Randomised quizzes with instant feedback", color: .navy)
                featureRow("globe", "Bilingual German / English", color: .oceanTeal)
                featureRow("photo.fill", "103+ official ELWIS diagrams & signals", color: .navyMid)
                featureRow("bookmark.fill", "Bookmarks & wrong-answer review", color: .gold)
                featureRow("chart.bar.fill", "Progress tracking & quiz history", color: .successGreen)
            }
        }
    }

    private var legalCard: some View {
        aboutCard(icon: "doc.text.fill", iconColor: .navyLight, title: "Data Source & Legal") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.successGreen)
                        .font(.subheadline)
                    Text("Question catalog sourced from the official **ELWIS** (Elektronischer Wasserstraßen-Informationsservice) August 2023 publication by the Generaldirektion Wasserstraßen und Schifffahrt (GDWS), Germany.")
                        .font(.caption)
                        .foregroundStyle(Color.navyMid)
                }
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color.navyLight)
                        .font(.subheadline)
                    Text("This app is an independent study tool and is not affiliated with or endorsed by GDWS, ELWIS, or the DMYV. Always verify current exam regulations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Divider()
                HStack {
                    Text("© 2024 SBF Exam Prep")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Catalog: Aug 2023")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Helpers

    private func aboutCard<Content: View>(icon: String, iconColor: Color, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.navy)
            }
            content()
        }
        .padding(16)
        .cardStyle()
    }

    private func bilingualRow(de: String, en: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(de)
                .font(.subheadline)
                .foregroundStyle(Color.navy)
            Text(en)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()
        }
    }

    private func catalogRow(_ label: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.navyMid)
            Spacer()
            Text("\(count)")
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
    }

    private func featureRow(_ icon: String, _ text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.navyMid)
        }
    }

    // MARK: Utilities

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appIcon: UIImage {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let img = UIImage(named: name) {
            return img
        }
        return UIImage(systemName: "sailboat.fill") ?? UIImage()
    }
}
