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
    func testActualWeekHomeAndNavigation() {
        let app = launch()
        XCTAssertTrue(app.navigationBars["This Week"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["UI Test Mode"].exists)
        XCTAssertTrue(app.buttons["next-week"].exists)
        let summary = app.descendants(matching: .any)["week-summary"].firstMatch
        let original = summary.label
        app.buttons["next-week"].tap()
        XCTAssertNotEqual(summary.label, original)
        app.buttons["previous-week"].tap()
        XCTAssertEqual(summary.label, original)
        app.buttons["show-today"].tap()
        XCTAssertEqual(summary.label, original)
    }

    @MainActor
    func testLookupAndWidgetInstructions() {
        let app = launch()
        app.tabBars.buttons["Date lookup"].tap()
        XCTAssertTrue(app.navigationBars["Date lookup"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["week-date-picker"].firstMatch.exists)
        app.tabBars.buttons["Week"].tap()
        let add = app.buttons["Add a widget"]
        for _ in 0..<4 where !add.isHittable { app.swipeUp() }
        add.tap()
        XCTAssertTrue(app.navigationBars["Add a widget"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Touch and hold")).firstMatch.exists)
    }

    @MainActor
    func testSettingsRetainAccessToSavedPlanner() {
        let app = launch()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["week-theme-picker"].firstMatch.exists)
        app.swipeUp()
        XCTAssertTrue(app.buttons["Open saved planner"].exists)
    }
}
