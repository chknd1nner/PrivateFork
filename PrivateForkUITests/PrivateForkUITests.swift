import XCTest

final class PrivateForkUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchAndCoreUIElements() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING_MODE"]
        app.launch()

        // Verify main window and app title exist
        XCTAssertTrue(app.staticTexts["PrivateFork"].exists, "App title should be displayed")

        // Verify core UI elements are present and accessible
        XCTAssertTrue(app.buttons["Settings"].exists, "Settings button should be accessible")
        XCTAssertTrue(app.textFields.containing(.any, identifier: "repository-url-field").element.exists ||
                     app.textFields.matching(identifier: "repository-url-field").firstMatch.exists ||
                     app.textFields.firstMatch.exists, "Repository URL field should be present")
        XCTAssertTrue(app.buttons["Select Folder"].exists, "Directory selection button should be accessible")
        XCTAssertTrue(app.buttons["Create Private Fork"].exists, "Create fork button should be present")
    }

    @MainActor
    func testSettingsWorkflow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING_MODE"]
        app.launch()

        // Test settings button opens settings sheet
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")

        settingsButton.tap()

        // Verify settings sheet appears with expected elements
        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 2), "Settings sheet should appear")
        XCTAssertTrue(app.textFields.containing(.any, identifier: "username").element.exists ||
                     app.textFields.firstMatch.exists, "Username field should be present in settings")

        // Test dismissing settings sheet
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()
        } else {
            // Alternative dismissal method if Cancel button not found
            app.keyboards.keys["Escape"].tap()
        }

        // Verify settings sheet is dismissed
        XCTAssertFalse(app.sheets.firstMatch.exists, "Settings sheet should be dismissed")
    }

    @MainActor
    func testRepositoryURLValidation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING_MODE"]
        app.launch()

        // Find the repository URL field
        let urlField = app.textFields.firstMatch
        XCTAssertTrue(urlField.exists, "Repository URL field should exist")

        // Test URL field interaction
        urlField.tap()
        urlField.typeText("https://github.com/user/repo")

        // Verify text was entered (basic validation that field accepts input)
        XCTAssertTrue(urlField.value as? String != "", "URL field should accept text input")

        // Clear field for next test
        urlField.tap()
        urlField.typeKey("a", modifierFlags: .command)
        urlField.typeText("")
    }
}
