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
    
    /// Deletes a repository from the authenticated user's GitHub account
    /// - Parameter name: Repository name to delete
    /// - Returns: Result containing Void on success or GitHubServiceError on failure
    func deleteRepository(name: String) async -> Result<Void, GitHubServiceError>
    
    // MARK: - OAuth Device Flow Methods
    
    /// Initiates the GitHub OAuth 2.0 device flow
    /// - Returns: A result containing device flow response data on success or GitHubServiceError on failure
    func initiateDeviceFlow() async -> Result<GitHubDeviceCodeResponse, GitHubServiceError>
    
    /// Polls the GitHub OAuth token endpoint for device flow completion
    /// - Parameters:
    ///   - deviceCode: The device code from initiation response
    ///   - interval: Polling interval in seconds
    ///   - expiresIn: Expiration time in seconds
    /// - Returns: A result containing success or GitHubServiceError on failure
    func pollForAccessToken(deviceCode: String, interval: Int, expiresIn: Int) async -> Result<Void, GitHubServiceError>
}
