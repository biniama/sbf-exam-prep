import AVFoundation
import SwiftUI

/// Draws a solution diagram up to a frame: lat/long grid, course and bearing lines, positions.
struct NavigationDiagramCanvas: View {
    let diagram: NavigationDiagram
    /// Elements visible so far and the ones added in the current frame (highlighted).
    let visible: Set<String>
    let highlighted: Set<String>

    var body: some View {
        Canvas { context, size in
            let margin: CGFloat = 46
            let scale = min((size.width - 2 * margin) / max(diagram.width, 1), (size.height - 2 * margin) / max(diagram.height, 1))
            func p(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: size.width / 2 + x * scale, y: size.height / 2 - y * scale)
            }
            drawGrid(context, size: size, scale: scale, point: p)
            var labels: [LabelRequest] = []
            for e in diagram.elements where e.type == "line" && visible.contains(e.id) {
                let a = p(e.x1 ?? 0, e.y1 ?? 0), b = p(e.x2 ?? 0, e.y2 ?? 0), hl = highlighted.contains(e.id)
                drawLine(context, e, a, b, hl)
                if let label = e.localizedLabel {
                    labels.append(LabelRequest(text: label, anchor: CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2),
                                               color: lineColor(e.style), bold: hl, gap: 6))
                }
            }
            var occupied = [CGRect(x: size.width - 36, y: 14, width: 28, height: 40)]  // north arrow
            for e in diagram.elements where e.type == "point" && visible.contains(e.id) {
                let c = p(e.x ?? 0, e.y ?? 0), hl = highlighted.contains(e.id)
                drawPoint(context, e, c, hl)
                occupied.append(CGRect(x: c.x - 9, y: c.y - 9, width: 18, height: 18))
                let text = [e.localizedLabel, e.sub].compactMap { $0 }.joined(separator: " ")
                if !text.isEmpty { labels.append(LabelRequest(text: text, anchor: c, color: Color.navy, bold: hl, gap: 10)) }
            }
            drawNorthArrow(context, at: CGPoint(x: size.width - 22, y: 30))
            // Labels of the current step get the best spots and are drawn on top.
            let placed = (labels.filter(\.bold) + labels.filter { !$0.bold }).map {
                placeLabel(context, $0, in: size, avoiding: &occupied)
            }
            for (box, text) in placed.reversed() {
                context.fill(Path(roundedRect: box, cornerRadius: 4), with: .color(Color.white.opacity(0.88)))
                context.draw(text, at: CGPoint(x: box.minX + 3, y: box.midY), anchor: .leading)
            }
        }
        .background(Color(red: 0.93, green: 0.96, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Solution diagram"))
    }

    private func drawGrid(_ context: GraphicsContext, size: CGSize, scale: Double, point: (Double, Double) -> CGPoint) {
        let gridColor = Color(red: 0.78, green: 0.85, blue: 0.91)
        let labelColor = Color(red: 0.42, green: 0.52, blue: 0.62)
        let g = diagram.grid
        let halfW = size.width / 2 / scale, halfH = size.height / 2 / scale
        // One line per minute of latitude / longitude; labels only as often as they fit.
        let step = scale > 30 ? 1 : 2
        let latEvery = labelInterval(spacing: scale, needed: 22)
        let lonEvery = labelInterval(spacing: scale * g.k, needed: 46)
        let lat0 = (g.lat * 60).rounded(.down)
        for i in stride(from: -40, through: 40, by: step) {
            let latMin = lat0 + Double(i)
            let y = latMin - g.lat * 60
            guard abs(y) < halfH else { continue }
            let a = point(-halfW, y), b = point(halfW, y)
            context.stroke(Path { $0.move(to: a); $0.addLine(to: b) }, with: .color(gridColor), lineWidth: 0.7)
            guard Int(latMin) % latEvery == 0, a.y > 16, a.y < size.height - 20 else { continue }
            context.draw(Text(minutesLabel(latMin, hemisphere: "N")).font(.system(size: 9)).foregroundStyle(labelColor),
                         at: CGPoint(x: 4, y: a.y - 6), anchor: .leading)
        }
        let lon0 = (g.lon * 60).rounded(.down)
        for i in stride(from: -60, through: 60, by: step) {
            let lonMin = lon0 + Double(i)
            let x = (lonMin - g.lon * 60) * g.k
            guard abs(x) < halfW else { continue }
            let a = point(x, -halfH), b = point(x, halfH)
            context.stroke(Path { $0.move(to: a); $0.addLine(to: b) }, with: .color(gridColor), lineWidth: 0.7)
            guard Int(lonMin) % lonEvery == 0, a.x < size.width - 40 else { continue }
            context.draw(Text(minutesLabel(lonMin, hemisphere: "E")).font(.system(size: 9)).foregroundStyle(labelColor),
                         at: CGPoint(x: a.x + 2, y: size.height - 8), anchor: .leading)
        }
    }

    /// Smallest of 1, 2, 5, 10 minutes whose labels are at least `needed` points apart.
    private func labelInterval(spacing: Double, needed: Double) -> Int {
        [1, 2, 5, 10].first { Double($0) * spacing >= needed } ?? 10
    }

    private func minutesLabel(_ totalMinutes: Double, hemisphere: String) -> String {
        let deg = Int(totalMinutes / 60)
        let min = Int(totalMinutes) - deg * 60
        return "\(deg)°\(String(format: "%02d", min))'"
    }

    private func lineColor(_ style: String) -> Color {
        switch style {
        case "course":    return Color.navy
        case "bearing":   return Color.oceanTeal
        case "set_drift": return Color.errorRed
        default:          return .gray
        }
    }

    private func drawLine(_ context: GraphicsContext, _ e: NavigationDiagram.Element, _ a: CGPoint, _ b: CGPoint, _ hl: Bool) {
        let color = lineColor(e.style)
        var style = StrokeStyle(lineWidth: hl ? 3.5 : 2.5, lineCap: .round)
        switch e.style {
        case "course", "set_drift": break
        case "bearing": style.dash = [7, 5]
        default:        style.dash = [2, 4]
        }
        context.stroke(Path { $0.move(to: a); $0.addLine(to: b) }, with: .color(color), style: style)
        if e.style == "course" || e.style == "set_drift" || e.style == "track" {
            let angle = atan2(b.y - a.y, b.x - a.x)
            var head = Path()
            head.move(to: b)
            head.addLine(to: CGPoint(x: b.x - 11 * cos(angle - 0.4), y: b.y - 11 * sin(angle - 0.4)))
            head.move(to: b)
            head.addLine(to: CGPoint(x: b.x - 11 * cos(angle + 0.4), y: b.y - 11 * sin(angle + 0.4)))
            context.stroke(head, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func drawPoint(_ context: GraphicsContext, _ e: NavigationDiagram.Element, _ c: CGPoint, _ hl: Bool) {
        let r: CGFloat = hl ? 7.5 : 6
        let rect = CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
        switch e.style {
        case "mark":
            var diamond = Path()
            diamond.move(to: CGPoint(x: c.x, y: c.y - r - 1))
            diamond.addLine(to: CGPoint(x: c.x + r, y: c.y))
            diamond.addLine(to: CGPoint(x: c.x, y: c.y + r + 1))
            diamond.addLine(to: CGPoint(x: c.x - r, y: c.y))
            diamond.closeSubpath()
            context.fill(diamond, with: .color(Color.gold))
            context.stroke(diamond, with: .color(Color.navy), lineWidth: 1)
        case "dr":
            context.fill(Path(rect), with: .color(.white))
            context.stroke(Path(rect), with: .color(Color.navy), lineWidth: 2)
        case "fix":
            context.stroke(Path(ellipseIn: rect), with: .color(Color.errorRed), lineWidth: 2.5)
            context.fill(Path(ellipseIn: rect.insetBy(dx: r * 0.6, dy: r * 0.6)), with: .color(Color.errorRed))
        default:
            var triangle = Path()
            triangle.move(to: CGPoint(x: c.x, y: c.y - r - 1))
            triangle.addLine(to: CGPoint(x: c.x + r, y: c.y + r))
            triangle.addLine(to: CGPoint(x: c.x - r, y: c.y + r))
            triangle.closeSubpath()
            context.fill(triangle, with: .color(Color.successGreen))
        }
    }

    private struct LabelRequest {
        let text: String
        let anchor: CGPoint
        let color: Color
        let bold: Bool
        /// Distance from the anchor: larger for point symbols.
        let gap: CGFloat
    }

    /// Finds the first spot around the label's anchor that stays on the canvas and is free,
    /// moving further away step by step when the close spots are taken.
    private func placeLabel(_ context: GraphicsContext, _ label: LabelRequest, in size: CGSize,
                            avoiding occupied: inout [CGRect]) -> (CGRect, GraphicsContext.ResolvedText) {
        let resolved = context.resolve(Text(label.text).font(.system(size: 11, weight: label.bold ? .bold : .medium))
            .foregroundStyle(label.color))
        let text = resolved.measure(in: CGSize(width: 220, height: 40))
        let w = text.width + 6, h = text.height + 2
        let a = label.anchor, g = label.gap
        let near = [
            CGPoint(x: a.x + g, y: a.y - h - 3), CGPoint(x: a.x - g - w, y: a.y - h - 3),
            CGPoint(x: a.x + g, y: a.y + 3), CGPoint(x: a.x - g - w, y: a.y + 3),
            CGPoint(x: a.x - w / 2, y: a.y - h - g), CGPoint(x: a.x - w / 2, y: a.y + g),
        ]
        var farther: [CGPoint] = []
        for k in 1...4 {
            let dy = CGFloat(k) * (h + 2)
            for o in near.prefix(4) {
                farther.append(CGPoint(x: o.x, y: o.y - dy))
                farther.append(CGPoint(x: o.x, y: o.y + dy))
            }
        }
        let bounds = CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3)
        let candidates = (near + farther).map { CGRect(origin: $0, size: CGSize(width: w, height: h)) }
        let inside = candidates.filter { bounds.contains($0) }
        var box = inside.first { r in !occupied.contains { $0.intersects(r) } } ?? inside.first ?? candidates[0]
        box.origin.x = min(max(box.minX, bounds.minX), bounds.maxX - w)
        box.origin.y = min(max(box.minY, bounds.minY), bounds.maxY - h)
        occupied.append(box)
        return (box, resolved)
    }

    private func drawNorthArrow(_ context: GraphicsContext, at c: CGPoint) {
        var arrow = Path()
        arrow.move(to: CGPoint(x: c.x, y: c.y - 12))
        arrow.addLine(to: CGPoint(x: c.x + 6, y: c.y + 6))
        arrow.addLine(to: CGPoint(x: c.x, y: c.y + 2))
        arrow.addLine(to: CGPoint(x: c.x - 6, y: c.y + 6))
        arrow.closeSubpath()
        context.fill(arrow, with: .color(Color.navy))
        context.draw(Text(verbatim: "N").font(.system(size: 10, weight: .bold)).foregroundStyle(Color.navy), at: CGPoint(x: c.x, y: c.y + 16))
    }
}

/// Speaks the frame texts with the system voice in the app language.
@MainActor
final class DiagramNarrator: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isSpeaking = false
    var onFinish: (() -> Void)?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AppLanguage.isGerman ? "de-DE" : "en-GB")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.onFinish?()
        }
    }
}

