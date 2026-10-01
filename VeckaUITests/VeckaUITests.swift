import XCTest

final class VeckaUITests: XCTestCase {
    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }
    @MainActor
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor
    func testActualWeekHomeAndNavigation() {
        let app = launch()
        XCTAssertTrue(app.navigationBars["This Week"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["UI Test Mode"].exists)
        XCTAssertEqual(app.tabBars.buttons.count, 2)
        let summary = app.descendants(matching: .any)["week-summary"].firstMatch
        let original = summary.label
        app.buttons["next-week"].tap()
        XCTAssertNotEqual(summary.label, original)
        app.buttons["previous-week"].tap()
        XCTAssertEqual(summary.label, original)
        app.buttons["show-today"].tap()
        XCTAssertEqual(summary.label, original)
        XCTAssertTrue(app.descendants(matching: .any)["week-month"].firstMatch.exists)
        capture(app, name: "Week — Apple default")
    }
    @MainActor
    func testLookupCancellationAndApplyReturnToWeek() {
        let app = launch()
        app.buttons["open-date-lookup"].tap()
        XCTAssertTrue(app.navigationBars["Date lookup"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["week-date-picker"].firstMatch.exists)
        capture(app, name: "Date lookup")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["This Week"].exists)
        app.buttons["open-date-lookup"].tap()
        app.buttons["Show week"].tap()
        XCTAssertTrue(app.navigationBars["This Week"].exists)
    }
    @MainActor
    func testGalleryAndWidgetInstructions() {
        let app = launch()
        app.tabBars.buttons["Widgets"].tap()
        XCTAssertTrue(app.navigationBars["Widgets"].exists)
        capture(app, name: "Free widget gallery")
        let add = app.buttons["Add a widget"]
        for _ in 0..<6 where !add.isHittable { app.swipeUp() }
        add.tap()
        XCTAssertTrue(app.navigationBars["Add a widget"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Touch and hold")).firstMatch.exists)
    }
    @MainActor
    func testSettingsRetainAccessToSavedPlanner() {
        let app = launch()
        app.buttons["utility-menu"].tap()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["week-theme-picker"].firstMatch.exists)
        capture(app, name: "Settings")
        let open = app.buttons["Open saved planner"]
        for _ in 0..<4 where !open.isHittable { app.swipeUp() }
        XCTAssertTrue(open.exists)
    }
    @MainActor
    func testAddOnsArePreviewableWithoutSales() {
        let app = launch()
        app.buttons["utility-menu"].tap()
        app.buttons["Add-ons"].tap()
        XCTAssertTrue(app.navigationBars["Add-ons"].exists)
        capture(app, name: "Widget Studio preview — sales disabled")
        app.swipeUp()
        XCTAssertFalse(app.buttons["Buy once"].exists)
        XCTAssertTrue(app.buttons["Restore purchases"].exists)
    }
}
