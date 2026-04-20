import SwiftUI
import UIKit

extension Color {
    static let navy        = Color(red: 0.04, green: 0.14, blue: 0.26)
    static let navyMid     = Color(red: 0.10, green: 0.23, blue: 0.37)
    static let navyLight   = Color(red: 0.16, green: 0.35, blue: 0.54)
    static let gold        = Color(red: 0.79, green: 0.66, blue: 0.30)
    static let goldLight   = Color(red: 0.95, green: 0.85, blue: 0.55)
    static let oceanTeal   = Color(red: 0.10, green: 0.60, blue: 0.66)
    static let successGreen = Color(red: 0.18, green: 0.49, blue: 0.20)
    static let errorRed    = Color(red: 0.77, green: 0.16, blue: 0.16)
    static let cardBG      = Color(.secondarySystemBackground)
    static let surfaceBG   = Color(.systemGroupedBackground)
}

// Use these instead of Color.xxx.gradient — avoids UIColor out-of-range warnings
// caused by SwiftUI's .gradient shorthand using extended Oklab color space
enum AppGradient {
    static let navy = LinearGradient(colors: [.navyMid, .navy], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gold = LinearGradient(colors: [.goldLight, .gold], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let errorRed = LinearGradient(colors: [Color(red: 0.87, green: 0.30, blue: 0.30), .errorRed], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let successGreen = LinearGradient(colors: [Color(red: 0.28, green: 0.62, blue: 0.30), .successGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let gray = LinearGradient(colors: [Color(white: 0.72), Color(white: 0.56)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct NavyGradient: View {
    var body: some View {
        LinearGradient(
            colors: [.navy, .navyMid],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ).ignoresSafeArea()
    }
}

struct GoldBadge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppGradient.gold)
            .clipShape(Capsule())
    }
}

extension View {
    func goldBadge() -> some View { modifier(GoldBadge()) }

    func cardStyle() -> some View {
        self
            .background(Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

struct ExamTypeBadge: View {
    let type: ExamType
    var body: some View {
        Text(type.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor)
            .clipShape(Capsule())
    }
    var badgeColor: Color {
        switch type {
        case .all:    return .navyLight
        case .shared: return .gold
        case .binnen: return .oceanTeal
        case .see:    return .navy
        }
    }
}

struct CategoryBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.navyMid)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.navyLight.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Image preview helpers

private struct PreviewImage: Identifiable {
    let id = UUID()
    let uiImage: UIImage
}

// UIScrollView subclass that re-sizes the image view whenever the scroll view
// gets its real bounds from the layout system (solves the "black screen" issue
// caused by bounds being .zero at makeUIView / updateUIView time).
private final class _PreviewScrollView: UIScrollView {
    let imageView = UIImageView()

    override func layoutSubviews() {
        super.layoutSubviews()
        guard zoomScale == minimumZoomScale else { return }
        imageView.frame = bounds
        contentSize = bounds.size
    }
}

/// UIScrollView wrapper that supports pinch-to-zoom and double-tap-to-zoom.
/// Calls `onDismiss` on a single tap when not zoomed.
private struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onDismiss: onDismiss) }

    func makeUIView(context: Context) -> _PreviewScrollView {
        let scrollView = _PreviewScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 6
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.delegate = context.coordinator
        scrollView.contentInsetAdjustmentBehavior = .never

        scrollView.imageView.image = image
        scrollView.imageView.contentMode = .scaleAspectFit
        scrollView.imageView.backgroundColor = .clear
        scrollView.addSubview(scrollView.imageView)
        context.coordinator.scrollView = scrollView

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap)
        )
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)

        return scrollView
    }

    func updateUIView(_ scrollView: _PreviewScrollView, context: Context) {}

    class Coordinator: NSObject, UIScrollViewDelegate {
        let onDismiss: () -> Void
        weak var scrollView: _PreviewScrollView?

        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? _PreviewScrollView)?.imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let iv = (scrollView as? _PreviewScrollView)?.imageView else { return }
            let offsetX = max((scrollView.bounds.width  - iv.frame.width)  / 2, 0)
            let offsetY = max((scrollView.bounds.height - iv.frame.height) / 2, 0)
            iv.center = CGPoint(x: iv.frame.width / 2 + offsetX,
                                y: iv.frame.height / 2 + offsetY)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let sv = scrollView else { return }
            if sv.zoomScale > 1 {
                sv.setZoomScale(1, animated: true)
            } else {
                let pt = gesture.location(in: sv.imageView)
                sv.zoom(to: CGRect(x: pt.x - 40, y: pt.y - 40, width: 80, height: 80),
                        animated: true)
            }
        }

        @objc func handleSingleTap() {
            if let sv = scrollView, sv.zoomScale <= 1.05 { onDismiss() }
        }
    }
}

/// Full-screen image preview with zoom, close button, swipe-down, and tap-background dismiss.
struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(1 - min(abs(dragOffset) / 300, 0.6))
                .ignoresSafeArea()

            ZoomableImageView(image: image, onDismiss: { close() })
                .ignoresSafeArea()
                .offset(y: dragOffset)
                .animation(.interactiveSpring(), value: dragOffset)

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: close) {
                        ZStack {
                            Circle()
                                .fill(.black.opacity(0.45))
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onChanged { value in
                    // Only allow downward drag
                    let dy = value.translation.height
                    if dy > 0 { dragOffset = dy }
                }
                .onEnded { value in
                    if dragOffset > 90 {
                        close()
                    } else {
                        withAnimation(.spring(response: 0.3)) { dragOffset = 0 }
                    }
                }
        )
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.18)) { dismiss() }
    }
}

// MARK: - QuestionImageView

struct QuestionImageView: View {
    let question: Question
    @State private var activePreview: PreviewImage? = nil

    var body: some View {
        let urls = question.imageURLs
        if urls.isEmpty {
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.navyLight.opacity(0.35))
                    Text("Image question")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(Color.navyLight.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if urls.count == 1, let uiImage = UIImage(contentsOfFile: urls[0].path) {
            thumbnail(uiImage)
                .onTapGesture { activePreview = PreviewImage(uiImage: uiImage) }
                .fullScreenCover(item: $activePreview) { item in
                    ImagePreviewView(image: item.uiImage)
                }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(urls.enumerated()), id: \.element.absoluteString) { _, url in
                        if let uiImage = UIImage(contentsOfFile: url.path) {
                            thumbnail(uiImage, height: 200)
                                .onTapGesture { activePreview = PreviewImage(uiImage: uiImage) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .fullScreenCover(item: $activePreview) { item in
                ImagePreviewView(image: item.uiImage)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ image: UIImage, height: CGFloat = 240) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: height)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.navyLight.opacity(0.2), lineWidth: 1))

            // Magnify hint
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.navyLight)
                .padding(5)
                .background(.ultraThinMaterial, in: Circle())
                .padding(8)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.navy)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardStyle()
    }
}
