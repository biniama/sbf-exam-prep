import SwiftUI
import UIKit

// MARK: - Image preview helpers

private struct PreviewImage: Identifiable {
    let id = UUID()
    let uiImage: UIImage
    let label: String
}

// UIScrollView subclass that re-sizes the image view whenever the scroll view
// gets its real bounds from the layout system (bounds are .zero at
// makeUIView / updateUIView time, which used to produce a black screen).
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
    let label: String
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
        scrollView.imageView.backgroundColor = .white
        scrollView.imageView.isAccessibilityElement = true
        scrollView.imageView.accessibilityLabel = label
        scrollView.addSubview(scrollView.imageView)
        context.coordinator.scrollView = scrollView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleSingleTap))
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        return scrollView
    }

    func updateUIView(_ scrollView: _PreviewScrollView, context: Context) {}

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let onDismiss: () -> Void
        weak var scrollView: _PreviewScrollView?

        init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? _PreviewScrollView)?.imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let iv = (scrollView as? _PreviewScrollView)?.imageView else { return }
            let offsetX = max((scrollView.bounds.width - iv.frame.width) / 2, 0)
            let offsetY = max((scrollView.bounds.height - iv.frame.height) / 2, 0)
            iv.center = CGPoint(x: iv.frame.width / 2 + offsetX, y: iv.frame.height / 2 + offsetY)
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let sv = scrollView else { return }
            if sv.zoomScale > 1 {
                sv.setZoomScale(1, animated: true)
            } else {
                let pt = gesture.location(in: sv.imageView)
                sv.zoom(to: CGRect(x: pt.x - 40, y: pt.y - 40, width: 80, height: 80), animated: true)
            }
        }

        @objc func handleSingleTap() {
            if let sv = scrollView, sv.zoomScale <= 1.05 { onDismiss() }
        }
    }
}

/// Full-screen image preview with zoom, close button, swipe-down and tap-to-dismiss.
struct ImagePreviewView: View {
    let image: UIImage
    var label: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black
                .opacity(1 - min(abs(dragOffset) / 300, 0.6))
                .ignoresSafeArea()

            ZoomableImageView(image: image, label: label, onDismiss: { close() })
                .ignoresSafeArea()
                .offset(y: dragOffset)
                .animation(.interactiveSpring(), value: dragOffset)

            VStack {
                HStack {
                    Spacer()
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.black.opacity(0.45)))
                    }
                    .accessibilityLabel(Text("Close"))
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                }
                Spacer()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onChanged { value in
                    let dy = value.translation.height
                    if dy > 0 { dragOffset = dy }
                }
                .onEnded { _ in
                    if dragOffset > 90 { close() } else { withAnimation(.spring(response: 0.3)) { dragOffset = 0 } }
                }
        )
    }

    private func close() { dismiss() }
}

// MARK: - QuestionImageView

/// Illustration of a question with tap-to-enlarge, plus a play button for sound signals.
struct QuestionImageView: View {
    let question: Question
    var maxHeight: CGFloat = 260
    @State private var activePreview: PreviewImage? = nil

    var body: some View {
        VStack(spacing: 10) {
            ForEach(question.imageURLs, id: \.absoluteString) { url in
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    thumbnail(uiImage)
                        .onTapGesture { activePreview = PreviewImage(uiImage: uiImage, label: accessibilityText) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(accessibilityText))
                        .accessibilityHint(Text("Double-tap to enlarge"))
                        .accessibilityAddTraits([.isImage, .isButton])
                        .accessibilityAction { activePreview = PreviewImage(uiImage: uiImage, label: accessibilityText) }
                }
            }
            if let pattern = question.soundPattern {
                SoundSignalButton(pattern: pattern)
            }
        }
        .fullScreenCover(item: $activePreview) { item in
            ImagePreviewView(image: item.uiImage, label: item.label)
        }
    }

    private var accessibilityText: String {
        if let pattern = question.soundPattern {
            return String(localized: "Sound signal: \(SoundSignalButton.spokenDescription(pattern))")
        }
        return String(localized: "Illustration for question \(question.questionNumber)")
    }

    private func thumbnail(_ image: UIImage) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: maxHeight)
                .padding(12)
                .background(Color.white)              // illustrations are drawn on white
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.navyLight.opacity(0.25), lineWidth: 1))

            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.navyLight)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
                .padding(8)
        }
        .contentShape(Rectangle())
    }
}
