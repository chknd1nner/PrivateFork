import XCTest
@testable import PrivateFork

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private var viewModel: SettingsViewModel!
    private var mockKeychainService: MockKeychainService!
    private var mockGitHubValidationService: MockGitHubValidationService!

    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        mockGitHubValidationService = MockGitHubValidationService()
        viewModel = SettingsViewModel(
            keychainService: mockKeychainService,
            gitHubValidationService: mockGitHubValidationService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockKeychainService = nil
        mockGitHubValidationService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_WithNoExistingCredentials_StartsWithEmptyFields() async {
        // Given: No existing credentials in keychain
        mockKeychainService.clearStoredCredentials()

        // When: ViewModel is initialized
        let newViewModel = SettingsViewModel(
            keychainService: mockKeychainService,
            gitHubValidationService: mockGitHubValidationService
        )

        // Wait for initialization to complete
        await Task.yield()

        // Then: Fields should be empty
        XCTAssertEqual(newViewModel.username, "")
        XCTAssertEqual(newViewModel.token, "")
        XCTAssertFalse(newViewModel.isSaved)
    }

    func testInitialization_WithExistingCredentials_LoadsThem() async {
        // Given: Existing credentials in keychain
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")

        // When: ViewModel is initialized
        let newViewModel = SettingsViewModel(
            keychainService: mockKeychainService,
            gitHubValidationService: mockGitHubValidationService
        )

        // Wait for initialization to complete
        await Task.yield()

        // Then: Fields should be populated
        XCTAssertEqual(newViewModel.username, "testuser")
        XCTAssertEqual(newViewModel.token, "testtoken")
        XCTAssertTrue(newViewModel.isSaved)
    }

    // MARK: - Validate and Save Tests

    func testValidateAndSave_WithValidCredentials_SavesSuccessfully() async {
        // Given: Valid credentials and successful validation
        viewModel.username = "validuser"
        viewModel.token = "validtoken"
        mockGitHubValidationService.setValidationResult(isValid: true)

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Credentials should be saved and success state set
        XCTAssertTrue(mockKeychainService.hasStoredCredentials())
        XCTAssertTrue(viewModel.isSaved)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isValidating)
    }

    func testValidateAndSave_WithInvalidCredentials_ShowsError() async {
        // Given: Invalid credentials
        viewModel.username = "invaliduser"
        viewModel.token = "invalidtoken"
        mockGitHubValidationService.setValidationResult(isValid: false)

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Error should be shown and credentials not saved
        XCTAssertFalse(mockKeychainService.hasStoredCredentials())
        XCTAssertFalse(viewModel.isSaved)
        XCTAssertEqual(viewModel.errorMessage, "Credential validation failed")
        XCTAssertFalse(viewModel.isValidating)
    }

    func testValidateAndSave_WithValidationError_ShowsSpecificError() async {
        // Given: GitHub validation service returns an error
        viewModel.username = "testuser"
        viewModel.token = "testtoken"
        mockGitHubValidationService.setValidationError(.authenticationFailed)

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Specific error should be shown
        XCTAssertFalse(mockKeychainService.hasStoredCredentials())
        XCTAssertFalse(viewModel.isSaved)
        XCTAssertEqual(viewModel.errorMessage, "Authentication failed - check your credentials")
        XCTAssertFalse(viewModel.isValidating)
    }

    func testValidateAndSave_WithKeychainError_ShowsKeychainError() async {
        // Given: Valid credentials but keychain save fails
        viewModel.username = "validuser"
        viewModel.token = "validtoken"
        mockGitHubValidationService.setValidationResult(isValid: true)
        mockKeychainService.shouldFailSave = true

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Keychain error should be shown
        XCTAssertFalse(viewModel.isSaved)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isValidating)
    }

    func testValidateAndSave_TrimsWhitespace() async {
        // Given: Credentials with whitespace
        viewModel.username = "  validuser  "
        viewModel.token = "  validtoken  "
        mockGitHubValidationService.setValidationResult(isValid: true)

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Trimmed credentials should be validated
        let lastValidated = mockGitHubValidationService.getLastValidatedCredentials()
        XCTAssertEqual(lastValidated?.username, "validuser")
        XCTAssertEqual(lastValidated?.token, "validtoken")
    }

    func testValidateAndSave_SetsValidatingState() async {
        // Given: Valid credentials
        viewModel.username = "validuser"
        viewModel.token = "validtoken"
        mockGitHubValidationService.setValidationResult(isValid: true)

        // When: Validate and save starts
        let validationTask = Task {
            await viewModel.validateAndSave()
        }

        // Then: isValidating should be true during operation
        XCTAssertTrue(viewModel.isValidating)

        await validationTask.value

        // And: isValidating should be false after completion
        XCTAssertFalse(viewModel.isValidating)
    }

    // MARK: - Clear Tests

    func testClear_WithExistingCredentials_ClearsSuccessfully() async {
        // Given: Existing credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "testtoken")
        viewModel.username = "testuser"
        viewModel.token = "testtoken"
        viewModel.isSaved = true

        // When: Clear is called
        await viewModel.clear()

        // Then: Credentials should be cleared
        XCTAssertFalse(mockKeychainService.hasStoredCredentials())
        XCTAssertEqual(viewModel.username, "")
        XCTAssertEqual(viewModel.token, "")
        XCTAssertFalse(viewModel.isSaved)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testClear_WithKeychainError_ShowsError() async {
        // Given: Keychain delete will fail
        mockKeychainService.shouldFailDelete = true
        viewModel.username = "testuser"
        viewModel.token = "testtoken"

        // When: Clear is called
        await viewModel.clear()

        // Then: Error should be shown and fields not cleared
        XCTAssertEqual(viewModel.username, "testuser")
        XCTAssertEqual(viewModel.token, "testtoken")
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - Message Clearing Tests

    func testValidateAndSave_ClearsPreviousMessages() async {
        // Given: Previous error state
        viewModel.errorMessage = "Previous error"
        viewModel.isSaved = true
        viewModel.username = "validuser"
        viewModel.token = "validtoken"
        mockGitHubValidationService.setValidationResult(isValid: true)

        // When: Validate and save is called
        await viewModel.validateAndSave()

        // Then: Previous messages should be cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isSaved) // New state
    }

    func testClear_ClearsPreviousMessages() async {
        // Given: Previous error and success state
        viewModel.errorMessage = "Previous error"
        viewModel.isSaved = true

        // When: Clear is called
        await viewModel.clear()

        // Then: Previous messages should be cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSaved)
    }
}
