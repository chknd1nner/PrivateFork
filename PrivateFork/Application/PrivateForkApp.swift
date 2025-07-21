import SwiftUI

struct PrivateForkApp: App {
    private let mainViewModel: MainViewModel
    private let keychainService: KeychainServiceProtocol
    private let gitHubValidationService: GitHubValidationServiceProtocol
    
    init() {
        // Create services based on test mode
        self.keychainService = Self.createKeychainService()
        let gitHubService = Self.createGitHubService(keychainService: self.keychainService)
        let gitService = Self.createGitService()
        let orchestrator = Self.createOrchestrator(
            keychainService: self.keychainService,
            gitHubService: gitHubService,
            gitService: gitService
        )
        
        // Create view model with proper dependency injection
        self.mainViewModel = MainViewModel(
            keychainService: self.keychainService,
            privateForkOrchestrator: orchestrator
        )
        
        self.gitHubValidationService = Self.createGitHubValidationService()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: mainViewModel, 
                    keychainService: keychainService,
                    gitHubValidationService: gitHubValidationService)
        }
    }
    
    private static func createKeychainService() -> KeychainServiceProtocol {
        // TESTING MODE: Use mock services during UI tests to prevent keychain dialogs
        if isRunningUITests() {
            print("🔍 DEBUG: Using TestingKeychainService for UI tests")
            return TestingKeychainService()
        }
        print("🔍 DEBUG: Using real KeychainService")
        return KeychainService()
    }
    
    private static func createGitHubService(keychainService: KeychainServiceProtocol) -> GitHubServiceProtocol {
        // TESTING MODE: Use mock services during UI tests to prevent network calls
        if isRunningUITests() {
            return TestingGitHubService()
        }
        return GitHubService(keychainService: keychainService)
    }
    
    private static func createGitService() -> GitServiceProtocol {
        // TESTING MODE: Use mock services during UI tests to prevent git operations
        if isRunningUITests() {
            return TestingGitService()
        }
        return GitService()
    }
    
    private static func createOrchestrator(
        keychainService: KeychainServiceProtocol,
        gitHubService: GitHubServiceProtocol,
        gitService: GitServiceProtocol
    ) -> PrivateForkOrchestratorProtocol {
        return PrivateForkOrchestrator(
            keychainService: keychainService,
            gitHubService: gitHubService,
            gitService: gitService
        )
    }
    
    private static func createGitHubValidationService() -> GitHubValidationServiceProtocol {
        // TESTING MODE: Use mock services during UI tests to prevent network calls
        if isRunningUITests() {
            return TestingGitHubValidationService()
        }
        return GitHubValidationService()
    }
    
    private static func isRunningUITests() -> Bool {
        // Check if we're running in UI test mode
        let hasXCTestConfig = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let hasUITestingMode = ProcessInfo.processInfo.arguments.contains("UI_TESTING_MODE")
        
        // DEBUG: Print environment to understand test detection
        print("🔍 DEBUG: isRunningUITests() called")
        print("🔍 DEBUG: XCTestConfigurationFilePath exists: \(hasXCTestConfig)")
        print("🔍 DEBUG: UI_TESTING_MODE argument exists: \(hasUITestingMode)")
        print("🔍 DEBUG: All arguments: \(ProcessInfo.processInfo.arguments)")
        
        return hasXCTestConfig || hasUITestingMode
    }
}

// MARK: - Testing Services
// Lightweight mock services for UI testing to prevent keychain dialogs
private class TestingKeychainService: KeychainServiceProtocol {
    func save(username: String, token: String) async -> Result<Void, KeychainError> {
        return .success(())
    }
    
    func retrieve() async -> Result<(username: String, token: String), KeychainError> {
        return .success(("testuser", "testtoken"))
    }
    
    func delete() async -> Result<Void, KeychainError> {
        return .success(())
    }
    
    func getUsername() async -> Result<String, KeychainError> {
        return .success("testuser")
    }
    
    func getGitHubToken() async -> Result<String, KeychainError> {
        return .success("testtoken")
    }
}

private class TestingGitHubValidationService: GitHubValidationServiceProtocol {
    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError> {
        return .success(true)
    }
}

private class TestingGitHubService: GitHubServiceProtocol {
    func validateCredentials() async -> Result<GitHubUser, GitHubServiceError> {
        let user = GitHubUser(
            login: "testuser",
            id: 12345,
            name: "Test User",
            email: "test@example.com",
            company: nil,
            location: nil,
            bio: nil,
            publicRepos: 5,
            privateRepos: 2,
            totalPrivateRepos: 2,
            plan: nil
        )
        return .success(user)
    }
    
    func createPrivateRepository(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError> {
        let repository = GitHubRepository(
            id: 123456,
            name: name,
            fullName: "testuser/\(name)",
            description: description,
            isPrivate: true,
            htmlUrl: "https://github.com/testuser/\(name)",
            cloneUrl: "https://github.com/testuser/\(name).git",
            sshUrl: "git@github.com:testuser/\(name).git",
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            pushedAt: ISO8601DateFormatter().string(from: Date()),
            size: 0,
            language: "Swift",
            owner: GitHubOwner(login: "testuser", id: 12345, type: "User")
        )
        return .success(repository)
    }
    
    func getCurrentUser() async -> Result<GitHubUser, GitHubServiceError> {
        return await validateCredentials()
    }
    
    func repositoryExists(name: String) async -> Result<Bool, GitHubServiceError> {
        return .success(false)
    }
    
    func deleteRepository(name: String) async -> Result<Void, GitHubServiceError> {
        return .success(())
    }
}

private class TestingGitService: GitServiceProtocol {
    func clone(repoURL: URL, to localPath: URL) async -> Result<String, Error> {
        return .success("Repository cloned successfully to \(localPath.path)")
    }
    
    func addRemote(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        return .success("Remote '\(name)' added successfully")
    }
    
    func setRemoteURL(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        return .success("Remote '\(name)' URL updated successfully")
    }
    
    func push(remoteName: String, branch: String, at path: URL, force: Bool) async -> Result<String, Error> {
        return .success("Pushed \(branch) to \(remoteName) successfully")
    }
    
    func status(at path: URL) async -> Result<String, Error> {
        return .success("Working tree clean")
    }
    
    func isValidRepository(at path: URL) async -> Result<Bool, Error> {
        return .success(true)
    }
}
