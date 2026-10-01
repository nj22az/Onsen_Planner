import SwiftUI
import WidgetKit

struct VeckaMediumWidgetView: View {
    let entry: VeckaWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("week.number_label").font(.subheadline).foregroundStyle(.secondary)
                Text(entry.weekNumber, format: .number.grouping(.never))
                    .font(.system(size: 56, weight: .semibold)).foregroundStyle(.tint).monospacedDigit()
                    .minimumScaleFactor(0.5).lineLimit(1)
                Text(verbatim: String(entry.year)).font(.caption).foregroundStyle(.secondary)
            }
            .frame(minWidth: 60)
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.date, format: .dateTime.month(.wide).year())
                    .font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                HStack(spacing: 2) {
                    ForEach(entry.week.days, id: \.self) { day in
                        WeekWidgetDay(date: day, reference: entry.date)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .modifier(WeekWidgetSurface(entry: entry))
    }
}

struct WeekWidgetDay: View {
    let date: Date
    let reference: Date
    private var isToday: Bool { ISOWeekCalendar.calendar().isDate(date, inSameDayAs: reference) }

    var body: some View {
        VStack(spacing: 8) {
            Text(date, format: .dateTime.weekday(.narrow)).foregroundStyle(.secondary)
            Text(date, format: .dateTime.day()).fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background {
                    if isToday { Capsule().fill(.tint.opacity(0.15)).widgetAccentable() }
                }
        }
        .font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date, format: .dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }
}
