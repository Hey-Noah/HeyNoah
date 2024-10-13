//
//  heynoahTests.swift
//  heynoahTests
//
//  Created by Juan San Emeterio on 10/13/24.
//

import XCTest
@testable import heynoah

class HeyNoahTests: XCTestCase {

    func testCustomNameRecognition() async throws {
        let speechService = SpeechService()
        let notificationService = NotificationService()
        let transcriptionViewController = TranscriptionViewController(speechService: speechService, notificationService: notificationService)
        transcriptionViewController.customName = "John"

        let expectation = XCTestExpectation(description: "Notification is sent when the custom name is recognized")

        notificationService.requestNotificationAuthorization { granted in
            if granted {
                speechService.startTranscription { transcription, error in
                    if transcription?.localizedCaseInsensitiveContains("John") == true {
                        notificationService.sendNotification(title: "Someone is speaking to you, John!", identifier: "JohnNotification")
                        expectation.fulfill()
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }

    func testDarkModeToggle() {
        let contentView = ContentView()
        var isDarkMode = false
        contentView.isDarkMode = isDarkMode

        isDarkMode.toggle()
        contentView.isDarkMode = isDarkMode

        XCTAssertEqual(contentView.isDarkMode, true, "The dark mode toggle should successfully update the state.")
    }

    func testFontSizeSlider() {
        let contentView = ContentView()
        let newFontSize: CGFloat = 40
        contentView.fontSize = newFontSize

        XCTAssertEqual(contentView.fontSize, newFontSize, "The font size slider should update the font size state correctly.")
    }

    func testCustomNameChange() {
        let contentView = ContentView()
        let newName = "Alice"
        contentView.customName = newName

        XCTAssertEqual(contentView.customName, newName, "The custom name text field should successfully update the name that the app listens for.")
    }

    func testNotificationAuthorization() async throws {
        let notificationService = NotificationService()
        let expectation = XCTestExpectation(description: "Notification authorization is requested and granted")

        notificationService.requestNotificationAuthorization { granted in
            XCTAssertTrue(granted, "Notification authorization should be granted.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
