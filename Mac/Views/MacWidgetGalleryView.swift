import SwiftUI

struct MacWidgetGalleryView: View {
    let openAddOns: () -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("mac.widget_instructions").font(.body)
                Text("week.gallery_free").font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) { small; medium }
                    VStack(alignment: .leading, spacing: 20) { small; medium }
                }
                WeekMonthView(date: Date(), now: Date()).padding(20)
                    .background(.background, in: RoundedRectangle(cornerRadius: 20))
                Text("week.gallery_large").font(.caption).foregroundStyle(.secondary)
                Divider()
                Text("week.studio_title").font(.headline)
                Text("week.studio_intro").font(.callout).foregroundStyle(.secondary)
                WeekStudioContent(date: Date(), layout: .minimal).frame(minHeight: 170)
                    .padding(20).background(.background, in: RoundedRectangle(cornerRadius: 20))
                Button("week.addons", action: openAddOns)
                Text("mac.widget_preview").font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 720, alignment: .leading).frame(maxWidth: .infinity)
        }.navigationTitle("week.widgets")
    }
    private var small: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("week.number_label").font(.subheadline)
            Text(ISOWeekCalendar.week(for: Date()).number, format: .number.grouping(.never)).font(.largeTitle.weight(.semibold))
            Text(Date(), format: .dateTime.month(.abbreviated).day()).font(.caption)
        }.padding(20).frame(minWidth: 150, minHeight: 150, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
    private var medium: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("week.widget_label \(ISOWeekCalendar.week(for: Date()).number)").font(.title2)
            WeekDayStrip(week: ISOWeekCalendar.week(for: Date()), now: Date())
        }.padding(20).frame(minWidth: 260, minHeight: 150, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}
