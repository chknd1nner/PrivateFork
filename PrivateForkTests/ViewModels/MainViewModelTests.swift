import XCTest
import Combine
@testable import PrivateFork

@MainActor
final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel!
    var mockKeychainService: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        viewModel = MainViewModel(keychainService: mockKeychainService)
        viewModel.setDebounceInterval(0) // Disable debouncing for faster tests
    }

    override func tearDown() {
        viewModel = nil
        mockKeychainService = nil
        super.tearDown()
    }

    func testInitialization() async {
        // Given, When
        let mockService = MockKeychainService()
        let viewModel = MainViewModel(keychainService: mockService)

        // Explicitly initialize credentials check (lazy initialization)
        await viewModel.initializeCredentialsCheck()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.repoURL, "")
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "")
        XCTAssertFalse(viewModel.isShowingSettings)
        XCTAssertEqual(viewModel.localPath, "")
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
    }

    // MARK: - URL Validation Tests

    func testValidGitHubURL() async {
        // Given
        let validURL = "https://github.com/owner/repository"

        // When
        viewModel.updateRepositoryURL(validURL)
        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertEqual(viewModel.repoURL, validURL)
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testValidGitHubURLWithWWW() async {
        // Given
        let validURL = "https://www.github.com/owner/repository"

        // When
        viewModel.updateRepositoryURL(validURL)
        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testValidGitHubURLWithSubpaths() async {
        // Given
        let validURL = "https://github.com/owner/repository/tree/main"

        // When
        viewModel.updateRepositoryURL(validURL)
        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testEmptyURL() async {
        // Given
        let emptyURL = ""

        // When
        viewModel.updateRepositoryURL(emptyURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a repository URL")
    }

    func testWhitespaceOnlyURL() async {
        // Given
        let whitespaceURL = "   \n\t   "

        // When
        viewModel.updateRepositoryURL(whitespaceURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a repository URL")
    }

    func testInvalidURL() async {
        // Given
        let invalidURL = "not-a-url"

        // When
        viewModel.updateRepositoryURL(invalidURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid URL format")
    }

    func testNonGitHubURL() async {
        // Given
        let nonGitHubURL = "https://gitlab.com/owner/repository"

        // When
        viewModel.updateRepositoryURL(nonGitHubURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a GitHub repository URL")
    }

    func testGitHubURLWithoutRepository() async {
        // Given
        let incompleteURL = "https://github.com/"

        // When
        viewModel.updateRepositoryURL(incompleteURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(
            viewModel.urlValidationMessage,
            "Invalid repository path. Expected format: github.com/owner/repository"
        )
    }

    func testGitHubURLWithOnlyOwner() async {
        // Given
        let incompleteURL = "https://github.com/owner"

        // When
        viewModel.updateRepositoryURL(incompleteURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(
            viewModel.urlValidationMessage,
            "Invalid repository path. Expected format: github.com/owner/repository"
        )
    }

    func testGitHubURLWithInvalidCharacters() async {
        // Given
        let invalidURL = "https://github.com/owner@$/repository#$"

        // When
        viewModel.updateRepositoryURL(invalidURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(
            viewModel.urlValidationMessage,
            "Invalid repository path. Expected format: github.com/owner/repository"
        )
    }

    func testValidGitHubURLWithValidSpecialCharacters() async {
        // Given
        let validURL = "https://github.com/owner-name/repository.name"

        // When
        viewModel.updateRepositoryURL(validURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testValidGitHubURLWithUnderscores() async {
        // Given
        let validURL = "https://github.com/owner_name/repository_name"

        // When
        viewModel.updateRepositoryURL(validURL)

        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    // MARK: - Debouncing Tests

    func testDebouncingBehavior() async {
        // Given - Set a small debounce interval to test the behavior
        viewModel.setDebounceInterval(0.1) // Short interval for test
        let initialURL = "https://github.com/owner/repo"
        let finalURL = "https://github.com/owner/repository"

        // When - Update URL multiple times quickly
        viewModel.updateRepositoryURL("h")
        viewModel.updateRepositoryURL("ht")
        viewModel.updateRepositoryURL("htt")
        viewModel.updateRepositoryURL(initialURL)
        viewModel.updateRepositoryURL(finalURL)

        // Wait for debounced validation (should only validate the final URL)
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        // Then
        XCTAssertEqual(viewModel.repoURL, finalURL)
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testMultipleValidationCalls() async {
        // Given
        let validURL = "https://github.com/owner/repository"

        // When - Multiple separate validation calls
        viewModel.updateRepositoryURL(validURL)
        await Task.yield() // Allow the validation task to run immediately

        // Verify first validation
        XCTAssertTrue(viewModel.isValidURL)

        // Update with invalid URL
        viewModel.updateRepositoryURL("invalid")
        await Task.yield() // Allow the validation task to run immediately

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid URL format")
    }

    // MARK: - Settings Tests

    func testShowSettings() {
        // Given
        XCTAssertFalse(viewModel.isShowingSettings)

        // When
        viewModel.showSettings()

        // Then
        XCTAssertTrue(viewModel.isShowingSettings)
    }

    func testHideSettings() {
        // Given
        viewModel.showSettings()
        XCTAssertTrue(viewModel.isShowingSettings)

        // When
        viewModel.hideSettings()

        // Then
        XCTAssertFalse(viewModel.isShowingSettings)
    }

    // MARK: - Directory Selection Tests

    func testInitialDirectoryState() {
        // Given the viewModel from setUp (configured with MockKeychainService)

        // Then
        XCTAssertEqual(viewModel.localPath, "")
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertEqual(viewModel.getFormattedPath(), "No folder selected")
    }

    func testFormattedPathWithEmptyPath() {
        // Given
        viewModel.localPath = ""

        // When
        let formattedPath = viewModel.getFormattedPath()

        // Then
        XCTAssertEqual(formattedPath, "No folder selected")
    }

    func testFormattedPathWithRootPath() {
        // Given
        viewModel.localPath = "/Applications"

        // When
        let formattedPath = viewModel.getFormattedPath()

        // Then
        XCTAssertEqual(formattedPath, "Applications")
    }

    func testFormattedPathWithNestedPath() {
        // Given
        viewModel.localPath = "/Users/testuser/Documents/MyProject"

        // When
        let formattedPath = viewModel.getFormattedPath()

        // Then
        XCTAssertEqual(formattedPath, "/Users/testuser/Documents/MyProject")
    }

    func testFormattedPathWithHomePath() {
        // Given
        viewModel.localPath = "/Users/testuser/Desktop"

        // When
        let formattedPath = viewModel.getFormattedPath()

        // Then
        XCTAssertEqual(formattedPath, "/Users/testuser/Desktop")
    }

    func testDirectorySelectionStateUpdates() {
        // Given
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertEqual(viewModel.localPath, "")

        // When - Simulate successful directory selection
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Then
        XCTAssertTrue(viewModel.hasSelectedDirectory)
        XCTAssertEqual(viewModel.localPath, "/Users/testuser/Documents")
        XCTAssertEqual(viewModel.getFormattedPath(), "/Users/testuser/Documents")
    }

    // Note: Testing actual NSOpenPanel behavior requires UI testing framework
    // These tests focus on the state management and path formatting logic

    func testPathDisplayAfterSelection() {
        // Given
        let testPath = "/Users/testuser/Projects/MyApp"

        // When
        viewModel.localPath = testPath
        viewModel.hasSelectedDirectory = true

        // Then
        XCTAssertEqual(viewModel.localPath, testPath)
        XCTAssertTrue(viewModel.hasSelectedDirectory)
        XCTAssertNotEqual(viewModel.getFormattedPath(), "No folder selected")
    }

    func testDirectorySelectionReset() {
        // Given - Directory already selected
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // When - Reset state
        viewModel.localPath = ""
        viewModel.hasSelectedDirectory = false

        // Then
        XCTAssertEqual(viewModel.localPath, "")
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertEqual(viewModel.getFormattedPath(), "No folder selected")
    }

    // MARK: - Credentials Tests

    func testCredentialsStatusWhenNotConfigured() async {
        // Given
        mockKeychainService.clearStoredCredentials()

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
    }

    func testCredentialsStatusWhenConfigured() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")
    }

    func testCredentialsStatusWhenKeychainError() async {
        // Given
        mockKeychainService.shouldFailRetrieve = true

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
    }

    func testCredentialsStatusWhenUnexpectedError() async {
        // Given
        mockKeychainService.shouldFailRetrieve = true

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertTrue(viewModel.credentialsStatusMessage.contains("GitHub credentials not configured"))
    }

    func testHideSettingsTriggersCredentialsCheck() async {
        // Given
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.hasCredentials)

        // Configure credentials while settings are "open"
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")

        // When
        viewModel.hideSettings()

        // Wait for credentials check
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")
    }

    // MARK: - UI State Management Tests

    func testIsUIEnabledWhenCredentialsConfigured() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertTrue(viewModel.isUIEnabled)
    }

    func testIsUIEnabledWhenCredentialsNotConfigured() async {
        // Given
        mockKeychainService.clearStoredCredentials()

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.isUIEnabled)
    }

    func testIsCreateButtonEnabledWhenAllConditionsMet() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Set up valid URL
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        // Set up directory selection
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // When, Then
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testIsCreateButtonEnabledWhenCredentialsMissing() async {
        // Given
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()

        // Set up valid URL
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        // Set up directory selection
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // When, Then
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testIsCreateButtonEnabledWhenURLInvalid() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Set up invalid URL
        viewModel.updateRepositoryURL("invalid-url")
        await Task.yield() // Allow the validation task to run immediately

        // Set up directory selection
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // When, Then
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testIsCreateButtonEnabledWhenDirectoryNotSelected() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Set up valid URL
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        // No directory selected
        viewModel.hasSelectedDirectory = false

        // When, Then
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    // MARK: - Real-time Updates Tests

    func testCredentialsUpdateAfterSettingsChange() async {
        // Given - Initially no credentials
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.hasCredentials)

        // When - Simulate credentials being saved in settings
        mockKeychainService.setStoredCredentials(username: "newuser", token: "newtoken")
        viewModel.hideSettings() // This should trigger credentials recheck

        // Wait for credentials check
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")
    }

    func testCredentialsUpdateAfterDeletion() async {
        // Given - Initially have credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()
        XCTAssertTrue(viewModel.hasCredentials)

        // When - Simulate credentials being deleted in settings
        mockKeychainService.clearStoredCredentials()
        viewModel.hideSettings() // This should trigger credentials recheck

        // Wait for credentials check
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
    }

    func testUIStateUpdateWhenCredentialsChange() async {
        // Given - Initially no credentials
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.isUIEnabled)

        // When - Add credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertTrue(viewModel.isUIEnabled)
        XCTAssertTrue(viewModel.hasCredentials)
    }

    // MARK: - Published Properties Tests

    func testPublishedPropertiesUpdate() async {
        // Given
        let expectation = XCTestExpectation(description: "Published properties should update")
        var receivedUpdates = 0

        // Monitor published property changes
        let cancellable = viewModel.$hasCredentials.sink { _ in
            receivedUpdates += 1
            if receivedUpdates >= 2 { // Initial value + one update
                expectation.fulfill()
            }
        }

        // When
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        cancellable.cancel()
        XCTAssertTrue(viewModel.hasCredentials)
    }

    // MARK: - Settings Sheet Dismissal Tests

    func testSettingsSheetDismissalSynchronization() async {
        // Given - Settings sheet is shown and credentials are initially not configured
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.hasCredentials)

        viewModel.showSettings()
        XCTAssertTrue(viewModel.isShowingSettings)

        // When - Credentials are configured while settings are open
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")

        // And settings sheet is dismissed (this simulates the onDismiss handler)
        viewModel.hideSettings()

        // Wait for credentials check
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - Credentials status should be updated and UI should be enabled
        XCTAssertFalse(viewModel.isShowingSettings)
        XCTAssertTrue(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials configured")
        XCTAssertTrue(viewModel.isUIEnabled)
    }

    func testSettingsSheetDismissalWithCredentialsCleared() async {
        // Given - Settings sheet is shown and credentials are initially configured
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()
        XCTAssertTrue(viewModel.hasCredentials)

        viewModel.showSettings()
        XCTAssertTrue(viewModel.isShowingSettings)

        // When - Credentials are cleared while settings are open
        mockKeychainService.clearStoredCredentials()

        // And settings sheet is dismissed (this simulates the onDismiss handler)
        viewModel.hideSettings()

        // Wait for credentials check
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then - Credentials status should be updated and UI should be disabled
        XCTAssertFalse(viewModel.isShowingSettings)
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured. Please configure them in Settings.")
        XCTAssertFalse(viewModel.isUIEnabled)
    }

    // MARK: - Status Message Tests

    func testInitialStatusMessage() {
        // Given the viewModel from setUp (configured with MockKeychainService)

        // Then
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
        XCTAssertFalse(viewModel.isForking)
    }

    func testStatusMessageUpdates() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // When
        let forkTask = Task {
            await viewModel.createPrivateFork()
        }

        // Wait a moment to check initial status
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - Should be in progress
        XCTAssertTrue(viewModel.isForking)
        XCTAssertEqual(viewModel.statusMessage, "Preparing to create private fork...")

        // Wait for completion
        await forkTask.value

        // Then - Should be complete
        XCTAssertFalse(viewModel.isForking)
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
    }

    // MARK: - Fork Button Tests

    func testIsCreateButtonEnabledWhenForking() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Verify preconditions
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        // When - Start fork operation
        let forkTask = Task {
            await viewModel.createPrivateFork()
        }

        // Wait a moment for fork to start
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then - Button should be disabled while forking
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertTrue(viewModel.isForking)

        // Clean up
        await forkTask.value
    }

    func testCreatePrivateForkWhenNotEnabled() async {
        // Given - Button is not enabled (no credentials)
        mockKeychainService.clearStoredCredentials()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        let initialStatus = viewModel.statusMessage

        // When
        await viewModel.createPrivateFork()

        // Then - Nothing should happen
        XCTAssertFalse(viewModel.isForking)
        XCTAssertEqual(viewModel.statusMessage, initialStatus)
    }

    func testCreatePrivateForkProgressiveStatusUpdates() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        var statusUpdates: [String] = []
        let expectation = XCTestExpectation(description: "Status updates should occur")

        // Monitor status changes
        let cancellable = viewModel.$statusMessage.sink { status in
            statusUpdates.append(status)
            if statusUpdates.count >= 6 { // Initial + 5 updates during fork
                expectation.fulfill()
            }
        }

        // When
        await viewModel.createPrivateFork()

        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        cancellable.cancel()

        XCTAssertTrue(statusUpdates.contains("Preparing to create private fork..."))
        XCTAssertTrue(statusUpdates.contains("Validating repository access..."))
        XCTAssertTrue(statusUpdates.contains("Creating private fork..."))
        XCTAssertTrue(statusUpdates.contains("Cloning repository..."))
        XCTAssertTrue(statusUpdates.contains("Fork created successfully!"))
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
        XCTAssertFalse(viewModel.isForking)
    }

    func testForkButtonStateManagement() async {
        // Given
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Verify initial state
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        XCTAssertFalse(viewModel.isForking)

        // When - Start fork
        let forkTask = Task {
            await viewModel.createPrivateFork()
        }

        // Wait for fork to start
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Then - During fork
        XCTAssertTrue(viewModel.isForking)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        // Wait for completion
        await forkTask.value

        // Then - After fork
        XCTAssertFalse(viewModel.isForking)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }
}
