import XCTest

final class MacUITests: XCTestCase {
    @MainActor
    func testWindowWeekNavigationAndDateLookup() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        let summary = app.descendants(matching: .any)["week-summary"].firstMatch
        XCTAssertTrue(summary.exists)
        let original = summary.label
        app.buttons["next-week"].tap()
        XCTAssertNotEqual(summary.label, original)
        app.buttons["previous-week"].tap()
        XCTAssertEqual(summary.label, original)
        app.typeKey("f", modifierFlags: .command)
        XCTAssertTrue(app.descendants(matching: .any)["week-date-picker"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(summary.exists)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Native macOS week window"
        capture.lifetime = .keepAlways
        add(capture)
    }
    @MainActor
    func testNativeSettingsShortcut() {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10))
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(app.descendants(matching: .any)["week-theme-picker"].firstMatch.waitForExistence(timeout: 5))
    }
}
