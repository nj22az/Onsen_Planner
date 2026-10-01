import Foundation

/// Window selections are independent; nil follows the current local date.
struct MacWeekSelection: Equatable {
    var date: Date?
    func resolved(now: Date) -> Date { date ?? now }
    mutating func move(_ weeks: Int, now: Date, timeZone: TimeZone = .autoupdatingCurrent) {
        date = ISOWeekCalendar.calendar(timeZone: timeZone).date(byAdding: .weekOfYear, value: weeks, to: resolved(now: now))
    }
    mutating func today() { date = nil }
    mutating func open(_ url: URL, now: Date, timeZone: TimeZone = .autoupdatingCurrent) -> Bool {
        guard url.scheme == "vecka" else { return false }
        switch url.host {
        case "today", "calendar": today(); return true
        case "week":
            let components = url.pathComponents.filter { $0 != "/" }
            guard (1...2).contains(components.count), let number = Int(components[0]) else { return false }
            let year: Int
            if components.count == 2 {
                guard let value = Int(components[1]) else { return false }
                year = value
            } else { year = ISOWeekCalendar.week(for: now, timeZone: timeZone).year }
            guard let target = ISOWeekCalendar.date(week: number, year: year, timeZone: timeZone) else { return false }
            date = target
            return true
        default: return false
        }
    }
}
