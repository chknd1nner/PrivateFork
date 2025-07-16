import XCTest
import Combine
@testable import PrivateFork

@MainActor
final class MainViewIntegrationTests: XCTestCase {

    var viewModel: MainViewModel!
    var mockKeychainService: MockKeychainService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        viewModel = MainViewModel(keychainService: mockKeychainService)
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockKeychainService = nil
        super.tearDown()
    }

    // MARK: - Complete User Flow Tests

    func testCompleteUserFlowFromURLInputToForkCreation() async {
        // Given - Start with clean state
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertEqual(viewModel.statusMessage, "Ready.")

        // When - Configure credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Then - UI should be enabled
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertTrue(viewModel.isUIEnabled)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")

        // When - Enter valid repository URL
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000) // Wait for URL validation

        // Then - URL should be valid
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")

        // When - Select directory
        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        // Then - Fork button should be enabled
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        // When - Create fork
        let forkTask = Task {
            await viewModel.createPrivateFork()
        }

        // Wait for fork to start
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - Should be in progress and button disabled
        XCTAssertTrue(viewModel.isForking)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertNotEqual(viewModel.statusMessage, "Ready.")

        // Wait for completion
        await forkTask.value

        // Then - Should be complete and ready for next operation
        XCTAssertFalse(viewModel.isForking)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
    }

    func testUserFlowWithMissingCredentials() async {
        // Given - No credentials configured
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()

        // When - Try to enter URL and select directory
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        // Then - UI should be disabled and fork button unavailable
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertFalse(viewModel.isUIEnabled)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
    }

    func testUserFlowWithInvalidURL() async {
        // Given - Credentials configured
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // When - Enter invalid URL
        viewModel.updateRepositoryURL("https://gitlab.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        // Then - Fork button should be disabled due to invalid URL
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertTrue(viewModel.isUIEnabled)
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a GitHub repository URL")
    }

    func testUserFlowWithoutDirectorySelection() async {
        // Given - Credentials configured and valid URL
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        // When - No directory selected
        XCTAssertFalse(viewModel.hasSelectedDirectory)

        // Then - Fork button should be disabled
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    // MARK: - Settings Integration Tests

    func testSettingsWorkflowIntegration() async {
        // Given - Start without credentials
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.hasCredentials)

        // When - Open settings
        viewModel.showSettings()
        XCTAssertTrue(viewModel.isShowingSettings)

        // Simulate user configuring credentials in settings
        mockKeychainService.setStoredCredentials(username: "newuser", token: "newtoken")

        // And close settings
        viewModel.hideSettings()
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for credentials check

        // Then - Credentials should be detected and UI enabled
        XCTAssertFalse(viewModel.isShowingSettings)
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertTrue(viewModel.isUIEnabled)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")
    }

    // MARK: - State Synchronization Tests

    func testCredentialsUIStateSynchronization() async {
        // Given - Monitor UI state changes
        var uiStateUpdates: [Bool] = []
        let expectation = XCTestExpectation(description: "UI state should update")

        viewModel.$isUIEnabled.sink { isEnabled in
            uiStateUpdates.append(isEnabled)
            if uiStateUpdates.count >= 2 { // Initial false + true after credentials
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        // When - Add credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Then - UI state should update
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(uiStateUpdates.first, false) // Initial state
        XCTAssertEqual(uiStateUpdates.last, true)   // After credentials
        XCTAssertTrue(viewModel.isUIEnabled)
    }

    func testForkButtonStateSynchronization() async {
        // Given - Set up for fork button to be enabled
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        // Verify fork button is enabled
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        // When - Start fork operation
        let forkTask = Task {
            await viewModel.createPrivateFork()
        }

        // Monitor button state changes
        var buttonStateUpdates: [Bool] = []
        let expectation = XCTestExpectation(description: "Button state should update")

        viewModel.$isCreateButtonEnabled.sink { isEnabled in
            buttonStateUpdates.append(isEnabled)
            if buttonStateUpdates.count >= 3 { // true -> false -> true
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        // Wait for fork completion
        await forkTask.value

        // Then - Button state should cycle: enabled -> disabled -> enabled
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertTrue(buttonStateUpdates.contains(true))  // Initially enabled
        XCTAssertTrue(buttonStateUpdates.contains(false)) // Disabled during fork
        XCTAssertTrue(viewModel.isCreateButtonEnabled)    // Re-enabled after completion
    }

    // MARK: - Real-time Status Updates Integration

    func testStatusUpdateDuringForkOperation() async {
        // Given - Set up for fork operation
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        // Monitor status updates
        var statusUpdates: [String] = []
        let expectation = XCTestExpectation(description: "Status should update multiple times")

        viewModel.$statusMessage.sink { status in
            statusUpdates.append(status)
            if status == "Ready." && statusUpdates.count > 5 { // Back to ready after fork
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        // When - Perform fork operation
        await viewModel.createPrivateFork()

        // Then - Should have multiple status updates
        await fulfillment(of: [expectation], timeout: 10.0)
        XCTAssertGreaterThan(statusUpdates.count, 5)
        XCTAssertTrue(statusUpdates.contains("Preparing to create private fork..."))
        XCTAssertTrue(statusUpdates.contains("Validating repository access..."))
        XCTAssertTrue(statusUpdates.contains("Creating private fork..."))
        XCTAssertTrue(statusUpdates.contains("Cloning repository..."))
        XCTAssertTrue(statusUpdates.contains("Fork created successfully!"))
        XCTAssertEqual(statusUpdates.last, "Ready.")
    }

    // MARK: - Error Handling Integration

    func testForkOperationWhenPrerequisitesRemoved() async {
        // Given - Set up for valid fork operation
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        try? await Task.sleep(nanoseconds: 400_000_000)

        viewModel.localPath = "/Users/testuser/Projects"
        viewModel.hasSelectedDirectory = true

        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        // When - Remove credentials before fork (simulate external change)
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()

        // Then - Fork button should be disabled
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        // And fork operation should not proceed
        await viewModel.createPrivateFork()
        XCTAssertFalse(viewModel.isForking)
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
    }
}