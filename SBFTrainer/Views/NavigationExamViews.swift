import SwiftUI

/// Navigation part of the See exam simulation: one task, typed answers, no feedback until the end.
struct NavigationExamView: View {
    @ObservedObject var part: NavigationExamPart
    let onFinish: () -> Void
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Navigation task \(part.task.number)", systemImage: "map.fill")
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                    Text("Work on chart D49 and type your results. Chart work and descriptions are compared with the official result at the end.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(part.task.introDE).font(.subheadline).foregroundStyle(Color.ink)
                    if progress.showEnglish, let en = part.task.introEN {
                        Text(en).font(.footnote.italic()).foregroundStyle(Color.inkSecondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.navyLight.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                ForEach(part.task.steps) { step in
                    stepInput(step)
                }

                Button(action: onFinish) {
                    Label("Finish and see result", systemImage: "checkmark.seal")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppGradient.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Text("Practice tolerance for typed answers: ±\(Int(part.tolerances.degrees))° for courses and bearings, ±\(formatted(part.tolerances.nm)) nm, ±\(Int(part.tolerances.minutes)) min, ±\(formatted(part.tolerances.arcMinutes))' for positions. ELWIS publishes no official tolerances.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .readableWidth()
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.surfaceBG)
    }

    private func stepInput(_ step: NavigationStep) -> some View {
        let fields = NavigationField.fields(for: step)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(step.number)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(Color.navy)
                    .frame(width: 26, height: 26)
                    .background(Color.gold.opacity(0.35))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.questionDE).font(.subheadline).foregroundStyle(Color.ink)
                    if progress.showEnglish, let en = step.questionEN {
                        Text(en).font(.footnote.italic()).foregroundStyle(Color.inkSecondary)
                    }
                }
            }
            if step.isPlot {
                Label("Chart work: draw this on chart D49.", systemImage: "pencil.and.ruler")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.oceanTeal)
            }
            // Two fields per row so positions (4 fields) and cross bearings fit on a phone.
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(stride(from: 0, to: fields.count, by: 2)), id: \.self) { start in
                    HStack(spacing: 8) {
                        ForEach(start..<min(start + 2, fields.count), id: \.self) { index in
                            let field = fields[index]
                            TextField(placeholder(field), text: binding(step.number, index))
                                .keyboardType(field == .text ? .default : .numbersAndPunctuation)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: field == .text ? .infinity : 110)
                                .accessibilityLabel(Text(placeholder(field)))
                            if let unit = unit(field) {
                                Text(unit).font(.callout).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func binding(_ number: Int, _ index: Int) -> Binding<String> {
        Binding {
            part.inputs[number]?[safe: index] ?? ""
        } set: { value in
            var values = part.inputs[number] ?? []
            while values.count <= index { values.append("") }
            values[index] = value
            part.inputs[number] = values
        }
    }

    private func placeholder(_ field: NavigationField) -> String {
        switch field {
        case .degrees(let label):  return label.isEmpty ? String(localized: "Degrees") : String(localized: "Bearing \(label)")
        case .nauticalMiles:      return String(localized: "Distance")
        case .minutes:            return String(localized: "Minutes")
        case .knots:              return String(localized: "Speed")
        case .clock:              return String(localized: "hh:mm")
        case .latitudeDegrees:    return String(localized: "Lat °")
        case .latitudeMinutes:    return String(localized: "Lat '")
        case .longitudeDegrees:   return String(localized: "Long °")
        case .longitudeMinutes:   return String(localized: "Long '")
        case .text:               return String(localized: "Your answer (optional)")
        }
    }

    private func unit(_ field: NavigationField) -> String? {
        switch field {
        case .degrees, .latitudeDegrees, .longitudeDegrees: return "°"
        case .nauticalMiles: return String(localized: "nm")
        case .minutes: return "min"
        case .knots: return "kn"
        case .latitudeMinutes: return "' N"
        case .longitudeMinutes: return "' E"
        case .clock, .text: return nil
        }
    }

    private func formatted(_ v: Double) -> String { v.formatted(.number.precision(.fractionLength(0...1))) }
}

/// Result of the navigation part with self-grading for chart work and descriptions.
struct NavigationExamReview: View {
    @ObservedObject var part: NavigationExamPart
    let onRegrade: () -> Void
    @EnvironmentObject var progress: UserProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Navigation task \(part.task.number)", systemImage: "map")
            if !part.needsSelfGrading.isEmpty {
                Text("Compare your chart work and descriptions with the official result and mark them yourself.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(part.task.steps) { step in
                row(step)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func row(_ step: NavigationStep) -> some View {
        let auto = part.autoResult(step)
        let correct = part.isCorrect(step)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: correct ? "checkmark.circle.fill" : (auto == nil && part.selfGrades[step.number] == nil ? "circle.dashed" : "xmark.circle.fill"))
                    .foregroundStyle(correct ? Color.successGreen : (auto == nil && part.selfGrades[step.number] == nil ? Color.inkSecondary : Color.errorRed))
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: "\(step.number). \(step.questionDE)").font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    let given = (part.inputs[step.number] ?? []).filter { !$0.isEmpty }.joined(separator: " · ")
                    if !given.isEmpty {
                        Text("Your answer: \(given)").font(.subheadline).foregroundStyle(Color.ink)
                    }
                    Text("Official: \(step.answerDE)").font(.subheadline.weight(.semibold)).foregroundStyle(Color.ink)
                    if progress.showEnglish, let en = step.answerEN {
                        Text(en).font(.caption.italic()).foregroundStyle(Color.inkSecondary)
                    }
                }
            }
            if auto == nil {
                HStack(spacing: 10) {
                    gradeButton(step, true)
                    gradeButton(step, false)
                }
                .padding(.leading, 28)
            }
        }
    }

    private func gradeButton(_ step: NavigationStep, _ value: Bool) -> some View {
        let selected = part.selfGrades[step.number] == value
        return Button {
            part.selfGrades[step.number] = value
            onRegrade()
        } label: {
            Label(value ? "I had it right" : "Wrong", systemImage: value ? "checkmark" : "xmark")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(selected ? .white : (value ? Color.successGreen : Color.errorRed))
                .background(selected ? (value ? Color.successGreen : Color.errorRed) : Color.clear)
                .overlay(Capsule().stroke(value ? Color.successGreen : Color.errorRed, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
