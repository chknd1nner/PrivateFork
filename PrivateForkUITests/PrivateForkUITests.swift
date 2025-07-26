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
        XCTAssertTrue(app.textFields["repository-url-field"].exists, "Repository URL field should be present")
        XCTAssertTrue(app.buttons["select-folder-button"].exists, "Directory selection button should be accessible")
        XCTAssertTrue(app.buttons["create-private-fork-button"].exists, "Create fork button should be present")
    }


    @MainActor
    func testRepositoryURLValidation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UI_TESTING_MODE"]
        app.launch()

        // Find the repository URL field
        let urlField = app.textFields["repository-url-field"]
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
