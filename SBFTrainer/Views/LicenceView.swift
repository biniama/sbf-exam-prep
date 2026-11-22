import SwiftUI

/// "My licence": which licences the learner is preparing for. Used in Settings and as a sheet from Home.
struct LicenceSettingsView: View {
    @EnvironmentObject var progress: UserProgress
    @Environment(\.dismiss) private var dismiss
    /// Shown as a sheet (from Home): adds a Done button and saves the default choice too.
    var isSheet = false

    var body: some View {
        Form {
            Section {
                Picker(selection: inlandBinding) {
                    ForEach(LicenceGoal.Inland.allCases) { option in
                        Text(option.title).tag(option)
                    }
                } label: {
                    Label("SBF Inland", systemImage: "water.waves")
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("SBF Inland")
            } footer: {
                Text("The sailing licence for inland waters has its own exam with 7 extra sailing questions.")
            }
            Section {
                Toggle(isOn: seaBinding) {
                    Label("SBF Sea", systemImage: "wind")
                }
                .disabled(progress.licenceGoal.inland == .none)
            } footer: {
                Text("Your choice decides which exam simulations are offered. All questions stay available for practice.")
            }
            Section {
                ForEach(progress.licenceGoal.examFormats) { format in
                    LabeledContent {
                        Text(ExamRules(format: format).summary).font(.caption).foregroundStyle(.secondary)
                    } label: {
                        Label(format.title, systemImage: format.icon)
                    }
                }
            } header: {
                Text("Exam simulations")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.surfaceBG)
        .navigationTitle("My licence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        progress.setLicenceGoal(progress.licenceGoal)
                        dismiss()
                    }
                }
            }
        }
    }

    private var inlandBinding: Binding<LicenceGoal.Inland> {
        Binding {
            progress.licenceGoal.inland
        } set: { value in
            var goal = progress.licenceGoal
            goal.inland = value
            if value == .none { goal.sea = true }
            progress.setLicenceGoal(goal)
        }
    }

    private var seaBinding: Binding<Bool> {
        Binding {
            progress.licenceGoal.sea
        } set: { value in
            var goal = progress.licenceGoal
            goal.sea = value
            progress.setLicenceGoal(goal)
        }
    }
}

/// Onboarding page: pick the licence in a few taps.
struct LicenceOnboardingPage: View {
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "sailboat")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.gold)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .accessibilityHidden(true)
                VStack(spacing: 8) {
                    Text("Which licence are you taking?")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("This decides which exam simulations you get. You can change it any time in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("SBF Inland")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                    ForEach(LicenceGoal.Inland.allCases) { option in
                        choiceRow(option.title, active: progress.licenceGoal.inland == option) {
                            var goal = progress.licenceGoal
                            goal.inland = option
                            if option == .none { goal.sea = true }
                            progress.setLicenceGoal(goal)
                        }
                    }
                    Text("SBF Sea")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .padding(.top, 8)
                    choiceRow(String(localized: "Also preparing for SBF Sea"), active: progress.licenceGoal.sea,
                              checkbox: true) {
                        var goal = progress.licenceGoal
                        goal.sea.toggle()
                        progress.setLicenceGoal(goal)
                    }
                    .disabled(progress.licenceGoal.inland == .none)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 150)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private func choiceRow(_ title: String, active: Bool, checkbox: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: checkbox ? (active ? "checkmark.square.fill" : "square")
                                           : (active ? "largecircle.fill.circle" : "circle"))
                    .font(.title3)
                    .foregroundStyle(active ? Color.gold : Color.white.opacity(0.5))
                Text(title)
                    .font(.subheadline.weight(active ? .semibold : .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(active ? Color.gold.opacity(0.18) : Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}
