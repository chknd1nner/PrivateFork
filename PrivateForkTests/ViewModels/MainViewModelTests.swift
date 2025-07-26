import XCTest
import Combine
@testable import PrivateFork

@MainActor
final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel!
    var mockKeychainService: MockKeychainService!
    var mockPrivateForkOrchestrator: MockPrivateForkOrchestrator!

    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        mockPrivateForkOrchestrator = MockPrivateForkOrchestrator()
        viewModel = MainViewModel(
            keychainService: mockKeychainService,
            privateForkOrchestrator: mockPrivateForkOrchestrator
        )
        viewModel.setDebounceInterval(0) // Disable debouncing for faster tests
    }

    override func tearDown() {
        viewModel = nil
        mockKeychainService = nil
        mockPrivateForkOrchestrator = nil
        super.tearDown()
    }

    func testInitialization() async {
        // Given, When
        let mockService = MockKeychainService()
        let mockOrchestrator = MockPrivateForkOrchestrator()
        let viewModel = MainViewModel(
            keychainService: mockService,
            privateForkOrchestrator: mockOrchestrator
        )

        // Explicitly initialize credentials check (lazy initialization)
        await viewModel.initializeCredentialsCheck()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.repoURL, "")
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "")
        XCTAssertEqual(viewModel.localPath, "")
        XCTAssertFalse(viewModel.hasSelectedDirectory)
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured.")
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
        mockKeychainService.clearStoredOAuthTokens()

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.hasCredentials)
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured.")
    }

    func testCredentialsStatusWhenConfigured() async {
        // Given
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        XCTAssertEqual(viewModel.credentialsStatusMessage, "GitHub credentials not configured.")
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


    // MARK: - UI State Management Tests

    func testIsUIEnabledWhenCredentialsConfigured() async {
        // Given
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertTrue(viewModel.isUIEnabled)
    }

    func testIsUIEnabledWhenCredentialsNotConfigured() async {
        // Given
        mockKeychainService.clearStoredOAuthTokens()

        // When
        await viewModel.checkCredentialsStatus()

        // Then
        XCTAssertFalse(viewModel.isUIEnabled)
    }

    func testIsCreateButtonEnabledWhenAllConditionsMet() async {
        // Given
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
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
        mockKeychainService.clearStoredOAuthTokens()
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
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


    func testUIStateUpdateWhenCredentialsChange() async {
        // Given - Initially no credentials
        mockKeychainService.clearStoredOAuthTokens()
        await viewModel.checkCredentialsStatus()
        XCTAssertFalse(viewModel.isUIEnabled)

        // When - Add credentials
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        cancellable.cancel()
        XCTAssertTrue(viewModel.hasCredentials)
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Configure orchestrator for success
        mockPrivateForkOrchestrator.setSuccessResult()

        // When
        await viewModel.createPrivateFork()

        // Then - Should be complete and have called orchestrator
        XCTAssertFalse(viewModel.isForking)
        XCTAssertEqual(mockPrivateForkOrchestrator.createPrivateForkCallCount, 1)
        XCTAssertEqual(mockPrivateForkOrchestrator.lastRepositoryURL, "https://github.com/owner/repository")
        XCTAssertEqual(mockPrivateForkOrchestrator.lastLocalPath, "/Users/testuser/Documents")
    }

    // MARK: - Fork Button Tests

    func testIsCreateButtonEnabledWhenForking() async {
        // Given
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Verify preconditions
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        // Configure orchestrator for success
        mockPrivateForkOrchestrator.setSuccessResult()

        // When - Complete fork operation
        await viewModel.createPrivateFork()

        // Then - Button should be enabled again after completion
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        XCTAssertFalse(viewModel.isForking)
        XCTAssertEqual(mockPrivateForkOrchestrator.createPrivateForkCallCount, 1)
    }

    func testCreatePrivateForkWhenNotEnabled() async {
        // Given - Button is not enabled (no credentials)
        mockKeychainService.clearStoredOAuthTokens()
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        var statusUpdates: [String] = []
        var cancellable: AnyCancellable?

        // Configure orchestrator for success - CRITICAL: This was missing!
        mockPrivateForkOrchestrator.setSuccessResult()

        // Monitor status changes
        cancellable = viewModel.$statusMessage.sink { status in
            statusUpdates.append(status)
        }

        // When
        await viewModel.createPrivateFork()
        
        // Allow any pending async status updates to complete
        await Task.yield()

        // Wait for the 2-second reset delay in MainViewModel
        try? await Task.sleep(for: .seconds(2.1))

        // Then - Cancel subscription after fork completes
        cancellable?.cancel()

        XCTAssertTrue(statusUpdates.contains("Preparing to create private fork..."))
        XCTAssertTrue(statusUpdates.contains("Validating GitHub credentials..."))
        XCTAssertTrue(statusUpdates.contains("Creating private repository..."))
        XCTAssertTrue(statusUpdates.contains("Cloning original repository..."))
        XCTAssertTrue(statusUpdates.contains("Private fork created successfully!"))
        XCTAssertEqual(viewModel.statusMessage, "Ready.")
        XCTAssertFalse(viewModel.isForking)
    }

    func testForkButtonStateManagement() async {
        // Given
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()

        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow the validation task to run immediately

        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true

        // Configure orchestrator for success
        mockPrivateForkOrchestrator.setSuccessResult()

        // Verify initial state
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        XCTAssertFalse(viewModel.isForking)

        // When - Complete fork operation
        await viewModel.createPrivateFork()

        // Then - After fork completion
        XCTAssertFalse(viewModel.isForking)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
        XCTAssertEqual(mockPrivateForkOrchestrator.createPrivateForkCallCount, 1)
    }
    
    // MARK: - Orchestrator Integration Tests
    
    func testCreatePrivateFork_WhenOrchestratorSucceeds_ShouldShowSuccess() async {
        // Given
        await setupValidForkConditions()
        mockPrivateForkOrchestrator.setSuccessResult(message: "Test success message!")

        // When
        await viewModel.createPrivateFork()

        // Then
        XCTAssertEqual(mockPrivateForkOrchestrator.createPrivateForkCallCount, 1)
        XCTAssertEqual(mockPrivateForkOrchestrator.lastRepositoryURL, "https://github.com/owner/repository")
        XCTAssertEqual(mockPrivateForkOrchestrator.lastLocalPath, "/Users/testuser/Documents")
        XCTAssertTrue(viewModel.statusMessage.contains("Test success message!"))
        XCTAssertFalse(viewModel.isForking)
    }
    
    func testCreatePrivateFork_WhenOrchestratorFails_ShouldShowError() async {
        // Given
        await setupValidForkConditions()
        mockPrivateForkOrchestrator.simulateCredentialValidationFailure()

        // When
        await viewModel.createPrivateFork()

        // Then
        XCTAssertEqual(mockPrivateForkOrchestrator.createPrivateForkCallCount, 1)
        XCTAssertTrue(viewModel.statusMessage.contains("Error:"))
        XCTAssertTrue(viewModel.statusMessage.contains("credential"))
        XCTAssertFalse(viewModel.isForking)
    }
    
    func testCreatePrivateFork_ShouldReceiveStatusCallbacks() async {
        // Given
        await setupValidForkConditions()
        mockPrivateForkOrchestrator.setSuccessResult()

        var statusUpdates: [String] = []
        let cancellable = viewModel.$statusMessage.sink { status in
            statusUpdates.append(status)
        }

        // When
        await viewModel.createPrivateFork()

        cancellable.cancel()

        // Then
        let orchestratorCallbacks = mockPrivateForkOrchestrator.getStatusCallbacks()
        XCTAssertGreaterThan(orchestratorCallbacks.count, 3)
        XCTAssertTrue(orchestratorCallbacks.contains { $0.contains("Validating") })
        XCTAssertTrue(orchestratorCallbacks.contains { $0.contains("Creating") })
        XCTAssertTrue(orchestratorCallbacks.contains { $0.contains("Cloning") })
    }
    
    // MARK: - Helper Methods
    
    private func setupValidForkConditions() async {
        mockKeychainService.setStoredOAuthTokens(accessToken: "testtoken", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
        await viewModel.checkCredentialsStatus()
        viewModel.updateRepositoryURL("https://github.com/owner/repository")
        await Task.yield() // Allow URL validation to complete
        viewModel.localPath = "/Users/testuser/Documents"
        viewModel.hasSelectedDirectory = true
    }
}
