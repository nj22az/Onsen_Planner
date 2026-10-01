//
//  WeekCalculator.swift
//  Vecka
//
//  Production-grade ISO 8601 week number calculator
//  Stateless ISO calculations shared with the widget
//

import Foundation

/// Compatibility facade for the database-independent ISO date engine.
final class WeekCalculator {
    static let shared = WeekCalculator()
    private init() {}

    /// Kept for saved-planner compatibility. Week numbers always use ISO 8601.
    @MainActor
    func configure(with rule: CalendarRule) {
        Log.i("ISO week numbering is fixed; saved calendar rule retained: \(rule.id)")
    }

    func currentWeekNumber() -> Int { weekNumber(for: Date()) }
    func currentYear() -> Int { ISOWeekCalendar.week(for: Date()).year }
    func weekNumber(for date: Date) -> Int { ISOWeekCalendar.week(for: date).number }

    /// Time-dependent fields are recalculated, never cached across midnight.
    func weekInfo(for date: Date = Date(), now: Date = Date()) -> WeekInfo {
        let week = ISOWeekCalendar.week(for: date)
        let current = ISOWeekCalendar.week(for: now)
        let isCurrent = week.number == current.number && week.year == current.year
        let calendar = ISOWeekCalendar.calendar()
        let daysRemaining = isCurrent
            ? calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: week.end).day ?? 0 : 0
        let range = week.start.formatted(.dateTime.month(.abbreviated).day().year())
            + " – " + week.end.formatted(.dateTime.month(.abbreviated).day().year())
        return WeekInfo(weekNumber: week.number, year: week.year,
                        startDate: week.start, endDate: week.end, dateRange: range,
                        daysRemaining: max(0, daysRemaining), isCurrentWeek: isCurrent)
    }

    func dates(in weekNumber: Int, year: Int) -> [Date] {
        guard let date = ISOWeekCalendar.date(week: weekNumber, year: year) else { return [] }
        return ISOWeekCalendar.week(for: date).days
    }
    func isInCurrentWeek(_ date: Date) -> Bool {
        let week = ISOWeekCalendar.week(for: date)
        let current = ISOWeekCalendar.week(for: Date())
        return week.number == current.number && week.year == current.year
    }
    func startOfWeek(for date: Date) -> Date { ISOWeekCalendar.week(for: date).start }
    func endOfWeek(for date: Date) -> Date { ISOWeekCalendar.week(for: date).end }
    func weekProgress(for date: Date = Date()) -> Double {
        let calendar = ISOWeekCalendar.calendar()
        let index = (calendar.component(.weekday, from: date) + 5) % 7
        let minutes = index * 1440 + calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        return Double(minutes) / Double(7 * 1440)
    }
    func weeksInYear(_ year: Int) -> Int { ISOWeekCalendar.weeks(in: year) }
}

// MARK: - WeekInfo Model

/// Comprehensive information about an ISO 8601 week
struct WeekInfo: Codable, Hashable {
    let weekNumber: Int
    let year: Int
    let startDate: Date
    let endDate: Date
    let dateRange: String
    let daysRemaining: Int
    let isCurrentWeek: Bool

    /// Formatted week string (e.g., "Week 48")
    var weekString: String {
        "Week \(weekNumber)"
    }

    /// Short week string (e.g., "W48")
    var shortWeekString: String {
        "W\(weekNumber)"
    }

    /// Full description (e.g., "Week 48 of 2025")
    var fullDescription: String {
        "Week \(weekNumber) of \(year)"
    }

    /// Accessibility description
    var accessibilityDescription: String {
        var description = "Week \(weekNumber), \(dateRange)"
        if isCurrentWeek {
            description += ", current week"
            if daysRemaining > 0 {
                description += ", \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining"
            }
        }
        return description
    }

    init(
        weekNumber: Int,
        year: Int,
        startDate: Date,
        endDate: Date,
        dateRange: String,
        daysRemaining: Int = 0,
        isCurrentWeek: Bool = false
    ) {
        self.weekNumber = weekNumber
        self.year = year
        self.startDate = startDate
        self.endDate = endDate
        self.dateRange = dateRange
        self.daysRemaining = daysRemaining
        self.isCurrentWeek = isCurrentWeek
    }

    /// Legacy initializer for compatibility
    init(for date: Date, localized: Bool = false) {
        let calculator = WeekCalculator.shared
        let info = calculator.weekInfo(for: date)
        self = info
    }
}

// MARK: - Extensions

extension WeekInfo {
    /// Get all dates in this week
    var dates: [Date] {
        WeekCalculator.shared.dates(in: weekNumber, year: year)
    }

    /// Check if a date is in this week
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.iso8601
        return calendar.isDate(date, equalTo: startDate, toGranularity: .weekOfYear)
    }
}
