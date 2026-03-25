import WidgetKit
import SwiftUI

@main
struct HaulWidgetBundle: WidgetBundle {
    var body: some Widget {
        HaulWidget()
    }
}

struct HaulWidget: Widget {
    let kind: String = "HaulWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HaulWidgetProvider()) { entry in
            HaulWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Haul Trip")
        .description("Quick access to your active trip's packing progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HaulWidgetEntry: TimelineEntry {
    let date: Date
    let tripName: String?
    let dateRange: String?
    let packedCount: Int
    let totalCount: Int
    let isEmpty: Bool
    let hasActiveTrip: Bool
}

struct HaulWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HaulWidgetEntry {
        HaulWidgetEntry(
            date: Date(),
            tripName: "Tokyo Trip",
            dateRange: "Mar 15–22",
            packedCount: 12,
            totalCount: 28,
            isEmpty: false,
            hasActiveTrip: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HaulWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HaulWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> HaulWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.haul.app")
        if let tripName = defaults?.string(forKey: "activeTripName"),
           let dateRange = defaults?.string(forKey: "activeTripDateRange"),
           let packed = defaults?.integer(forKey: "activeTripPacked"),
           let total = defaults?.integer(forKey: "activeTripTotal") {
            return HaulWidgetEntry(
                date: Date(),
                tripName: tripName,
                dateRange: dateRange,
                packedCount: packed,
                totalCount: total,
                isEmpty: false,
                hasActiveTrip: true
            )
        }
        return HaulWidgetEntry(
            date: Date(),
            tripName: nil,
            dateRange: nil,
            packedCount: 0,
            totalCount: 0,
            isEmpty: true,
            hasActiveTrip: false
        )
    }
}

struct HaulWidgetEntryView: View {
    var entry: HaulWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.hasActiveTrip {
            activeTripView
        } else {
            emptyStateView
        }
    }

    private var activeTripView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "c4956a"))
                Text(entry.tripName ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "1a1814"))
                    .lineLimit(1)
                Spacer()
            }

            if family == .systemMedium {
                Text(entry.dateRange ?? "")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "7a746a"))
            }

            Spacer()

            // Progress
            let progress = entry.totalCount > 0 ? Double(entry.packedCount) / Double(entry.totalCount) : 0.0

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(entry.packedCount)/\(entry.totalCount) packed")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: "7a746a"))
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(progress == 1.0 ? Color(hex: "5d8c5d") : Color(hex: "c4956a"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "d4cfc6").opacity(0.4))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progress == 1.0 ? Color(hex: "5d8c5d") : Color(hex: "c4956a"))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)

                if progress == 1.0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Ready to go!")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "5d8c5d"))
                }
            }
        }
        .padding(4)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "suitcase")
                .font(.system(size: 28))
                .foregroundColor(Color(hex: "d4cfc6"))

            Text("No active trip")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "7a746a"))

            Text("Open Haul to plan your next trip")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "7a746a").opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
