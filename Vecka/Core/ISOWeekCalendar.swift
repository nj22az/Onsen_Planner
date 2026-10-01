import Foundation

/// One ISO rule for the app, shortcuts and widgets. Never reads the database.
enum ISOWeekCalendar {
    static func calendar(timeZone: TimeZone = .autoupdatingCurrent) -> Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        calendar.timeZone = timeZone
        return calendar
    }

    static func week(for date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> ISOWeek {
        let calendar = calendar(timeZone: timeZone)
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        return ISOWeek(number: calendar.component(.weekOfYear, from: date),
                       year: calendar.component(.yearForWeekOfYear, from: date),
                       start: start,
                       days: (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) })
    }

    static func date(week: Int, year: Int, timeZone: TimeZone = .autoupdatingCurrent) -> Date? {
        guard (1...53).contains(week), (1...9999).contains(year) else { return nil }
        let calendar = calendar(timeZone: timeZone)
        guard let date = calendar.date(from: DateComponents(weekday: 2, weekOfYear: week, yearForWeekOfYear: year)),
              calendar.component(.weekOfYear, from: date) == week,
              calendar.component(.yearForWeekOfYear, from: date) == year else { return nil }
        return date
    }

    static func weeks(in year: Int, timeZone: TimeZone = .autoupdatingCurrent) -> Int {
        let calendar = calendar(timeZone: timeZone)
        guard let date = calendar.date(from: DateComponents(year: year, month: 12, day: 28)) else { return 52 }
        return calendar.component(.weekOfYear, from: date)
    }

    static func monthWeeks(for date: Date, timeZone: TimeZone = .autoupdatingCurrent) -> [ISOWeek] {
        let calendar = calendar(timeZone: timeZone)
        guard let month = calendar.dateInterval(of: .month, for: date) else { return [] }
        var start = week(for: month.start, timeZone: timeZone).start
        var result: [ISOWeek] = []
        while start < month.end && result.count < 6 {
            result.append(week(for: start, timeZone: timeZone))
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { break }
            start = next
        }
        return result
    }

    /// Precompute local midnights: WidgetKit can advance even if refresh is delayed.
    /// Calendar days, rather than 86,400 seconds, keep DST boundaries correct.
    static func timelineDates(from now: Date, days: Int = 14,
                              timeZone: TimeZone = .autoupdatingCurrent) -> [Date] {
        let calendar = calendar(timeZone: timeZone)
        let start = calendar.startOfDay(for: now)
        guard days > 0 else { return [now] }
        return [now] + (1...min(days, 31)).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}

struct ISOWeek: Equatable, Sendable {
    let number: Int
    let year: Int
    let start: Date
    let days: [Date]
    var end: Date { days.last ?? start }
}