/// Step-by-step solution diagram with optional narration (feature flag navigationDiagrams).
struct NavigationDiagramView: View {
    let task: NavigationTask
    let diagram: NavigationDiagram
    @State private var frame = 0
    @State private var autoPlay = false
    @StateObject private var narrator = DiagramNarrator()
    @AppStorage("diagramNarration") private var narration = true
    @Environment(\.horizontalSizeClass) private var hSize

    private var current: NavigationDiagram.Frame { diagram.frames[frame] }
    private var visible: Set<String> { Set(diagram.frames[0...frame].flatMap(\.show)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                NavigationDiagramCanvas(diagram: diagram, visible: visible, highlighted: Set(current.show))
                    .frame(height: hSize == .regular ? 460 : 340)
                    .animation(.easeInOut(duration: 0.3), value: frame)
                HStack {
                    Text("Step \(frame + 1) of \(diagram.frames.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let step = current.step {
                        Text("· Question \(step)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle(isOn: $narration) {
                        Label("Read aloud", systemImage: "speaker.wave.2")
                    }
                    .toggleStyle(.button)
                    .font(.caption)
                }
                // Controls above the caption so they stay in place while the text length changes.
                HStack(spacing: 12) {
                    Button { go(frame - 1) } label: {
                        Label("Back", systemImage: "chevron.left").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(frame == 0)
                    Button { autoPlay.toggle(); if autoPlay { speakOrAdvance() } else { narrator.stop() } } label: {
                        Image(systemName: autoPlay ? "pause.fill" : "play.fill").frame(width: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(Text(autoPlay ? "Pause" : "Play"))
                    Button { go(frame + 1) } label: {
                        Label("Next", systemImage: "chevron.right").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(frame == diagram.frames.count - 1)
                }
                Text(current.localized)
                    .font(.body)
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .cardStyle()
                Text("Drawn from the official results – not a reproduction of chart D49.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.surfaceBG)
        .navigationTitle("Task \(task.number) · diagram")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            narrator.onFinish = { if autoPlay { advanceAfterPause() } }
        }
        .onDisappear { narrator.stop() }
    }

    private func go(_ index: Int) {
        guard diagram.frames.indices.contains(index) else { return }
        frame = index
        if narration { narrator.speak(current.localized) } else { narrator.stop() }
    }

    private func speakOrAdvance() {
        if narration {
            narrator.speak(current.localized)
        } else {
            advanceAfterPause()
        }
    }

    private func advanceAfterPause() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: narration ? 800_000_000 : 4_000_000_000)
            guard autoPlay else { return }
            if frame < diagram.frames.count - 1 {
                go(frame + 1)
                if !narration { advanceAfterPause() }
            } else {
                autoPlay = false
            }
        }
    }
}
