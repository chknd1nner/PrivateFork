import Foundation

// MARK: - Git Service Protocol
protocol GitServiceProtocol {
    
    // MARK: - Repository Operations
    
    /// Clone a repository from a remote URL to a local directory
    /// - Parameters:
    ///   - repoURL: The URL of the repository to clone
    ///   - localPath: The local directory where the repository should be cloned
    /// - Returns: Result containing success message or error
    func clone(repoURL: URL, to localPath: URL) async -> Result<String, Error>
    
    // MARK: - Remote Configuration
    
    /// Add a new remote to a Git repository
    /// - Parameters:
    ///   - name: The name of the remote (e.g., "origin", "upstream")
    ///   - url: The URL of the remote repository
    ///   - path: The local path to the Git repository
    /// - Returns: Result containing success message or error
    func addRemote(name: String, url: URL, at path: URL) async -> Result<String, Error>
    
    /// Set the URL of an existing remote
    /// - Parameters:
    ///   - name: The name of the remote to modify
    ///   - url: The new URL for the remote
    ///   - path: The local path to the Git repository
    /// - Returns: Result containing success message or error
    func setRemoteURL(name: String, url: URL, at path: URL) async -> Result<String, Error>
    
    // MARK: - Push Operations
    
    /// Push changes to a remote repository
    /// - Parameters:
    ///   - remoteName: The name of the remote to push to
    ///   - branch: The branch to push
    ///   - path: The local path to the Git repository
    ///   - force: Whether to force push (default: false)
    /// - Returns: Result containing success message or error
    func push(remoteName: String, branch: String, at path: URL, force: Bool) async -> Result<String, Error>
    
    // MARK: - Repository Status
    
    /// Get the current status of a Git repository
    /// - Parameter path: The local path to the Git repository
    /// - Returns: Result containing status information or error
    func status(at path: URL) async -> Result<String, Error>
    
    /// Check if a directory is a valid Git repository
    /// - Parameter path: The local path to check
    /// - Returns: Result containing validation result or error
    func isValidRepository(at path: URL) async -> Result<Bool, Error>
}