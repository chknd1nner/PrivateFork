import Foundation
@testable import PrivateFork

class MockGitHubService: GitHubServiceProtocol {
    // Mock state
    private var mockUser: GitHubUser?
    private var mockRepositories: [String: GitHubRepository] = [:]
    private var existingRepositories: Set<String> = []

    // Control flags for testing different scenarios
    var shouldFailValidation = false
    var shouldFailRepositoryCreation = false
    var shouldFailRepositoryExists = false
    var shouldFailGetCurrentUser = false

    // Specific error scenarios
    var validationError: GitHubServiceError?
    var repositoryCreationError: GitHubServiceError?
    var repositoryExistsError: GitHubServiceError?
    var getCurrentUserError: GitHubServiceError?

    // Rate limiting simulation
    var shouldSimulateRateLimit = false
    var rateLimitRetryAfter: Date?

    // MARK: - GitHubServiceProtocol Implementation

    func validateCredentials() async -> Result<GitHubUser, GitHubServiceError> {
        if shouldFailValidation {
            return .failure(validationError ?? .authenticationFailed)
        }

        if shouldSimulateRateLimit {
            return .failure(.rateLimited(retryAfter: rateLimitRetryAfter))
        }

        guard let user = mockUser else {
            return .failure(.authenticationFailed)
        }

        return .success(user)
    }

    func createPrivateRepository(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError> {
        if shouldFailRepositoryCreation {
            return .failure(repositoryCreationError ?? .unexpectedError("Repository creation failed"))
        }

        if shouldSimulateRateLimit {
            return .failure(.rateLimited(retryAfter: rateLimitRetryAfter))
        }

        // Check if repository already exists
        if existingRepositories.contains(name) {
            return .failure(.repositoryNameConflict(name))
        }

        // Validate repository name
        if name.isEmpty || name.count > 100 {
            return .failure(.invalidRepositoryName)
        }

        // Create mock repository
        let repository = GitHubRepository(
            id: Int.random(in: 1...1000000),
            name: name,
            fullName: "\(mockUser?.login ?? "testuser")/\(name)",
            description: description,
            isPrivate: true,
            htmlUrl: "https://github.com/\(mockUser?.login ?? "testuser")/\(name)",
            cloneUrl: "https://github.com/\(mockUser?.login ?? "testuser")/\(name).git",
            sshUrl: "git@github.com:\(mockUser?.login ?? "testuser")/\(name).git",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            pushedAt: ISO8601DateFormatter().string(from: Date()),
            size: 0,
            language: "Swift",
            owner: GitHubOwner(
                login: mockUser?.login ?? "testuser",
                id: mockUser?.id ?? 12345,
                type: "User"
            )
        )

        // Store the repository
        mockRepositories[name] = repository
        existingRepositories.insert(name)

        return .success(repository)
    }

    func getCurrentUser() async -> Result<GitHubUser, GitHubServiceError> {
        if shouldFailGetCurrentUser {
            return .failure(getCurrentUserError ?? .authenticationFailed)
        }

        if shouldSimulateRateLimit {
            return .failure(.rateLimited(retryAfter: rateLimitRetryAfter))
        }

        guard let user = mockUser else {
            return .failure(.authenticationFailed)
        }

        return .success(user)
    }

    func repositoryExists(name: String) async -> Result<Bool, GitHubServiceError> {
        if shouldFailRepositoryExists {
            return .failure(repositoryExistsError ?? .networkError(NSError(domain: "MockError", code: -1)))
        }

        if shouldSimulateRateLimit {
            return .failure(.rateLimited(retryAfter: rateLimitRetryAfter))
        }

        return .success(existingRepositories.contains(name))
    }

    // MARK: - Test Helper Methods

    func setMockUser(_ user: GitHubUser) {
        mockUser = user
    }

    func addExistingRepository(name: String) {
        existingRepositories.insert(name)
    }

    func removeExistingRepository(name: String) {
        existingRepositories.remove(name)
    }

    func clearExistingRepositories() {
        existingRepositories.removeAll()
        mockRepositories.removeAll()
    }

    func setValidationError(_ error: GitHubServiceError) {
        validationError = error
        shouldFailValidation = true
    }

    func setRepositoryCreationError(_ error: GitHubServiceError) {
        repositoryCreationError = error
        shouldFailRepositoryCreation = true
    }

    func setRepositoryExistsError(_ error: GitHubServiceError) {
        repositoryExistsError = error
        shouldFailRepositoryExists = true
    }

    func setGetCurrentUserError(_ error: GitHubServiceError) {
        getCurrentUserError = error
        shouldFailGetCurrentUser = true
    }

    func simulateRateLimit(retryAfter: Date? = nil) {
        shouldSimulateRateLimit = true
        rateLimitRetryAfter = retryAfter
    }

    func resetMockState() {
        mockUser = nil
        mockRepositories.removeAll()
        existingRepositories.removeAll()

        shouldFailValidation = false
        shouldFailRepositoryCreation = false
        shouldFailRepositoryExists = false
        shouldFailGetCurrentUser = false

        validationError = nil
        repositoryCreationError = nil
        repositoryExistsError = nil
        getCurrentUserError = nil

        shouldSimulateRateLimit = false
        rateLimitRetryAfter = nil
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

    func setupDefaultMockData() {
        setMockUser(MockGitHubService.defaultMockUser())
    }
}
