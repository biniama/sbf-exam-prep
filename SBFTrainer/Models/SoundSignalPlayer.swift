import AVFoundation
import SwiftUI

/// Plays sound signals (short ≈ 1 s, prolonged ≈ 4 s blasts) with a synthesised horn.
///
/// Pattern syntax: "." short blast, "-" prolonged blast, " " pause between groups.
@MainActor
final class SoundSignalPlayer: ObservableObject {
    static let shared = SoundSignalPlayer()

    @Published private(set) var playingPattern: String?
    /// Index (into the pattern string) of the blast that is currently sounding.
    @Published private(set) var activeIndex: Int?

    static let shortSeconds = 1.0
    static let longSeconds = 4.0
    static let gapSeconds = 1.0
    static let pauseSeconds = 2.5

    private let engine = AVAudioEngine()
    private let node = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var progressTask: Task<Void, Never>?
    private var configured = false

    struct Segment: Equatable {
        let index: Int
        let start: Double
        let duration: Double
    }

    /// Timeline of the blasts in a pattern (pure, used by the UI and tests).
    static func timeline(for pattern: String) -> (segments: [Segment], total: Double) {
        var t = 0.0
        var segments: [Segment] = []
        for (i, ch) in pattern.enumerated() {
            switch ch {
            case ".":
                segments.append(Segment(index: i, start: t, duration: shortSeconds)); t += shortSeconds + gapSeconds
            case "-":
                segments.append(Segment(index: i, start: t, duration: longSeconds)); t += longSeconds + gapSeconds
            case " ":
                t += pauseSeconds - gapSeconds
            default:
                continue
            }
        }
        return (segments, max(0, t - gapSeconds))
    }

    func toggle(_ pattern: String) {
        if playingPattern == pattern { stop() } else { play(pattern) }
    }

    func play(_ pattern: String) {
        stop()
        let (segments, total) = Self.timeline(for: pattern)
        guard total > 0, let buffer = makeBuffer(segments: segments, total: total) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            if !configured {
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: buffer.format)
                configured = true
            }
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        node.scheduleBuffer(buffer, at: nil, options: [])
        node.play()
        playingPattern = pattern

        let started = Date()
        progressTask = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(started)
                if elapsed >= total + 0.1 { self.stop(); break }
                self.activeIndex = segments.first { elapsed >= $0.start && elapsed < $0.start + $0.duration }?.index
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    func stop() {
        progressTask?.cancel()
        progressTask = nil
        if node.isPlaying { node.stop() }
        if engine.isRunning { engine.pause() }
        playingPattern = nil
        activeIndex = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func makeBuffer(segments: [Segment], total: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        let frames = AVAudioFrameCount(total * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let data = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for i in 0..<Int(frames) { data[i] = 0 }

        // Ship's horn: low fundamental with a few harmonics, soft attack/release.
        let f0 = 220.0
        let ramp = 0.04
        for seg in segments {
            let start = Int(seg.start * sampleRate)
            let count = Int(seg.duration * sampleRate)
            for n in 0..<count where start + n < Int(frames) {
                let t = Double(n) / sampleRate
                let env = min(1, t / ramp, (seg.duration - t) / ramp)
                let s = sin(2 * .pi * f0 * t) + 0.5 * sin(2 * .pi * 2 * f0 * t)
                    + 0.3 * sin(2 * .pi * 3 * f0 * t) + 0.15 * sin(2 * .pi * 4 * f0 * t)
                data[start + n] = Float(0.28 * env * s)
            }
        }
        return buffer
    }
}

/// Play/stop button that also shows the pattern and highlights the blast that is sounding.
struct SoundSignalButton: View {
    let pattern: String
    @ObservedObject private var player = SoundSignalPlayer.shared

    private var isPlaying: Bool { player.playingPattern == pattern }

    var body: some View {
        Button { player.toggle(pattern) } label: {
            HStack(spacing: 12) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "speaker.wave.2.circle.fill")
                    .font(.title2)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                Text(isPlaying ? "Stop" : "Play signal")
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                glyphs
            }
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.gold.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Stop sound signal") : Text("Play sound signal"))
        .accessibilityValue(Text(SoundSignalButton.spokenDescription(pattern)))
        .onDisappear { if isPlaying { player.stop() } }
    }

    private var glyphs: some View {
        HStack(spacing: 5) {
            ForEach(Array(pattern.enumerated()), id: \.offset) { i, ch in
                let active = player.activeIndex == i
                switch ch {
                case ".":
                    Circle().frame(width: 10, height: 10)
                        .foregroundStyle(active ? Color.gold : Color.ink)
                case "-":
                    Capsule().frame(width: 26, height: 6)
                        .foregroundStyle(active ? Color.gold : Color.ink)
                default:
                    Spacer().frame(width: 8)
                }
            }
        }
        .accessibilityHidden(true)
    }

    /// e.g. "prolonged, short, short"
    static func spokenDescription(_ pattern: String) -> String {
        pattern.compactMap { ch -> String? in
            switch ch {
            case ".": return String(localized: "short", comment: "short blast (sound signal)")
            case "-": return String(localized: "prolonged", comment: "prolonged blast (sound signal)")
            case " ": return String(localized: "pause", comment: "pause in a sound signal")
            default: return nil
            }
        }.joined(separator: ", ")
    }
}
