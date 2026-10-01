//
//  VeckaWidget.swift
//  VeckaWidget
//
//  情報デザイン (Jōhō Dezain) Widget
//  Japanese Minimalist: Small (week hero) + Large (month calendar)
//

import WidgetKit
import SwiftUI
import Foundation

// MARK: - Main Widget View
struct VeckaWidgetEntryView: View {
    let entry: VeckaWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            VeckaSmallWidgetView(entry: entry)
        case .systemMedium:
            VeckaMediumWidgetView(entry: entry)
        case .systemLarge:
            VeckaLargeWidgetView(entry: entry)
        #if os(iOS)
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("week.short").font(.caption2)
                Text(entry.weekNumber, format: .number.grouping(.never)).font(.title2.bold()).monospacedDigit()
            }
            .containerBackground(.background, for: .widget)
            .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("week.widget_label \(entry.weekNumber)").font(.headline)
                Text(entry.date, format: .dateTime.month(.abbreviated).day()).font(.caption)
            }
            .containerBackground(.background, for: .widget)
            .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        case .accessoryInline:
            Text("week.widget_label \(entry.weekNumber)")
                .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
        #endif
        default:
            VeckaSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct VeckaWidget: Widget {
    let kind: String = "VeckaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VeckaWidgetProvider()) { entry in
            VeckaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Week Number")
        .description("View the current ISO week number and monthly calendar.")
        .supportedFamilies(supportedFamilies)
    }
    private var supportedFamilies: [WidgetFamily] {
        #if os(macOS)
        return [.systemSmall, .systemMedium, .systemLarge]
        #else
        return [.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
    }

}

/// Preserve the original widget kind and installed configurations.
@main
struct VeckaWidgetBundle: WidgetBundle {
    var body: some Widget {
        VeckaWidget()
        WeekStudioWidget()
    }
}
