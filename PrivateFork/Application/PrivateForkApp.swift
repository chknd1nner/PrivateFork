import SwiftUI

struct PrivateForkApp: App {
    private let mainViewModel: MainViewModel
    
    init() {
        // 1. Create the correct services based on the environment
        let keychainService = Self.createKeychainService()
        let gitHubValidationService = Self.createGitHubValidationService()
        
        // 2. Create view models, injecting the services
        self.mainViewModel = MainViewModel(keychainService: keychainService)
    }
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: mainViewModel, 
                    keychainService: Self.createKeychainService(),
                    gitHubValidationService: Self.createGitHubValidationService())
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
