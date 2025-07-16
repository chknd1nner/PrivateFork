import Foundation

protocol GitHubValidationServiceProtocol {
    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError>
}

enum GitHubValidationError: Error, LocalizedError {
    case invalidUsername
    case invalidToken
    case networkError
    case authenticationFailed
    case rateLimitExceeded
    case serverError

    var errorDescription: String? {
        switch self {
        case .invalidUsername:
            return "Invalid GitHub username format"
        case .invalidToken:
            return "Invalid Personal Access Token format"
        case .networkError:
            return "Network connection error"
        case .authenticationFailed:
            return "Authentication failed - check your credentials"
        case .rateLimitExceeded:
            return "GitHub API rate limit exceeded"
        case .serverError:
            return "GitHub server error"
        }
    }
}
