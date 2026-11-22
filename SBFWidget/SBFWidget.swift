import SwiftUI
import WidgetKit

struct StudyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StudyProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudyEntry {
        StudyEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudyEntry) -> Void) {
        completion(StudyEntry(date: .now, snapshot: context.isPreview ? .placeholder : (WidgetSnapshot.load() ?? .placeholder)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudyEntry>) -> Void) {
        let now = Date()
        guard let snapshot = WidgetSnapshot.load() else {
            completion(Timeline(entries: [StudyEntry(date: now, snapshot: .empty)], policy: .after(now.addingTimeInterval(3600))))
            return
        }
        let dates = [now] + snapshot.refreshDates(after: now)
        let entries = dates.map { StudyEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

extension WidgetSnapshot {
    static let empty = WidgetSnapshot(streak: 0, lastStudyDay: nil, dueDates: [], answered: 0, accuracy: 0,
                                      masteredCount: 0, totalQuestions: 466, updated: .now)
}

private let navy = Color(red: 0.04, green: 0.14, blue: 0.26)
private let gold = Color(red: 0.79, green: 0.66, blue: 0.30)

struct StudyWidgetView: View {
    let entry: StudyEntry
    @Environment(\.widgetFamily) private var family

    private var streak: Int { entry.snapshot.currentStreak(at: entry.date) }
    private var due: Int { entry.snapshot.dueCount(at: entry.date) }
    private var studiedToday: Bool { entry.snapshot.studied(on: entry.date) }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(studiedToday ? gold : .white.opacity(0.6))
                Text("\(streak)").font(.title.bold()).foregroundStyle(.white)
            }
            Text("day streak").font(.caption2).foregroundStyle(.white.opacity(0.75))
            Spacer(minLength: 0)
            Text(due > 0 ? "\(due) due" : "All caught up")
                .font(.headline)
                .foregroundStyle(gold)
                .minimumScaleFactor(0.7)
            Text(studiedToday ? "Studied today ✓" : "Keep your streak!")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            small
            Divider().overlay(.white.opacity(0.3))
            VStack(alignment: .leading, spacing: 10) {
                stat("checkmark.circle", entry.snapshot.accuracy.formatted(.percent.precision(.fractionLength(0))), "accuracy")
                stat("star.circle", "\(entry.snapshot.masteredCount)/\(entry.snapshot.totalQuestions)", "mastered")
                stat("number.circle", "\(entry.snapshot.answered)", "answered")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func stat(_ icon: String, _ value: String, _ label: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(gold)
            Text(value).font(.subheadline.bold()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.75))
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "sailboat.fill").font(.caption2)
                Text("\(due)").font(.title3.bold())
            }
        }
        .widgetAccentable()
        .accessibilityLabel(Text("\(due) questions due"))
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("SBF Exam Prep", systemImage: "sailboat.fill").font(.caption.bold()).widgetAccentable()
            Text(due > 0 ? "\(due) questions due" : "All caught up").font(.caption)
            Text("\(streak)-day streak").font(.caption2)
        }
    }
}

struct StudyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudyWidget", provider: StudyProvider()) { entry in
            StudyWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [navy, Color(red: 0.10, green: 0.23, blue: 0.37)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Study progress")
        .description("Your streak and the questions due for review.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct SBFWidgetBundle: WidgetBundle {
    var body: some Widget { StudyWidget() }
}
