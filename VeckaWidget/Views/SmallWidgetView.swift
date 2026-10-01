import SwiftUI
import WidgetKit

struct VeckaSmallWidgetView: View {
    let entry: VeckaWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("week.number_label").font(.headline).foregroundStyle(.secondary)
            Text(entry.weekNumber, format: .number.grouping(.never))
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.tint).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
            Spacer(minLength: 0)
            Text(entry.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.caption).lineLimit(1).minimumScaleFactor(0.8)
            Text("week.iso_year \(String(entry.year))").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .modifier(WeekWidgetSurface(entry: entry))
    }
}

struct WeekWidgetSurface: ViewModifier {
    let entry: VeckaWidgetEntry
    @Environment(\.widgetRenderingMode) private var renderingMode
    private var appearance: WeekAppearance {
        WeekAppearance.resolve(WeekAppearance.defaults.string(forKey: WeekAppearance.storageKey) ?? "apple")
    }

    func body(content: Content) -> some View {
        content
            .tint(renderingMode == .fullColor ? appearance.tint : .primary)
            .containerBackground(.background, for: .widget)
            .widgetURL(URL(string: "vecka://week/\(entry.weekNumber)/\(entry.year)"))
            .accessibilityElement(children: .combine)
    }
}
