import XCTest
@testable import Vecka

final class ISOWeekCalendarTests: XCTestCase {
    private let utc = TimeZone(secondsFromGMT: 0)!

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12,
                      zone: TimeZone? = nil) -> Date {
        ISOWeekCalendar.calendar(timeZone: zone ?? utc)
            .date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testKnownNewYearBoundaries() {
        let cases = [(2016, 1, 1, 53, 2015), (2021, 1, 1, 53, 2020),
                     (2027, 1, 1, 53, 2026), (2024, 12, 30, 1, 2025)]
        for (year, month, day, number, weekYear) in cases {
            let week = ISOWeekCalendar.week(for: date(year, month, day), timeZone: utc)
            XCTAssertEqual(week.number, number)
            XCTAssertEqual(week.year, weekYear)
            XCTAssertEqual(week.days.count, 7)
            XCTAssertEqual(ISOWeekCalendar.calendar(timeZone: utc).component(.weekday, from: week.start), 2)
        }
    }

    func testAllWeeksRoundTripAcrossGregorianCycle() {
        for year in 2000..<2400 {
            let count = ISOWeekCalendar.weeks(in: year, timeZone: utc)
            XCTAssertTrue(count == 52 || count == 53)
            for number in 1...count {
                guard let date = ISOWeekCalendar.date(week: number, year: year, timeZone: utc) else {
                    return XCTFail("Missing week \(year)/\(number)")
                }
                let week = ISOWeekCalendar.week(for: date, timeZone: utc)
                XCTAssertEqual(week.number, number)
                XCTAssertEqual(week.year, year)
            }
        }
    }

    func testInvalidWeeksAreNotSilentlyNormalised() {
        XCTAssertNil(ISOWeekCalendar.date(week: 53, year: 2021, timeZone: utc))
        XCTAssertNil(ISOWeekCalendar.date(week: 0, year: 2026, timeZone: utc))
        XCTAssertNil(ISOWeekCalendar.date(week: 54, year: 2026, timeZone: utc))
        XCTAssertNil(ISOWeekCalendar.date(week: 1, year: 0, timeZone: utc))
        XCTAssertEqual(ISOWeekCalendar.weeks(in: 2026, timeZone: utc), 53)
    }

    func testLocalTimeZoneCanChangeTheWeekAtTheSameInstant() {
        let instant = date(2026, 1, 4, hour: 23)
        let stockholm = TimeZone(identifier: "Europe/Stockholm")!
        XCTAssertEqual(ISOWeekCalendar.week(for: instant, timeZone: utc).number, 1)
        XCTAssertEqual(ISOWeekCalendar.week(for: instant, timeZone: stockholm).number, 2)
    }

    func testTimelineCrossesDSTAtLocalMidnight() {
        let zone = TimeZone(identifier: "Europe/Stockholm")!
        for (month, day, expectedHours) in [(3, 28, 23), (10, 24, 25)] {
            let now = date(2026, month, day, zone: zone)
            let entries = ISOWeekCalendar.timelineDates(from: now, timeZone: zone)
            XCTAssertEqual(entries.count, 15)
            XCTAssertEqual(entries.first, now)
            XCTAssertEqual(entries[2].timeIntervalSince(entries[1]), Double(expectedHours * 3600))
            for midnight in entries.dropFirst() {
                XCTAssertEqual(ISOWeekCalendar.calendar(timeZone: zone).component(.hour, from: midnight), 0)
            }
            XCTAssertEqual(entries, entries.sorted())
        }
    }

    func testTimelineIncludesNextWeekAndYear() {
        let entries = ISOWeekCalendar.timelineDates(from: date(2026, 12, 31), timeZone: utc)
        XCTAssertTrue(entries.contains { ISOWeekCalendar.week(for: $0, timeZone: utc).year == 2027 })
        XCTAssertEqual(ISOWeekCalendar.timelineDates(from: Date(), days: 0).count, 1)
    }

    func testMonthGridCoversEveryDateIncludingSixRowMonth() {
        let calendar = ISOWeekCalendar.calendar(timeZone: utc)
        for month in 1...12 {
            let reference = date(2026, month, 15)
            let weeks = ISOWeekCalendar.monthWeeks(for: reference, timeZone: utc)
            XCTAssertTrue((4...6).contains(weeks.count))
            let days = weeks.flatMap(\.days).filter { calendar.component(.month, from: $0) == month }
            XCTAssertEqual(days.count, calendar.range(of: .day, in: .month, for: reference)?.count)
            XCTAssertEqual(Set(days).count, days.count)
        }
        XCTAssertEqual(ISOWeekCalendar.monthWeeks(for: date(2026, 3, 15), timeZone: utc).count, 6)
    }

    func testWeekInfoDoesNotCacheTodaysState() {
        let calendar = ISOWeekCalendar.calendar()
        let monday = calendar.date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 12))!
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)!
        XCTAssertEqual(WeekCalculator.shared.weekInfo(for: monday, now: monday).daysRemaining, 6)
        XCTAssertEqual(WeekCalculator.shared.weekInfo(for: monday, now: tuesday).daysRemaining, 5)
        XCTAssertFalse(WeekCalculator.shared.weekInfo(for: monday, now: nextMonday).isCurrentWeek)
    }

    func testInvalidAppearanceFallsBackToApple() {
        XCTAssertEqual(WeekAppearance.resolve("missing"), .apple)
        XCTAssertEqual(WeekAppearance.allCases.map(\.rawValue), ["apple", "muji", "note", "kinto"])
    }
}
