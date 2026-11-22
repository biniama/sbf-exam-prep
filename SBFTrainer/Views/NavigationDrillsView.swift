import SwiftUI

/// A light flashing in its real rhythm (feature flag navigationDrills).
struct LightBeaconView: View {
    let light: LightCharacter
    var size: CGFloat = 90
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSince(start)
            let on = light.isOn(at: t)
            let progress = t.truncatingRemainder(dividingBy: max(light.period, 0.1)) / max(light.period, 0.1)
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(on ? color : Color.white.opacity(0.06))
                        .frame(width: size * 0.42, height: size * 0.42)
                        .shadow(color: on ? color.opacity(0.9) : .clear, radius: size * 0.3)
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: size * 0.42, height: size * 0.42)
                }
                .frame(width: size, height: size)
                GeometryReader { geo in
                    Capsule().fill(Color.white.opacity(0.15))
                        .overlay(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.6)).frame(width: geo.size.width * progress)
                        }
                }
                .frame(width: size * 1.6, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.navy)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Animated light"))
        .onAppear { start = Date() }
    }

    private var color: Color {
        switch light.colour {
        case .white:  return .white
        case .red:    return Color(red: 1, green: 0.25, blue: 0.25)
        case .green:  return Color(red: 0.3, green: 1, blue: 0.45)
        case .yellow: return Color(red: 1, green: 0.85, blue: 0.2)
        }
    }
}

/// Unlimited practice for the arithmetic of the navigation task.
struct NavigationDrillsView: View {
    @State private var kind: NavigationDrill.Kind = .course
    @State private var drill = NavigationDrill.make(.course)
    @State private var input = ""
    @State private var picked: LightCharacter?
    @State private var result: Bool?
    @State private var correctCount = 0
    @State private var answeredCount = 0
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Drill", selection: $kind) {
                    ForEach(NavigationDrill.Kind.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(Color.ink)

                if answeredCount > 0 {
                    Text("\(correctCount) of \(answeredCount) correct")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Label(drill.kind.title, systemImage: drill.kind.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.inkSecondary)
                    if let light = drill.light {
                        LightBeaconView(light: light)
                    }
                    Text(drill.prompt)
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if drill.kind == .light {
                        choices
                    } else {
                        HStack {
                            TextField(drill.isClock ? String(localized: "hh:mm") : String(localized: "Answer"), text: $input)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.roundedBorder)
                                .focused($focused)
                                .onSubmit(check)
                                .disabled(result != nil)
                                .frame(maxWidth: 160)
                            if !drill.unit.isEmpty { Text(drill.unit).foregroundStyle(.secondary) }
                        }
                    }
                    if let result {
                        feedback(result)
                    }
                }
                .padding(18)
                .cardStyle()

                Button(action: result == nil ? check : next) {
                    Label(result == nil ? "Check" : "Next exercise", systemImage: result == nil ? "checkmark" : "arrow.right")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppGradient.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(result == nil && drill.kind != .light && input.isEmpty)
                .disabled(result == nil && drill.kind == .light && picked == nil)
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.surfaceBG)
        .navigationTitle("Navigation drills")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: kind) { _, new in
            drill = NavigationDrill.make(new)
            reset()
        }
    }

    private var choices: some View {
        VStack(spacing: 8) {
            ForEach(drill.choices, id: \.code) { choice in
                let isPicked = picked == choice
                let reveal = result != nil
                Button {
                    guard result == nil else { return }
                    picked = choice
                } label: {
                    HStack {
                        Text(choice.notation).font(.body.monospaced().weight(.semibold))
                        Spacer()
                        if reveal && choice == drill.light {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.successGreen)
                        } else if reveal && isPicked {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.errorRed)
                        }
                    }
                    .foregroundStyle(Color.ink)
                    .padding(12)
                    .background(isPicked ? Color.gold.opacity(0.2) : Color.navyLight.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func feedback(_ correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(correct ? "Correct" : "Not quite", systemImage: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(correct ? Color.successGreen : Color.errorRed)
            ForEach(drill.solution, id: \.self) { line in
                Text(line)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((correct ? Color.successGreen : Color.errorRed).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func check() {
        guard result == nil else { return }
        let ok: Bool
        if drill.kind == .light {
            guard let picked else { return }
            ok = drill.check(choice: picked)
        } else {
            guard !input.isEmpty else { return }
            ok = drill.check(input)
        }
        result = ok
        answeredCount += 1
        if ok { correctCount += 1 }
        focused = false
    }

    private func next() {
        drill = NavigationDrill.make(kind)
        reset()
    }

    private func reset() {
        input = ""
        picked = nil
        result = nil
    }
}
