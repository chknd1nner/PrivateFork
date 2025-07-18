import Foundation

protocol GitHubServiceProtocol {
    /// Validates GitHub credentials by making an authenticated request to GitHub API
    /// - Returns: Result containing GitHubUser on success or GitHubServiceError on failure
    func validateCredentials() async -> Result<GitHubUser, GitHubServiceError>

    /// Creates a private repository on GitHub with the specified name and description
    /// - Parameters:
    ///   - name: Repository name (required)
    ///   - description: Repository description (optional)
    /// - Returns: Result containing GitHubRepository on success or GitHubServiceError on failure
    func createPrivateRepository(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError>

    /// Retrieves the authenticated user's GitHub profile information
    /// - Returns: Result containing GitHubUser on success or GitHubServiceError on failure
    func getCurrentUser() async -> Result<GitHubUser, GitHubServiceError>

    /// Checks if a repository with the given name already exists for the authenticated user
    /// - Parameter name: Repository name to check
    /// - Returns: Result containing Boolean (true if exists) or GitHubServiceError on failure
    func repositoryExists(name: String) async -> Result<Bool, GitHubServiceError>
}
