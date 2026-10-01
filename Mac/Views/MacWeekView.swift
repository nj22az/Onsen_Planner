import SwiftUI

struct MacWeekView: View {
    let selection: MacWeekSelection
    let appearance: WeekAppearance
    let select: (Date?) -> Void
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let date = selection.resolved(now: context.date)
            ScrollView {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 40) {
                        overview(date: date, now: context.date).frame(minWidth: 220, maxWidth: 320)
                        WeekMonthView(date: date, now: context.date) { select($0) }.frame(minWidth: 320, maxWidth: 480)
                    }
                    VStack(alignment: .leading, spacing: 32) {
                        overview(date: date, now: context.date)
                        WeekMonthView(date: date, now: context.date) { select($0) }
                    }
                }
                .padding(28).frame(maxWidth: 940, alignment: .leading).frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("mac-week-home")
    }
    private func overview(date: Date, now: Date) -> some View {
        VStack(alignment: .leading, spacing: appearance.sectionSpacing) {
            Text(date, format: .dateTime.weekday(.wide).month(.wide).day()).font(.subheadline).foregroundStyle(.secondary)
            WeekHeroView(date: date, appearance: appearance)
            WeekDayStrip(week: ISOWeekCalendar.week(for: date), now: now)
            Text("week.iso_explanation").font(.callout).foregroundStyle(.secondary)
        }
    }
}
