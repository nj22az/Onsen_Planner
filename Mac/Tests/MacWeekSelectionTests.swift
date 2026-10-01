import XCTest
@testable import OnsenPlannerMac

final class MacWeekSelectionTests: XCTestCase {
    let utc = TimeZone(secondsFromGMT: 0)!
    func testYearBoundaryNavigationPreservesISOYear() throws {
        let start = try XCTUnwrap(ISOWeekCalendar.date(week: 53, year: 2020, timeZone: utc))
        var selection = MacWeekSelection(date: start)
        selection.move(1, now: start, timeZone: utc)
        let next = ISOWeekCalendar.week(for: selection.resolved(now: start), timeZone: utc)
        XCTAssertEqual(next.number, 1)
        XCTAssertEqual(next.year, 2021)
        selection.move(-1, now: start, timeZone: utc)
        XCTAssertEqual(selection.date, start)
    }
    func testTodayFollowsTimeButBrowsedWeekStaysSelected() throws {
        let start = try XCTUnwrap(ISOWeekCalendar.date(week: 40, year: 2026, timeZone: utc))
        let later = start.addingTimeInterval(604800)
        var selection = MacWeekSelection()
        XCTAssertEqual(selection.resolved(now: later), later)
        selection.move(1, now: start, timeZone: utc)
        XCTAssertEqual(selection.resolved(now: later.addingTimeInterval(604800)), later)
        selection.today()
        XCTAssertEqual(selection.resolved(now: start), start)
    }
    func testInvalidLinkCannotReplaceSelection() throws {
        let start = try XCTUnwrap(ISOWeekCalendar.date(week: 40, year: 2026, timeZone: utc))
        var selection = MacWeekSelection(date: start)
        for value in ["vecka://week/53/2021", "vecka://week/0/2026", "vecka://week/40/bad", "https://week/40/2026", "vecka://facts/foo"] {
            XCTAssertFalse(selection.open(URL(string: value)!, now: start, timeZone: utc))
            XCTAssertEqual(selection.date, start)
        }
        XCTAssertTrue(selection.open(URL(string: "vecka://today")!, now: start, timeZone: utc))
        XCTAssertNil(selection.date)
    }
    func testWidgetLinkUsesExplicitISOYear() throws {
        let now = Date()
        var selection = MacWeekSelection()
        XCTAssertTrue(selection.open(URL(string: "vecka://week/53/2020")!, now: now, timeZone: utc))
        XCTAssertEqual(selection.date, ISOWeekCalendar.date(week: 53, year: 2020, timeZone: utc))
    }
    func testWindowsHaveIndependentSelections() {
        var first = MacWeekSelection()
        let second = MacWeekSelection()
        first.move(1, now: Date(), timeZone: utc)
        XCTAssertNotEqual(first, second)
        XCTAssertNil(second.date)
    }
    func testDSTMidnightsAndMonthCoverage() throws {
        let zone = try XCTUnwrap(TimeZone(identifier: "Europe/Stockholm"))
        let calendar = ISOWeekCalendar.calendar(timeZone: zone)
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 12)))
        let dates = ISOWeekCalendar.timelineDates(from: start, timeZone: zone)
        XCTAssertEqual(dates.count, 15)
        XCTAssertEqual(dates[2].timeIntervalSince(dates[1]), 23 * 3600)
        let weeks = ISOWeekCalendar.monthWeeks(for: start, timeZone: zone)
        XCTAssertEqual(weeks.count, 6)
        XCTAssertEqual(Set(weeks.flatMap(\.days).filter { calendar.component(.month, from: $0) == 3 }).count, 31)
    }
}
