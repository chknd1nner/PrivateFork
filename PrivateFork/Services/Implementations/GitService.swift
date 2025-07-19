import Foundation

// MARK: - Git Service Error Types
enum GitServiceError: Error, LocalizedError {
    case invalidURL(String)
    case invalidPath(String)
    case repositoryNotFound(String)
    case remoteAlreadyExists(String)
    case remoteNotFound(String)
    case authenticationFailed
    case networkError(String)
    case commandExecutionFailed(String)
    case invalidRepository(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid repository URL: \(url)"
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        case .repositoryNotFound(let repo):
            return "Repository not found: \(repo)"
        case .remoteAlreadyExists(let name):
            return "Remote '\(name)' already exists"
        case .remoteNotFound(let name):
            return "Remote '\(name)' not found"
        case .authenticationFailed:
            return "Git authentication failed"
        case .networkError(let message):
            return "Network error: \(message)"
        case .commandExecutionFailed(let message):
            return "Git command failed: \(message)"
        case .invalidRepository(let path):
            return "Invalid Git repository at: \(path)"
        }
    }
}

// MARK: - Git Service Implementation
class GitService: GitServiceProtocol {
    private let shell: ShellProtocol
    private let timeout: TimeInterval
    
    // MARK: - Initialization
    
    init(shell: ShellProtocol = Shell(), timeout: TimeInterval = 60.0) {
        self.shell = shell
        self.timeout = timeout
    }
    
    // MARK: - Repository Operations
    
