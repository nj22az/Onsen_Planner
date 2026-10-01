import WidgetKit
import Foundation

/// Week numbers require no permissions, shared database or network request.
struct VeckaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VeckaWidgetEntry { VeckaWidgetEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (VeckaWidgetEntry) -> Void) {
        completion(VeckaWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VeckaWidgetEntry>) -> Void) {
        let entries = ISOWeekCalendar.timelineDates(from: Date()).map { VeckaWidgetEntry(date: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct VeckaWidgetEntry: TimelineEntry {
    let date: Date
    var week: ISOWeek { ISOWeekCalendar.week(for: date) }
    var weekNumber: Int { week.number }
    var year: Int { week.year }
    static var preview: Self { Self(date: Date()) }
}
