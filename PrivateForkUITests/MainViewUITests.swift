import XCTest

final class MainViewUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testMainViewLaunches() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Verify that the main title is displayed
        XCTAssertTrue(app.staticTexts["PrivateFork"].exists)
        
        // Verify that the subtitle is displayed
        XCTAssertTrue(app.staticTexts["Create private mirrors of GitHub repositories"].exists)
    }
}