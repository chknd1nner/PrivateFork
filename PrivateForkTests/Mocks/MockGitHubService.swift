import Foundation
@testable import PrivateFork

class MockGitHubService: GitHubServiceProtocol {
    // Result-driven properties for each protocol method
    var validateCredentialsResult: Result<GitHubUser, GitHubServiceError>!
    var createPrivateRepositoryResult: Result<GitHubRepository, GitHubServiceError>!
    var getCurrentUserResult: Result<GitHubUser, GitHubServiceError>!
    var repositoryExistsResult: Result<Bool, GitHubServiceError>!
    var deleteRepositoryResult: Result<Void, GitHubServiceError>!
    var initiateDeviceFlowResult: Result<GitHubDeviceCodeResponse, GitHubServiceError>!
    var pollForAccessTokenResult: Result<Void, GitHubServiceError>!
    
    // Call tracking for verification
    var validateCredentialsCallCount = 0
    var createPrivateRepositoryCallCount = 0
    var getCurrentUserCallCount = 0
    var repositoryExistsCallCount = 0
    var deleteRepositoryCallCount = 0
    var initiateDeviceFlowCallCount = 0
    var pollForAccessTokenCallCount = 0
    
    // Last call parameters for verification
    var lastCreateRepositoryName: String?
    var lastCreateRepositoryDescription: String?
    var lastRepositoryExistsName: String?
    var lastDeleteRepositoryName: String?
    var lastPollDeviceCode: String?
    var lastPollInterval: Int?
    var lastPollExpiresIn: Int?

    // MARK: - GitHubServiceProtocol Implementation

    func validateCredentials() async -> Result<GitHubUser, GitHubServiceError> {
        validateCredentialsCallCount += 1
        return validateCredentialsResult
    }

    func createPrivateRepository(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError> {
        createPrivateRepositoryCallCount += 1
        lastCreateRepositoryName = name
        lastCreateRepositoryDescription = description
        return createPrivateRepositoryResult
    }

    func getCurrentUser() async -> Result<GitHubUser, GitHubServiceError> {
        getCurrentUserCallCount += 1
        return getCurrentUserResult
    }

    func repositoryExists(name: String) async -> Result<Bool, GitHubServiceError> {
        repositoryExistsCallCount += 1
        lastRepositoryExistsName = name
        return repositoryExistsResult
    }
    
    func deleteRepository(name: String) async -> Result<Void, GitHubServiceError> {
        deleteRepositoryCallCount += 1
        lastDeleteRepositoryName = name
        return deleteRepositoryResult
    }
    
    func initiateDeviceFlow() async -> Result<GitHubDeviceCodeResponse, GitHubServiceError> {
        initiateDeviceFlowCallCount += 1
        return initiateDeviceFlowResult
    }
    
    func pollForAccessToken(deviceCode: String, interval: Int, expiresIn: Int) async -> Result<Void, GitHubServiceError> {
        pollForAccessTokenCallCount += 1
        lastPollDeviceCode = deviceCode
        lastPollInterval = interval
        lastPollExpiresIn = expiresIn
        return pollForAccessTokenResult
    }

    // MARK: - Test Helper Methods
    
    func resetMockState() {
        validateCredentialsResult = nil
        createPrivateRepositoryResult = nil
        getCurrentUserResult = nil
        repositoryExistsResult = nil
        deleteRepositoryResult = nil
        initiateDeviceFlowResult = nil
        pollForAccessTokenResult = nil
        
        validateCredentialsCallCount = 0
        createPrivateRepositoryCallCount = 0
        getCurrentUserCallCount = 0
        repositoryExistsCallCount = 0
        deleteRepositoryCallCount = 0
        initiateDeviceFlowCallCount = 0
        pollForAccessTokenCallCount = 0
        
        lastCreateRepositoryName = nil
        lastCreateRepositoryDescription = nil
        lastRepositoryExistsName = nil
        lastDeleteRepositoryName = nil
        lastPollDeviceCode = nil
        lastPollInterval = nil
        lastPollExpiresIn = nil
    }
    
    func setupSuccessResults() {
        let mockUser = Self.defaultMockUser()
        let mockRepository = Self.defaultMockRepository()
        let mockDeviceFlow = Self.defaultMockDeviceFlowResponse()
        
        validateCredentialsResult = .success(mockUser)
        createPrivateRepositoryResult = .success(mockRepository)
        getCurrentUserResult = .success(mockUser)
        repositoryExistsResult = .success(false)
        deleteRepositoryResult = .success(())
        initiateDeviceFlowResult = .success(mockDeviceFlow)
        pollForAccessTokenResult = .success(())
    }

    // MARK: - Default Mock Data

    static func defaultMockUser() -> GitHubUser {
        return GitHubUser(
            login: "testuser",
            id: 12345,
            name: "Test User",
            email: "test@example.com",
            company: "Test Company",
            location: "Test Location",
            bio: "Test bio",
            publicRepos: 5,
            privateRepos: 2,
            totalPrivateRepos: 2,
            plan: GitHubPlan(
                name: "pro",
                space: 976562499,
                collaborators: 0,
                privateRepos: 9999
            )
        )
    }
    
    static func defaultMockRepository() -> GitHubRepository {
        return GitHubRepository(
            id: 123456,
            name: "test-repo",
            fullName: "testuser/test-repo",
            description: "Test repository",
            isPrivate: true,
            htmlUrl: "https://github.com/testuser/test-repo",
            cloneUrl: "https://github.com/testuser/test-repo.git",
            sshUrl: "git@github.com:testuser/test-repo.git",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            pushedAt: ISO8601DateFormatter().string(from: Date()),
            size: 0,
            language: "Swift",
            owner: GitHubOwner(
                login: "testuser",
                id: 12345,
                type: "User"
            )
        )
    }
    
    static func defaultMockDeviceFlowResponse() -> GitHubDeviceCodeResponse {
        return GitHubDeviceCodeResponse(
            deviceCode: "3584d83530557fdd1f46af8289938c8ef79f9dc5",
            userCode: "WDJB-MJHT",
            verificationUri: "https://github.com/login/device",
            expiresIn: 900,
            interval: 5
        )
    }
}
