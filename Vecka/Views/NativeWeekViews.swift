import SwiftUI

/// Shared native week presentation for iOS and macOS.
struct WeekHeroView: View {
    let date: Date
    let appearance: WeekAppearance
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 72
    private var week: ISOWeek { ISOWeekCalendar.week(for: date) }

    var body: some View {
        Group {
            switch appearance {
            case .apple:
                VStack(alignment: .leading, spacing: 8) { label; number; range; year }
            case .muji:
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 24) {
                        number
                        VStack(alignment: .leading, spacing: 8) { label; range; year }
                    }
                    VStack(alignment: .leading, spacing: 12) { label; number; range; year }
                }
            case .note:
                VStack(alignment: .leading, spacing: 12) { range.font(.headline); label; number; year }
            case .kinto:
                VStack(alignment: .center, spacing: 16) { label; number; range; year }
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: appearance == .kinto ? .center : .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("week.widget_label \(week.number)"))
        .accessibilityValue(Text(verbatim: week.start.formatted(.dateTime.month(.wide).day()) + " – " + week.end.formatted(.dateTime.month(.wide).day().year()) + ", " + String(localized: "week.iso_year \(String(week.year))")))
        .accessibilityIdentifier("week-summary")
    }
    private var label: some View { Text("week.number_label").font(.subheadline).foregroundStyle(.secondary) }
    private var number: some View {
        Text(week.number, format: .number.grouping(.never))
            .font(.system(size: numberSize, weight: appearance == .kinto ? .regular : .semibold))
            .monospacedDigit()
            .accessibilityIdentifier("week-number")
    }
    private var range: some View {
        Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day().year()))
            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
    }
    private var year: some View { Text("week.iso_year \(String(week.year))").font(.caption).foregroundStyle(.secondary) }
}

struct WeekDayStrip: View {
    let week: ISOWeek
    let now: Date
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(week.days, id: \.self) { date in
                    HStack {
                        Text(date, format: .dateTime.weekday(.wide).day())
                        if ISOWeekCalendar.calendar().isDate(date, inSameDayAs: now) { Text("week.today").foregroundStyle(.tint) }
                    }
                }
            }
        } else {
            HStack(spacing: 0) {
                ForEach(week.days, id: \.self) { date in
                    let today = ISOWeekCalendar.calendar().isDate(date, inSameDayAs: now)
                    VStack(spacing: 10) {
                        Text(date, format: .dateTime.weekday(.narrow)).font(.caption).foregroundStyle(.secondary)
                        Text(date, format: .dateTime.day()).font(.body.weight(today ? .semibold : .regular))
                        Circle().fill(today ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.clear)).frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(date, format: .dateTime.weekday(.wide).month(.wide).day()))
                    .accessibilityAddTraits(today ? .isSelected : [])
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct WeekMonthView: View {
    let date: Date
    let now: Date
    var select: ((Date) -> Void)?
    @Environment(\.dynamicTypeSize) private var typeSize
    private var selected: ISOWeek { ISOWeekCalendar.week(for: date) }
    private var calendar: Calendar { ISOWeekCalendar.calendar() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date, format: .dateTime.month(.wide).year()).font(.headline)
            if !typeSize.isAccessibilitySize {
                HStack(spacing: 0) {
                    Text("week.short").frame(maxWidth: .infinity)
                    ForEach(selected.days, id: \.self) { day in
                        Text(day, format: .dateTime.weekday(.narrow)).frame(maxWidth: .infinity)
                    }
                }
                .font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            ForEach(ISOWeekCalendar.monthWeeks(for: date), id: \.start) { week in
                Button {
                    select?(week.days.first { calendar.isDate($0, equalTo: date, toGranularity: .month) } ?? week.start)
                } label: {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("week.widget_label \(week.number)").font(.headline)
                            Text(verbatim: week.start.formatted(.dateTime.month(.abbreviated).day()) + " – " + week.end.formatted(.dateTime.month(.abbreviated).day()))
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    } else {
                        HStack(spacing: 0) {
                            Text(week.number, format: .number.grouping(.never)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                            ForEach(week.days, id: \.self) { day in
                                Text(day, format: .dateTime.day())
                                    .fontWeight(calendar.isDate(day, inSameDayAs: now) ? .bold : .regular)
                                    .opacity(calendar.isDate(day, equalTo: date, toGranularity: .month) ? 1 : 0.4)
                                    .frame(maxWidth: .infinity)
                            }
                        }.font(.subheadline).monospacedDigit().frame(minHeight: 44)
                    }
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .background(week.start == selected.start ? Color.accentColor.opacity(0.08) : Color.clear)
                .accessibilityLabel(Text("week.widget_label \(week.number)"))
                .accessibilityValue(Text(verbatim: week.start.formatted(.dateTime.month(.wide).day()) + " – " + week.end.formatted(.dateTime.month(.wide).day())))
                .accessibilityAddTraits(week.start == selected.start ? .isSelected : [])
                .disabled(select == nil)
            }
        }
        .accessibilityIdentifier("week-month")
    }
}

