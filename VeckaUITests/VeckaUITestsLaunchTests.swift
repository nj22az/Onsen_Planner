//
//  VeckaUITestsLaunchTests.swift
//  VeckaUITests
//
//  Created by Nils Johansson on 2025-08-09.
//

import XCTest

final class VeckaUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-disable-animations"]
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["week-summary"].firstMatch.waitForExistence(timeout: 10))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
