//
//  heynoahUITestsLaunchTests.swift
//  heynoahUITests
//
//  Created by Juan San Emeterio on 10/13/24.
//

import XCTest

final class HeyNoahUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let gearButton = app.buttons["gear"]
        if gearButton.exists {
            gearButton.tap()
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}