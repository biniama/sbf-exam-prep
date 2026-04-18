import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animate = false

    private let colors: [Color] = [
        .gold, .successGreen, .oceanTeal,
        Color(red: 0.95, green: 0.85, blue: 0.3),
        Color(red: 0.3, green: 0.75, blue: 0.9),
        Color(red: 0.95, green: 0.5, blue: 0.3),
        .white
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 0.55)
                        .rotationEffect(.degrees(animate ? p.endAngle : p.startAngle))
                        .offset(
                            x: animate ? p.endX : p.startX,
                            y: animate ? p.endY : p.startY
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: p.duration).delay(p.delay),
                            value: animate
                        )
                }
            }
            .onAppear {
                let w = geo.size.width
                particles = (0..<70).map { _ in
                    ConfettiParticle(
                        startX: CGFloat.random(in: 0...w) - w / 2,
                        startY: CGFloat.random(in: -120...(-20)),
                        endX: CGFloat.random(in: -w * 0.6...w * 0.6),
                        endY: geo.size.height * CGFloat.random(in: 0.7...1.1),
                        color: colors.randomElement()!,
                        size: CGFloat.random(in: 7...14),
                        startAngle: Double.random(in: 0...360),
                        endAngle: Double.random(in: 400...1080),
                        duration: Double.random(in: 1.6...2.4),
                        delay: Double.random(in: 0...0.4)
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    var startX, startY: CGFloat
    var endX, endY: CGFloat
    var color: Color
    var size: CGFloat
    var startAngle, endAngle: Double
    var duration, delay: Double
}
