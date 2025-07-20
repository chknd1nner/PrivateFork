import Foundation

/// Protocol defining the orchestration of the complete private fork creation workflow
/// Coordinates KeychainService, GitHubService, and GitService to create a private fork
/// of a public repository with real-time status updates and comprehensive error handling
protocol PrivateForkOrchestratorProtocol {
    /// Creates a private fork of a public repository
    /// - Parameters:
    ///   - repositoryURL: The URL of the public GitHub repository to fork
    ///   - localPath: The local directory path where the repository should be cloned
    ///   - statusCallback: Callback function for real-time status updates during the workflow
    /// - Returns: Result containing success message or PrivateForkError on failure
    func createPrivateFork(
        repositoryURL: String,
        localPath: String,
        statusCallback: @escaping (String) -> Void
    ) async -> Result<String, PrivateForkError>
}

/// Comprehensive error types for the private fork orchestration workflow
enum PrivateForkError: Error, LocalizedError {
    case invalidRepositoryURL
    case invalidLocalPath
    case credentialValidationFailed(KeychainError)
    case repositoryCreationFailed(GitHubServiceError)
    case gitOperationFailed(Error)
    case cleanupFailed(Error)
    case workflowInterrupted(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRepositoryURL:
            return "Invalid repository URL provided"
        case .invalidLocalPath:
            return "Invalid local path provided"
        case .credentialValidationFailed(let keychainError):
            return "Credential validation failed: \(keychainError.localizedDescription)"
        case .repositoryCreationFailed(let gitHubError):
            return "Repository creation failed: \(gitHubError.localizedDescription)"
        case .gitOperationFailed(let error):
            return "Git operation failed: \(error.localizedDescription)"
        case .cleanupFailed(let error):
            return "Cleanup failed: \(error.localizedDescription)"
        case .workflowInterrupted(let message):
            return "Workflow interrupted: \(message)"
        }
    }
}