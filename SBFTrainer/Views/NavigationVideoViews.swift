import SwiftUI

/// A video row that opens the video in YouTube (feature flag navigationVideos).
struct NavigationVideoRow: View {
    let video: NavigationVideo
    var start: Int? = nil
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button { openURL(video.url(startingAt: start)) } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.errorRed)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: video.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    NavigationVideoMeta(video: video)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

/// "Channel · 13 min · German"
struct NavigationVideoMeta: View {
    let video: NavigationVideo

    var body: some View {
        HStack(spacing: 4) {
            Text(verbatim: video.channel)
            Text(verbatim: "·")
            Text("\(video.minutes) min")
            if let lang = video.lang {
                Text(verbatim: "·")
                Text(lang == "de" ? "German" : "English")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

/// Technique videos, all of them or one technique (opened from a sub-question).
struct NavigationVideosView: View {
    let techniques: [NavigationTechnique]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(techniques) { technique in
                    if techniques.count > 1 {
                        SectionHeader(title: LocalizedStringKey(technique.localized), systemImage: "play.rectangle")
                    }
                    ForEach(technique.videos) { NavigationVideoRow(video: $0) }
                }
                NavigationVideosDisclaimer()
            }
            .padding(20)
            .readableWidth()
        }
        .background(Color.surfaceBG)
        .navigationTitle(techniques.count == 1 ? techniques[0].localized : String(localized: "Technique videos"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NavigationVideosDisclaimer: View {
    var body: some View {
        Text("Videos by third parties on YouTube. They open in YouTube and are not part of the official ELWIS material.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension NavigationWalkthrough {
    /// "4:41"
    static func timestamp(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }
}
