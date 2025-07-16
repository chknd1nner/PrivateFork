import XCTest
@testable import PrivateFork

@MainActor
final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel!

    override func setUp() {
        super.setUp()
        viewModel = MainViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialization() {
        // Given, When
        let viewModel = MainViewModel()

        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.repoURL, "")
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "")
        XCTAssertFalse(viewModel.isShowingSettings)
    }

    // MARK: - URL Validation Tests

    func testValidGitHubURL() async {
        // Given
        let validURL = "https://github.com/owner/repository"

        // When
        viewModel.updateRepositoryURL(validURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds

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

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testValidGitHubURLWithSubpaths() async {
        // Given
        let validURL = "https://github.com/owner/repository/tree/main"

        // When
        viewModel.updateRepositoryURL(validURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testEmptyURL() async {
        // Given
        let emptyURL = ""

        // When
        viewModel.updateRepositoryURL(emptyURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a repository URL")
    }

    func testWhitespaceOnlyURL() async {
        // Given
        let whitespaceURL = "   \n\t   "

        // When
        viewModel.updateRepositoryURL(whitespaceURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a repository URL")
    }

    func testInvalidURL() async {
        // Given
        let invalidURL = "not-a-url"

        // When
        viewModel.updateRepositoryURL(invalidURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid URL format")
    }

    func testNonGitHubURL() async {
        // Given
        let nonGitHubURL = "https://gitlab.com/owner/repository"

        // When
        viewModel.updateRepositoryURL(nonGitHubURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Please enter a GitHub repository URL")
    }

    func testGitHubURLWithoutRepository() async {
        // Given
        let incompleteURL = "https://github.com/"

        // When
        viewModel.updateRepositoryURL(incompleteURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid repository path. Expected format: github.com/owner/repository")
    }

    func testGitHubURLWithOnlyOwner() async {
        // Given
        let incompleteURL = "https://github.com/owner"

        // When
        viewModel.updateRepositoryURL(incompleteURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid repository path. Expected format: github.com/owner/repository")
    }

    func testGitHubURLWithInvalidCharacters() async {
        // Given
        let invalidURL = "https://github.com/owner@$/repository#$"

        // When
        viewModel.updateRepositoryURL(invalidURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertFalse(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Invalid repository path. Expected format: github.com/owner/repository")
    }

    func testValidGitHubURLWithValidSpecialCharacters() async {
        // Given
        let validURL = "https://github.com/owner-name/repository.name"

        // When
        viewModel.updateRepositoryURL(validURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    func testValidGitHubURLWithUnderscores() async {
        // Given
        let validURL = "https://github.com/owner_name/repository_name"

        // When
        viewModel.updateRepositoryURL(validURL)

        // Wait for debounced validation
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then
        XCTAssertTrue(viewModel.isValidURL)
        XCTAssertEqual(viewModel.urlValidationMessage, "Valid GitHub repository URL")
    }

    // MARK: - Debouncing Tests

    func testDebouncingBehavior() async {
        // Given
        let initialURL = "https://github.com/owner/repo"
        let finalURL = "https://github.com/owner/repository"

        // When - Update URL multiple times quickly
        viewModel.updateRepositoryURL("h")
        viewModel.updateRepositoryURL("ht")
        viewModel.updateRepositoryURL("htt")
        viewModel.updateRepositoryURL(initialURL)
        viewModel.updateRepositoryURL(finalURL)

        // Wait for debounced validation (should only validate the final URL)
        try? await Task.sleep(nanoseconds: 400_000_000)

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
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Verify first validation
        XCTAssertTrue(viewModel.isValidURL)

        // Update with invalid URL
        viewModel.updateRepositoryURL("invalid")
        try? await Task.sleep(nanoseconds: 400_000_000)

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
}
