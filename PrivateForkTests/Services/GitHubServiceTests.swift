import XCTest
@testable import PrivateFork

final class GitHubServiceTests: XCTestCase {

    var gitHubService: GitHubService!
    var mockKeychainService: MockKeychainService!
    var mockURLSession: URLSession!

    override func setUp() {
        super.setUp()

        // Setup mocks
        mockKeychainService = MockKeychainService()
        mockURLSession = URLSession.mockSession()

        // Clear any existing mock responses
        MockURLProtocol.clearMockResponses()

        // Create service with mocks
        gitHubService = GitHubService(
            keychainService: mockKeychainService,
            urlSession: mockURLSession,
            baseURL: URL(string: "https://api.github.com")!
        )
    }

    override func tearDown() {
        gitHubService = nil
        mockKeychainService = nil
        mockURLSession = nil
        MockURLProtocol.clearMockResponses()
        super.tearDown()
    }

    // MARK: - Validate Credentials Tests

    func testValidateCredentials_ValidCredentials_ShouldReturnUser() async {
        // Given: Valid credentials in keychain and successful API response
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // When: Validating credentials
        let result = await gitHubService.validateCredentials()

        // Then: Should return successful user
        switch result {
        case .success(let user):
            XCTAssertEqual(user.login, "testuser")
            XCTAssertEqual(user.id, 12345)
            XCTAssertEqual(user.name, "Test User")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testValidateCredentials_NoCredentials_ShouldReturnCredentialsNotFound() async {
        // Given: No credentials in keychain
        mockKeychainService.clearStoredCredentials()

        // When: Validating credentials
        let result = await gitHubService.validateCredentials()

        // Then: Should return credentials not found error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .credentialsNotFound)
        }
    }

    func testValidateCredentials_InvalidToken_ShouldReturnAuthenticationFailed() async {
        // Given: Invalid token in keychain
        mockKeychainService.setStoredCredentials(username: "testuser", token: "invalid_token")

        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: Data(), statusCode: 401)

        // When: Validating credentials
        let result = await gitHubService.validateCredentials()

        // Then: Should return authentication failed error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .authenticationFailed)
        }
    }

    func testValidateCredentials_RateLimited_ShouldReturnRateLimitedError() async {
        // Given: Valid credentials but rate limited response
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let headers = ["Retry-After": "1640995200"] // Unix timestamp
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: Data(), statusCode: 429, headers: headers)

        // When: Validating credentials
        let result = await gitHubService.validateCredentials()

        // Then: Should return rate limited error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .rateLimited(let retryAfter) = error {
                XCTAssertNotNil(retryAfter)
            } else {
                XCTFail("Expected rate limited error but got: \(error)")
            }
        }
    }

    // MARK: - Create Private Repository Tests

    func testCreatePrivateRepository_ValidName_ShouldCreateRepository() async {
        // Given: Valid credentials and repository name
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // Mock repository existence check (404 means doesn't exist)
        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/test-repo", data: Data(), statusCode: 404)

        // Mock successful repository creation
        let mockRepoData = MockURLProtocol.mockSuccessfulRepository(name: "test-repo", description: "Test repository")
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user/repos", data: mockRepoData, statusCode: 201)

        // When: Creating a repository
        let result = await gitHubService.createPrivateRepository(name: "test-repo", description: "Test repository")

        // Then: Should return created repository
        switch result {
        case .success(let repository):
            XCTAssertEqual(repository.name, "test-repo")
            XCTAssertEqual(repository.description, "Test repository")
            XCTAssertTrue(repository.isPrivate)
            XCTAssertEqual(repository.owner.login, "testuser")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testCreatePrivateRepository_EmptyName_ShouldReturnInvalidRepositoryName() async {
        // Given: Empty repository name
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        // When: Creating a repository with empty name
        let result = await gitHubService.createPrivateRepository(name: "", description: nil)

        // Then: Should return invalid repository name error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRepositoryName)
        }
    }

    func testCreatePrivateRepository_NameTooLong_ShouldReturnInvalidRepositoryName() async {
        // Given: Repository name that's too long
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")
        let longName = String(repeating: "a", count: 101)

        // When: Creating a repository with too long name
        let result = await gitHubService.createPrivateRepository(name: longName, description: nil)

        // Then: Should return invalid repository name error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRepositoryName)
        }
    }

    func testCreatePrivateRepository_InvalidCharacters_ShouldReturnInvalidRepositoryName() async {
        // Given: Repository name with invalid characters
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        // When: Creating a repository with invalid characters
        let result = await gitHubService.createPrivateRepository(name: "test@repo", description: nil)

        // Then: Should return invalid repository name error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidRepositoryName)
        }
    }

    func testCreatePrivateRepository_RepositoryExists_ShouldReturnNameConflict() async {
        // Given: Valid credentials and existing repository
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // Mock repository existence check (200 means exists)
        let mockRepoData = MockURLProtocol.mockSuccessfulRepository(name: "existing-repo")
        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/existing-repo", data: mockRepoData, statusCode: 200)

        // When: Creating a repository that already exists
        let result = await gitHubService.createPrivateRepository(name: "existing-repo", description: nil)

        // Then: Should return name conflict error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .repositoryNameConflict(let name) = error {
                XCTAssertEqual(name, "existing-repo")
            } else {
                XCTFail("Expected name conflict error but got: \(error)")
            }
        }
    }

    func testCreatePrivateRepository_InsufficientPermissions_ShouldReturnInsufficientPermissions() async {
        // Given: Valid credentials but insufficient permissions
        mockKeychainService.setStoredCredentials(username: "testuser", token: "limited_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // Mock repository existence check
        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/test-repo", data: Data(), statusCode: 404)

        // Mock 403 response for repository creation
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user/repos", data: Data(), statusCode: 403)

        // When: Creating a repository with insufficient permissions
        let result = await gitHubService.createPrivateRepository(name: "test-repo", description: nil)

        // Then: Should return insufficient permissions error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .insufficientPermissions)
        }
    }

    // MARK: - Get Current User Tests

    func testGetCurrentUser_ValidCredentials_ShouldReturnUser() async {
        // Given: Valid credentials in keychain
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // When: Getting current user
        let result = await gitHubService.getCurrentUser()

        // Then: Should return user
        switch result {
        case .success(let user):
            XCTAssertEqual(user.login, "testuser")
            XCTAssertEqual(user.id, 12345)
            XCTAssertEqual(user.name, "Test User")
            XCTAssertEqual(user.email, "test@example.com")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testGetCurrentUser_InvalidCredentials_ShouldReturnAuthenticationFailed() async {
        // Given: Invalid credentials
        mockKeychainService.setStoredCredentials(username: "testuser", token: "invalid_token")

        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: Data(), statusCode: 401)

        // When: Getting current user
        let result = await gitHubService.getCurrentUser()

        // Then: Should return authentication failed error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .authenticationFailed)
        }
    }

    // MARK: - Repository Exists Tests

    func testRepositoryExists_RepositoryExists_ShouldReturnTrue() async {
        // Given: Valid credentials and existing repository
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        let mockRepoData = MockURLProtocol.mockSuccessfulRepository(name: "existing-repo")
        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/existing-repo", data: mockRepoData, statusCode: 200)

        // When: Checking if repository exists
        let result = await gitHubService.repositoryExists(name: "existing-repo")

        // Then: Should return true
        switch result {
        case .success(let exists):
            XCTAssertTrue(exists)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testRepositoryExists_RepositoryDoesNotExist_ShouldReturnFalse() async {
        // Given: Valid credentials and non-existing repository
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/non-existing-repo", data: Data(), statusCode: 404)

        // When: Checking if repository exists
        let result = await gitHubService.repositoryExists(name: "non-existing-repo")

        // Then: Should return false
        switch result {
        case .success(let exists):
            XCTAssertFalse(exists)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }

    func testRepositoryExists_NetworkError_ShouldReturnNetworkError() async {
        // Given: Valid credentials but network error
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        let networkError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        MockURLProtocol.setMockError(for: "https://api.github.com/repos/testuser/test-repo", error: networkError)

        // When: Checking if repository exists
        let result = await gitHubService.repositoryExists(name: "test-repo")

        // Then: Should return network error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .networkError(let underlyingError) = error {
                XCTAssertEqual((underlyingError as NSError).domain, "NetworkError")
            } else {
                XCTFail("Expected network error but got: \(error)")
            }
        }
    }

    // MARK: - Integration Tests

    func testCreatePrivateRepository_EndToEndFlow_ShouldSucceed() async {
        // Given: Complete valid setup
        mockKeychainService.setStoredCredentials(username: "testuser", token: "valid_token")

        // Mock user endpoint
        let mockUserData = MockURLProtocol.mockSuccessfulUser()
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user", data: mockUserData, statusCode: 200)

        // Mock repository existence check (404 means doesn't exist)
        MockURLProtocol.setMockResponse(for: "https://api.github.com/repos/testuser/integration-test-repo", data: Data(), statusCode: 404)

        // Mock successful repository creation
        let mockRepoData = MockURLProtocol.mockSuccessfulRepository(name: "integration-test-repo", description: "Integration test repository")
        MockURLProtocol.setMockResponse(for: "https://api.github.com/user/repos", data: mockRepoData, statusCode: 201)

        // When: Creating repository through full flow
        let result = await gitHubService.createPrivateRepository(name: "integration-test-repo", description: "Integration test repository")

        // Then: Should succeed with all expected values
        switch result {
        case .success(let repository):
            XCTAssertEqual(repository.name, "integration-test-repo")
            XCTAssertEqual(repository.description, "Integration test repository")
            XCTAssertTrue(repository.isPrivate)
            XCTAssertEqual(repository.owner.login, "testuser")
            XCTAssertEqual(repository.fullName, "testuser/integration-test-repo")
            XCTAssertEqual(repository.htmlUrl, "https://github.com/testuser/integration-test-repo")
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
}
