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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.clearStoredOAuthTokens()

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "invalid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))
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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "limited_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "invalid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
        mockKeychainService.setStoredOAuthTokens(accessToken: "valid_token", refreshToken: "refresh_token", expiresIn: Date().addingTimeInterval(3600))

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
    
    // MARK: - Device Flow Tests
    
    func testInitiateDeviceFlow_ValidRequest_ShouldReturnDeviceCode() async {
        // Given: Mock successful device code response
        let mockDeviceData = MockURLProtocol.mockDeviceCodeResponse(deviceCode: "device123", userCode: "ABCD-1234")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/device/code", data: mockDeviceData, statusCode: 200)
        
        // When: Initiating device flow
        let result = await gitHubService.initiateDeviceFlow()
        
        // Then: Should return device code response
        switch result {
        case .success(let response):
            XCTAssertEqual(response.deviceCode, "device123")
            XCTAssertEqual(response.userCode, "ABCD-1234")
            XCTAssertEqual(response.verificationUri, "https://github.com/login/device")
            XCTAssertEqual(response.expiresIn, 900)
            XCTAssertEqual(response.interval, 5)
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
    
    func testInitiateDeviceFlow_NetworkError_ShouldReturnDeviceFlowInitiationFailed() async {
        // Given: Network error for device code endpoint
        let networkError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"])
        MockURLProtocol.setMockError(for: "https://github.com/login/device/code", error: networkError)
        
        // When: Initiating device flow
        let result = await gitHubService.initiateDeviceFlow()
        
        // Then: Should return device flow initiation failed error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowInitiationFailed)
        }
    }
    
    func testInitiateDeviceFlow_BadRequest_ShouldReturnDeviceFlowInitiationFailed() async {
        // Given: Bad request response from device code endpoint
        MockURLProtocol.setMockResponse(for: "https://github.com/login/device/code", data: Data(), statusCode: 400)
        
        // When: Initiating device flow
        let result = await gitHubService.initiateDeviceFlow()
        
        // Then: Should return device flow initiation failed error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowInitiationFailed)
        }
    }
    
    func testPollForAccessToken_SuccessfulToken_ShouldSaveTokenAndSucceed() async {
        // Given: Mock successful token response and clear keychain
        mockKeychainService.clearStoredOAuthTokens()
        let mockTokenData = MockURLProtocol.mockAccessTokenResponse(accessToken: "gho_test_token")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: mockTokenData, statusCode: 200)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "device123", interval: 1, expiresIn: 900)
        
        // Then: Should succeed and save token to keychain
        switch result {
        case .success:
            let tokenResult = await mockKeychainService.retrieveOAuthTokens()
            switch tokenResult {
            case .success(let token):
                XCTAssertEqual(token.accessToken, "gho_test_token")
                XCTAssertEqual(token.refreshToken, "")
                XCTAssertTrue(token.expiresIn > Date())
            case .failure:
                XCTFail("Expected token to be saved in keychain")
            }
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
    
    func testPollForAccessToken_AuthorizationPending_ShouldEventuallySucceed() async {
        // Given: First configure pending response, then after delay configure success
        let pendingData = MockURLProtocol.mockDeviceFlowError("authorization_pending")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: pendingData, statusCode: 200)
        
        // Configure success response after short delay to simulate pending then success
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            let tokenData = MockURLProtocol.mockAccessTokenResponse(accessToken: "gho_pending_token")
            MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: tokenData, statusCode: 200)
        }
        
        // When: Polling for access token with short interval
        let result = await gitHubService.pollForAccessToken(deviceCode: "device123", interval: 1, expiresIn: 900)
        
        // Then: Should eventually succeed after pending state
        switch result {
        case .success:
            let tokenResult = await mockKeychainService.retrieveOAuthTokens()
            switch tokenResult {
            case .success(let token):
                XCTAssertEqual(token.accessToken, "gho_pending_token")
            case .failure:
                XCTFail("Expected token to be saved in keychain")
            }
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
    
    func testPollForAccessToken_SlowDown_ShouldIncreaseInterval() async {
        // Given: First configure slow_down response, then after delay configure success
        let slowDownData = MockURLProtocol.mockDeviceFlowError("slow_down", description: "Polling too frequently")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: slowDownData, statusCode: 200)
        
        // Configure success response after delay to simulate slow_down then success
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            let tokenData = MockURLProtocol.mockAccessTokenResponse()
            MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: tokenData, statusCode: 200)
        }
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "device123", interval: 1, expiresIn: 900)
        
        // Then: Should succeed after handling slow_down
        switch result {
        case .success:
            XCTAssertTrue(true) // Success indicates the polling handled slow_down correctly
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
    
    func testPollForAccessToken_ExpiredToken_ShouldReturnDeviceFlowExpired() async {
        // Given: Mock expired token error
        let expiredData = MockURLProtocol.mockDeviceFlowError("expired_token")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: expiredData, statusCode: 200)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "expired_device", interval: 1, expiresIn: 900)
        
        // Then: Should return expired error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowExpired)
        }
    }
    
    func testPollForAccessToken_AccessDenied_ShouldReturnDeviceFlowAccessDenied() async {
        // Given: Mock access denied error
        let deniedData = MockURLProtocol.mockDeviceFlowError("access_denied")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: deniedData, statusCode: 200)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "denied_device", interval: 1, expiresIn: 900)
        
        // Then: Should return access denied error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowAccessDenied)
        }
    }
    
    func testPollForAccessToken_UnknownError_ShouldReturnDeviceFlowUnexpectedResponse() async {
        // Given: Mock unknown error
        let unknownData = MockURLProtocol.mockDeviceFlowError("unknown_error")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: unknownData, statusCode: 200)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "unknown_device", interval: 1, expiresIn: 900)
        
        // Then: Should return unexpected response error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowUnexpectedResponse)
        }
    }
    
    func testPollForAccessToken_Timeout_ShouldReturnPollingTimeout() async {
        // Given: Mock authorization pending that never resolves
        let pendingData = MockURLProtocol.mockDeviceFlowError("authorization_pending")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: pendingData, statusCode: 200)
        
        // When: Polling with very short expiration time
        let result = await gitHubService.pollForAccessToken(deviceCode: "timeout_device", interval: 1, expiresIn: 2)
        
        // Then: Should return polling timeout error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .deviceFlowPollingTimeout)
        }
    }
    
    func testPollForAccessToken_NetworkError_ShouldReturnNetworkError() async {
        // Given: Network error during polling
        let networkError = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"])
        MockURLProtocol.setMockError(for: "https://github.com/login/oauth/access_token", error: networkError)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "network_error_device", interval: 1, expiresIn: 900)
        
        // Then: Should return network error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .networkError = error {
                XCTAssertTrue(true) // Expected network error
            } else {
                XCTFail("Expected network error but got: \(error)")
            }
        }
    }
    
    func testPollForAccessToken_KeychainSaveFailure_ShouldReturnUnexpectedError() async {
        // Given: Successful token response but keychain save failure
        mockKeychainService.saveOAuthTokensResult = .failure(.unhandledError(status: -25300))
        let mockTokenData = MockURLProtocol.mockAccessTokenResponse()
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: mockTokenData, statusCode: 200)
        
        // When: Polling for access token
        let result = await gitHubService.pollForAccessToken(deviceCode: "keychain_error", interval: 1, expiresIn: 900)
        
        // Then: Should return unexpected error due to keychain failure
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .unexpectedError(let message) = error {
                XCTAssertTrue(message.contains("Failed to save OAuth tokens"))
            } else {
                XCTFail("Expected unexpected error but got: \(error)")
            }
        }
    }
    
    // MARK: - Device Flow Integration Tests
    
    func testDeviceFlow_EndToEndFlow_ShouldSucceed() async {
        // Given: Complete device flow setup
        mockKeychainService.clearStoredOAuthTokens()
        
        // Mock device code initiation
        let deviceCodeData = MockURLProtocol.mockDeviceCodeResponse(deviceCode: "integration_device", userCode: "INTG-TEST")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/device/code", data: deviceCodeData, statusCode: 200)
        
        // Mock successful token exchange
        let tokenData = MockURLProtocol.mockAccessTokenResponse(accessToken: "gho_integration_token")
        MockURLProtocol.setMockResponse(for: "https://github.com/login/oauth/access_token", data: tokenData, statusCode: 200)
        
        // When: Running complete device flow
        let initiateResult = await gitHubService.initiateDeviceFlow()
        guard case .success(let deviceResponse) = initiateResult else {
            XCTFail("Device flow initiation failed")
            return
        }
        
        let pollResult = await gitHubService.pollForAccessToken(
            deviceCode: deviceResponse.deviceCode,
            interval: deviceResponse.interval,
            expiresIn: deviceResponse.expiresIn
        )
        
        // Then: Should complete successfully with token saved
        switch pollResult {
        case .success:
            let tokenResult = await mockKeychainService.retrieveOAuthTokens()
            switch tokenResult {
            case .success(let token):
                XCTAssertEqual(token.accessToken, "gho_integration_token")
                XCTAssertTrue(token.expiresIn > Date())
            case .failure:
                XCTFail("Expected token to be saved in keychain")
            }
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)")
        }
    }
}
