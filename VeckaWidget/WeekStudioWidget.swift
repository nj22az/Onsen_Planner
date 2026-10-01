import AppIntents
import SwiftUI
import WidgetKit

struct WeekStudioIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "week.studio_title"
    static let description = IntentDescription("week.studio_description")
    @Parameter(title: "week.studio_layout", default: .minimal) var layout: WeekStudioLayout
    @Parameter(title: "week.studio_colour", default: .blue) var colour: WeekStudioColour
    @Parameter(title: "week.studio_show_date", default: true) var showDate: Bool
    @Parameter(title: "week.studio_show_year", default: true) var showYear: Bool
}

struct WeekStudioEntry: TimelineEntry {
    let date: Date
    let configuration: WeekStudioIntent
    let owned: Bool
}
struct WeekStudioProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeekStudioEntry {
        WeekStudioEntry(date: Date(), configuration: WeekStudioIntent(), owned: false)
    }
    func snapshot(for configuration: WeekStudioIntent, in context: Context) async -> WeekStudioEntry {
        let result = await AddOnVerifier.current()
        return WeekStudioEntry(date: Date(), configuration: configuration,
                               owned: result.owned.contains(AddOnProduct.widgetStudio.rawValue))
    }
    func timeline(for configuration: WeekStudioIntent, in context: Context) async -> Timeline<WeekStudioEntry> {
        let result = await AddOnVerifier.current()
        let owned = result.owned.contains(AddOnProduct.widgetStudio.rawValue)
        let now = Date()
        let entries = ISOWeekCalendar.timelineDates(from: now).map {
            WeekStudioEntry(date: $0, configuration: configuration, owned: owned)
        }
        // Request re-verification; WidgetKit decides when the request is honoured.
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600)))
    }
}
struct WeekStudioEntryView: View {
    let entry: WeekStudioEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var mode
    var body: some View {
        if entry.owned {
            WeekStudioContent(date: entry.date, layout: entry.configuration.layout,
                              showDate: entry.configuration.showDate, showYear: entry.configuration.showYear,
                              compact: family == .systemSmall)
                .tint(mode == .fullColor ? entry.configuration.colour.appearance.tint : .primary)
                .containerBackground(.background, for: .widget)
                .widgetURL(URL(string: "vecka://week/\(ISOWeekCalendar.week(for: entry.date).number)/\(ISOWeekCalendar.week(for: entry.date).year)"))
        } else {
            // Never obstruct the week or erase the saved widget configuration.
            VeckaWidgetEntryView(entry: VeckaWidgetEntry(date: entry.date))
        }
    }
}
struct WeekStudioWidget: Widget {
    let kind = "VeckaWidgetStudio"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeekStudioIntent.self, provider: WeekStudioProvider()) { entry in
            WeekStudioEntryView(entry: entry)
        }
        .configurationDisplayName("week.studio_title")
        .description("week.studio_widget_description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
