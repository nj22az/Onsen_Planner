import XCTest
import SwiftData
import Observation
@testable import Vecka

@MainActor
final class HolidayRefreshTests: XCTestCase {
    private func withRules(_ body: (ModelContext, HolidayManager) async throws -> Void) async throws {
        let keys = ["showHolidays", "holidayRegions"]
        let previous = keys.map { UserDefaults.standard.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { UserDefaults.standard.set(value, forKey: key) }
                else { UserDefaults.standard.removeObject(forKey: key) }
            }
        }
        UserDefaults.standard.set(true, forKey: "showHolidays")
        UserDefaults.standard.set("SE", forKey: "holidayRegions")
        let schema = Schema([HolidayRule.self, AppConfiguration.self])
        let container = try ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        ])
        let context = container.mainContext
        context.insert(HolidayRule(name: "First", region: "SE", isBankHoliday: true, type: .fixed, month: 1, day: 3))
        context.insert(HolidayRule(name: "Second", region: "VN", isBankHoliday: false, type: .fixed, month: 2, day: 4))
        try context.save()
        try await body(context, HolidayManager.shared)
    }

    func testCompletionNotifiesObserversAndPublishesNewData() async throws {
        try await withRules { context, manager in
            let changed = expectation(description: "Calendar observes completed cache")
            withObservationTracking {
                _ = manager.holidayCache
            } onChange: {
                changed.fulfill()
            }
            let task = manager.calculateAndCacheHolidays(context: context)
            await task?.value
            await fulfillment(of: [changed], timeout: 1)
            XCTAssertTrue(manager.holidayCache.values.flatMap { $0 }.contains { $0.name == "First" })
            XCTAssertFalse(manager.isCalculating)
        }
    }

    func testSupersededRegionDoesNotPublish() async throws {
        try await withRules { context, manager in
            let revision = manager.cacheRevision
            let first = manager.calculateAndCacheHolidays(context: context, focusYear: 2030)
            UserDefaults.standard.set("VN", forKey: "holidayRegions")
            let second = manager.calculateAndCacheHolidays(context: context, focusYear: 2040)
            await first?.value
            await second?.value
            XCTAssertEqual(manager.cacheRevision, revision + 1)
            let items = manager.holidayCache.values.flatMap { $0 }
            XCTAssertTrue(items.contains { $0.name == "Second" })
            XCTAssertFalse(items.contains { $0.name == "First" })
        }
    }

    func testDisablingHolidaysInvalidatesInFlightResult() async throws {
        try await withRules { context, manager in
            let task = manager.calculateAndCacheHolidays(context: context)
            UserDefaults.standard.set(false, forKey: "showHolidays")
            XCTAssertNil(manager.calculateAndCacheHolidays(context: context))
            let revision = manager.cacheRevision
            await task?.value
            XCTAssertTrue(manager.holidayCache.isEmpty)
            XCTAssertEqual(manager.cacheRevision, revision)
            XCTAssertFalse(manager.isCalculating)
        }
    }
}