    func clone(repoURL: URL, to localPath: URL) async -> Result<String, Error> {
        // Validate inputs
        guard isValidGitURL(repoURL) else {
            return .failure(GitServiceError.invalidURL(repoURL.absoluteString))
        }
        
        // Ensure parent directory exists
        let parentDirectory = localPath.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
            } catch {
                return .failure(GitServiceError.invalidPath("Cannot create parent directory: \(parentDirectory.path)"))
            }
        }
        
        // Execute git clone command
        let arguments = ["clone", repoURL.absoluteString, localPath.path]
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: nil, timeout: timeout)
        
        switch result {
        case .success(let output):
            return .success("Repository cloned successfully: \(output)")
        case .failure(let shellError):
            return .failure(mapShellErrorToGitError(shellError, operation: "clone"))
        }
    }
    
    // MARK: - Remote Configuration
    
    func addRemote(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        // Validate repository exists
        let validationResult = await isValidRepository(at: path)
        switch validationResult {
        case .success(let isValid):
            guard isValid else {
                return .failure(GitServiceError.invalidRepository(path.path))
            }
        case .failure(let error):
            return .failure(error)
        }
        
        // Validate remote name and URL
        guard !name.isEmpty, isValidGitURL(url) else {
            return .failure(GitServiceError.invalidURL(url.absoluteString))
        }
        
        // Execute git remote add command
        let arguments = ["remote", "add", name, url.absoluteString]
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: path, timeout: timeout)
        
        switch result {
        case .success(let output):
            return .success("Remote '\(name)' added successfully: \(output)")
        case .failure(let shellError):
            return .failure(mapShellErrorToGitError(shellError, operation: "add remote"))
        }
    }
    
    func setRemoteURL(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        // Validate repository exists
        let validationResult = await isValidRepository(at: path)
        switch validationResult {
        case .success(let isValid):
            guard isValid else {
                return .failure(GitServiceError.invalidRepository(path.path))
            }
        case .failure(let error):
            return .failure(error)
        }
        
        // Validate remote name and URL
        guard !name.isEmpty, isValidGitURL(url) else {
            return .failure(GitServiceError.invalidURL(url.absoluteString))
        }
        
        // Execute git remote set-url command
        let arguments = ["remote", "set-url", name, url.absoluteString]
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: path, timeout: timeout)
        
        switch result {
        case .success(let output):
            return .success("Remote '\(name)' URL updated successfully: \(output)")
        case .failure(let shellError):
            return .failure(mapShellErrorToGitError(shellError, operation: "set remote URL"))
        }
    }
    
    // MARK: - Push Operations
    
    func push(remoteName: String, branch: String, at path: URL, force: Bool = false) async -> Result<String, Error> {
        // Validate repository exists
        let validationResult = await isValidRepository(at: path)
        switch validationResult {
        case .success(let isValid):
            guard isValid else {
                return .failure(GitServiceError.invalidRepository(path.path))
            }
        case .failure(let error):
            return .failure(error)
        }
        
        // Validate inputs
        guard !remoteName.isEmpty, !branch.isEmpty else {
            return .failure(GitServiceError.commandExecutionFailed("Remote name and branch cannot be empty"))
        }
        
        // Build push arguments
        var arguments = ["push"]
        if force {
            arguments.append("--force")
        }
        arguments.append(remoteName)
        arguments.append(branch)
        
        // Execute git push command with extended timeout for potentially large uploads
        let pushTimeout = max(timeout, 300.0) // Minimum 5 minutes for push operations
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: path, timeout: pushTimeout)
        
        switch result {
        case .success(let output):
            return .success("Push to '\(remoteName)' completed successfully: \(output)")
        case .failure(let shellError):
            return .failure(mapShellErrorToGitError(shellError, operation: "push"))
        }
    }
    
    // MARK: - Repository Status
    
    func status(at path: URL) async -> Result<String, Error> {
        // Validate repository exists
        let validationResult = await isValidRepository(at: path)
        switch validationResult {
        case .success(let isValid):
            guard isValid else {
                return .failure(GitServiceError.invalidRepository(path.path))
            }
        case .failure(let error):
            return .failure(error)
        }
        
        // Execute git status command
        let arguments = ["status", "--porcelain"]
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: path, timeout: timeout)
        
        switch result {
        case .success(let output):
            return .success(output.isEmpty ? "Working tree clean" : output)
        case .failure(let shellError):
            return .failure(mapShellErrorToGitError(shellError, operation: "status"))
        }
    }
    
    func isValidRepository(at path: URL) async -> Result<Bool, Error> {
        // Check if path exists
        guard FileManager.default.fileExists(atPath: path.path) else {
            return .failure(GitServiceError.invalidPath(path.path))
        }
        
        // Execute git rev-parse command to check if it's a valid repository
        let arguments = ["rev-parse", "--git-dir"]
        let result = await shell.execute(command: "git", arguments: arguments, workingDirectory: path, timeout: timeout)
        
        switch result {
        case .success:
            return .success(true)
        case .failure:
            return .success(false)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func isValidGitURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        return urlString.hasPrefix("https://") || 
               urlString.hasPrefix("git://") || 
               urlString.hasPrefix("ssh://") ||
               urlString.contains("@") // SSH format: git@github.com:user/repo.git
    }
    
    private func mapShellErrorToGitError(_ shellError: ShellError, operation: String) -> GitServiceError {
        switch shellError {
        case .commandNotFound:
            return .commandExecutionFailed("Git command not found")
        case .executionFailed(_, let stderr):
            // Parse common Git error patterns
            let lowerStderr = stderr.lowercased()
            if lowerStderr.contains("authentication failed") || lowerStderr.contains("permission denied") {
                return .authenticationFailed
            } else if lowerStderr.contains("network") || lowerStderr.contains("connection") {
                return .networkError(stderr)
            } else if lowerStderr.contains("not found") || lowerStderr.contains("does not exist") {
                return .repositoryNotFound(stderr)
            } else if lowerStderr.contains("already exists") {
                return .remoteAlreadyExists(stderr)
            } else {
                return .commandExecutionFailed("Git \(operation) failed: \(stderr)")
            }
        case .timeout(let command, let duration):
            return .commandExecutionFailed("Git \(operation) timed out after \(duration) seconds: \(command)")
        case .invalidWorkingDirectory(let url):
            return .invalidPath(url.path)
        case .processingError(let message):
            return .commandExecutionFailed("Processing error during \(operation): \(message)")
        }
    }
}