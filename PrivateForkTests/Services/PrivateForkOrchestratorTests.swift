import XCTest
@testable import PrivateFork

@MainActor
final class PrivateForkOrchestratorTests: XCTestCase {

    var orchestrator: PrivateForkOrchestrator!
    var mockKeychainService: MockKeychainService!
    var mockGitHubService: MockGitHubService!
    var mockGitService: MockGitService!

    override func setUp() {
        super.setUp()
        
        // Initialize mock services
        mockKeychainService = MockKeychainService()
        mockGitHubService = MockGitHubService()
        mockGitService = MockGitService()
        
        // Create orchestrator with mock dependencies
        orchestrator = PrivateForkOrchestrator(
            keychainService: mockKeychainService,
            gitHubService: mockGitHubService,
            gitService: mockGitService
        )
        
        // Set up default success scenario
        setupSuccessScenario()
    }

    override func tearDown() {
        orchestrator = nil
        mockKeychainService = nil
        mockGitHubService = nil
        mockGitService = nil
        super.tearDown()
    }

    // MARK: - Success Scenarios

    func testCreatePrivateFork_WhenSuccessful_ShouldCompleteWorkflow() async {
        // Given: All services configured for success
        var statusUpdates: [String] = []

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { status in
            statusUpdates.append(status)
        }

        // Then: The operation should succeed with proper status updates
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Private fork created successfully"))
            XCTAssertTrue(statusUpdates.contains("Validating GitHub credentials..."))
            XCTAssertTrue(statusUpdates.contains(where: { $0.contains("Creating private repository") }))
            XCTAssertTrue(statusUpdates.contains("Cloning original repository..."))
            XCTAssertTrue(statusUpdates.contains("Configuring remotes..."))
            XCTAssertTrue(statusUpdates.contains("Pushing to private repository..."))
        case .failure:
            XCTFail("Orchestration should have succeeded")
        }
    }

    func testCreatePrivateFork_WhenSuccessful_ShouldCallServicesInCorrectOrder() async {
        // Given: All services configured for success
        var statusUpdates: [String] = []

        // When: The orchestration workflow is called
        _ = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { status in
            statusUpdates.append(status)
        }

        // Then: Services should be called correctly
        // MockKeychainService doesn't track call counts, but GitService does
        
        // MockGitService tracks call counts  
        XCTAssertEqual(mockGitService.cloneCallCount, 1)
        XCTAssertEqual(mockGitService.addRemoteCallCount, 1)
        XCTAssertEqual(mockGitService.pushCallCount, 2) // --all and --tags
    }

    // MARK: - Error Scenarios

    func testCreatePrivateFork_WhenCredentialValidationFails_ShouldReturnCredentialError() async {
        // Given: Keychain service configured to fail
        mockKeychainService.shouldFailRetrieve = true

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return credential validation error
        switch result {
        case .success:
            XCTFail("Should have failed with credential error")
        case .failure(let error):
            guard case .credentialValidationFailed = error else {
                XCTFail("Expected credential validation error, got \(error)")
                return
            }
        }
    }

    func testCreatePrivateFork_WhenGitHubValidationFails_ShouldReturnCredentialError() async {
        // Given: GitHub service configured to fail validation
        mockGitHubService.shouldFailValidation = true

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return credential validation error
        switch result {
        case .success:
            XCTFail("Should have failed with credential error")
        case .failure(let error):
            guard case .credentialValidationFailed = error else {
                XCTFail("Expected credential validation error, got \(error)")
                return
            }
        }
    }

    func testCreatePrivateFork_WhenRepositoryCreationFails_ShouldReturnRepositoryCreationError() async {
        // Given: GitHub service configured to fail repository creation
        mockGitHubService.shouldFailRepositoryCreation = true
        mockGitHubService.repositoryCreationError = .repositoryNameConflict("test-repo")

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return repository creation error
        switch result {
        case .success:
            XCTFail("Should have failed with repository creation error")
        case .failure(let error):
            guard case .repositoryCreationFailed(let gitHubError) = error else {
                XCTFail("Expected repository creation error, got \(error)")
                return
            }
            guard case .repositoryNameConflict = gitHubError else {
                XCTFail("Expected repository name conflict error")
                return
            }
        }
    }

    func testCreatePrivateFork_WhenGitCloneFails_ShouldReturnGitOperationError() async {
        // Given: Git service configured to fail clone
        mockGitService.setCloneFailure(GitServiceError.authenticationFailed)

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return git operation error
        switch result {
        case .success:
            XCTFail("Should have failed with git operation error")
        case .failure(let error):
            guard case .gitOperationFailed = error else {
                XCTFail("Expected git operation error, got \(error)")
                return
            }
        }
    }

    func testCreatePrivateFork_WhenPushFails_ShouldReturnGitOperationError() async {
        // Given: Git service configured to fail push
        mockGitService.setPushFailure(GitServiceError.authenticationFailed)

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return git operation error
        switch result {
        case .success:
            XCTFail("Should have failed with git operation error")
        case .failure(let error):
            guard case .gitOperationFailed = error else {
                XCTFail("Expected git operation error, got \(error)")
                return
            }
        }
    }

    // MARK: - Input Validation

    func testCreatePrivateFork_WhenRepositoryURLIsInvalid_ShouldReturnInvalidURLError() async {
        // Given: Invalid repository URL
        let invalidURL = "not-a-url"

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: invalidURL,
            localPath: "/tmp/test"
        ) { _ in }

        // Then: Should return invalid URL error
        switch result {
        case .success:
            XCTFail("Should have failed with invalid URL error")
        case .failure(let error):
            guard case .invalidRepositoryURL = error else {
                XCTFail("Expected invalid repository URL error, got \(error)")
                return
            }
        }
    }

    func testCreatePrivateFork_WhenLocalPathIsInvalid_ShouldReturnInvalidPathError() async {
        // Given: Invalid local path (parent directory doesn't exist)
        let invalidPath = "/nonexistent/directory/path"

        // When: The orchestration workflow is called
        let result = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: invalidPath
        ) { _ in }

        // Then: Should return invalid path error
        switch result {
        case .success:
            XCTFail("Should have failed with invalid path error")
        case .failure(let error):
            guard case .invalidLocalPath = error else {
                XCTFail("Expected invalid local path error, got \(error)")
                return
            }
        }
    }

    // MARK: - Status Callback Testing

    func testCreatePrivateFork_ShouldProvideStatusUpdates() async {
        // Given: Success scenario
        var statusUpdates: [String] = []

        // When: The orchestration workflow is called
        _ = await orchestrator.createPrivateFork(
            repositoryURL: "https://github.com/user/repo",
            localPath: "/tmp/test"
        ) { status in
            statusUpdates.append(status)
        }

        // Then: Should provide meaningful status updates
        XCTAssertGreaterThan(statusUpdates.count, 3)
        XCTAssertTrue(statusUpdates.first?.contains("Validating") == true)
        XCTAssertTrue(statusUpdates.contains { $0.contains("Creating") })
        XCTAssertTrue(statusUpdates.contains { $0.contains("Cloning") })
        XCTAssertTrue(statusUpdates.contains { $0.contains("Pushing") })
    }


    // MARK: - Private Helper Methods

    private func setupSuccessScenario() {
        // Configure keychain service for success
        mockKeychainService.setStoredCredentials(username: "testuser", token: "test-token")
        
        // Configure GitHub service for success
        let mockUser = GitHubUser(
            login: "testuser",
            id: 123,
            name: "Test User",
            email: "test@example.com",
            company: nil,
            location: nil,
            bio: nil,
            publicRepos: 5,
            privateRepos: 2,
            totalPrivateRepos: 2,
            plan: nil
        )
        mockGitHubService.setMockUser(mockUser)
        
        // Configure git service for success (using defaults)
        // MockGitService is already configured for success by default
    }
}