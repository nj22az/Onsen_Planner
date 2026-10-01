import SwiftUI
import WidgetKit

struct VeckaLargeWidgetView: View {
    let entry: VeckaWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text("week.number_label").font(.subheadline).foregroundStyle(.secondary)
                    Text(entry.weekNumber, format: .number.grouping(.never))
                        .font(.largeTitle.bold()).foregroundStyle(.tint).monospacedDigit()
                }
                Spacer()
                Text(entry.date, format: .dateTime.month(.wide).year()).font(.headline)
            }
            Grid(horizontalSpacing: 4, verticalSpacing: 8) {
                GridRow {
                    Text("week.short").foregroundStyle(.secondary)
                    ForEach(entry.week.days, id: \.self) { date in
                        Text(date, format: .dateTime.weekday(.narrow)).foregroundStyle(.secondary)
                    }
                }
                ForEach(ISOWeekCalendar.monthWeeks(for: entry.date), id: \.start) { week in
                    GridRow {
                        Text(week.number, format: .number.grouping(.never)).foregroundStyle(.secondary)
                        ForEach(week.days, id: \.self) { date in
                            let today = ISOWeekCalendar.calendar().isDate(date, inSameDayAs: entry.date)
                            Text(date, format: .dateTime.day())
                                .fontWeight(today ? .bold : .regular)
                                .foregroundStyle(today ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                                .opacity(ISOWeekCalendar.calendar().component(.month, from: date) == ISOWeekCalendar.calendar().component(.month, from: entry.date) ? 1 : 0.4)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .background {
                                    if today { Capsule().fill(.tint.opacity(0.15)).widgetAccentable() }
                                }
                                .accessibilityLabel(Text(date, format: .dateTime.weekday(.wide).month(.wide).day()))
                        }
                    }
                }
            }
            .font(.caption).monospacedDigit()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .modifier(WeekWidgetSurface(entry: entry))
    }
}
