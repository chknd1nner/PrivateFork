import Foundation

struct CLIArguments {
    let repositoryURL: String
    let localPath: String
}

enum CLIError: Error, LocalizedError, Equatable {
    case invalidArguments(String)
    case invalidURL(String)
    case invalidPath(String)
    case credentialsNotConfigured
    case credentialValidationFailed
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidArguments(let details):
            return "Invalid arguments: \(details)"
        case .invalidURL(let url):
            return "Invalid repository URL: \(url)"
        case .invalidPath(let path):
            return "Invalid local path: \(path)"
        case .credentialsNotConfigured:
            return "Credentials not configured. Please launch the GUI to configure GitHub credentials."
        case .credentialValidationFailed:
            return "Credential validation failed. Please check your GitHub token in the GUI."
        case .operationFailed(let details):
            return "Operation failed: \(details)"
        }
    }
}

enum CLIExitCode: Int32 {
    case success = 0
    case invalidArguments = 1
    case credentialsNotConfigured = 2
    case credentialValidationFailed = 3
    case operationFailed = 4
}
