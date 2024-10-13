//
//  heynoahUITests.swift
//  heynoahUITests
//
//  Created by Juan San Emeterio on 10/13/24.
//

import XCTest

final class HeyNoahUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testLaunchApp() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.isHittable, "The app should be hittable after launch.")
    }

    @MainActor
    func testToggleDarkMode() throws {
        let app = XCUIApplication()
        app.launch()

        let gearButton = app.buttons["gear"]
        XCTAssertTrue(gearButton.exists, "Gear button should exist on the main screen.")
        gearButton.tap()

        let darkModeToggle = app.switches["Dark Mode"]
        XCTAssertTrue(darkModeToggle.exists, "Dark Mode toggle should exist in settings.")
        let initialValue = darkModeToggle.value as? String
        darkModeToggle.tap()
        let newValue = darkModeToggle.value as? String

        XCTAssertNotEqual(initialValue, newValue, "Dark Mode toggle value should change after tapping.")
    }

    @MainActor
    func testAdjustFontSize() throws {
        let app = XCUIApplication()
        app.launch()

        let gearButton = app.buttons["gear"]
        XCTAssertTrue(gearButton.exists, "Gear button should exist on the main screen.")
        gearButton.tap()

        let fontSizeSlider = app.sliders.firstMatch
        XCTAssertTrue(fontSizeSlider.exists, "Font size slider should exist in settings.")
        fontSizeSlider.adjust(toNormalizedSliderPosition: 0.8)
        XCTAssertTrue(fontSizeSlider.exists, "Font size slider should still exist after adjustment.")
    }

    @MainActor
    func testChangeCustomName() throws {
        let app = XCUIApplication()
        app.launch()

        let gearButton = app.buttons["gear"]
        XCTAssertTrue(gearButton.exists, "Gear button should exist on the main screen.")
        gearButton.tap()

        let customNameField = app.textFields["Custom Name"]
        XCTAssertTrue(customNameField.exists, "Custom name text field should exist in settings.")
        customNameField.tap()
        customNameField.typeText("Alice")

        XCTAssertEqual(customNameField.value as? String, "Alice", "The custom name text field should display the entered name.")
    }

    @MainActor
    func testNotificationPermissionRequest() throws {
        let app = XCUIApplication()
        app.launch()

        // Assuming the app requests notification permissions on launch
        addUIInterruptionMonitor(withDescription: "Notification Permission Alert") { alert -> Bool in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            return false
        }

        app.tap() // Trigger the interruption handler
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
