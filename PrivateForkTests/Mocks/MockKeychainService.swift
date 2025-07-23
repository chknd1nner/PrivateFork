import Foundation
@testable import PrivateFork

class MockKeychainService: KeychainServiceProtocol {
    // Result-driven properties for each protocol method
    var saveResult: Result<Void, KeychainError>?
    var retrieveResult: Result<(username: String, token: String), KeychainError>?
    var deleteResult: Result<Void, KeychainError>?
    var getGitHubTokenResult: Result<String, KeychainError>?
    
    // Call tracking for verification
    var saveCallCount = 0
    var retrieveCallCount = 0
    var deleteCallCount = 0
    var getGitHubTokenCallCount = 0
    
    // Last call parameters for verification
    var lastSaveUsername: String?
    var lastSaveToken: String?
    
    // Legacy stored credentials for helper methods
    private var storedCredentials: (username: String, token: String)?

    func save(username: String, token: String) async -> Result<Void, KeychainError> {
        saveCallCount += 1
        lastSaveUsername = username
        lastSaveToken = token
        
        // If result is explicitly set, use it
        if let result = saveResult {
            // Update stored credentials on success for helper methods
            if case .success = result {
                storedCredentials = (username: username, token: token)
            }
            return result
        }
        
        // Fallback: use stored credentials logic
        storedCredentials = (username: username, token: token)
        return .success(())
    }

    func retrieve() async -> Result<(username: String, token: String), KeychainError> {
        retrieveCallCount += 1
        
        // If result is explicitly set, use it
        if let result = retrieveResult {
            return result
        }
        
        // Fallback: use stored credentials logic
        guard let credentials = storedCredentials else {
            return .failure(.itemNotFound)
        }
        return .success(credentials)
    }

    func delete() async -> Result<Void, KeychainError> {
        deleteCallCount += 1
        
        // If result is explicitly set, use it
        if let result = deleteResult {
            // Clear stored credentials on success for helper methods
            if case .success = result {
                storedCredentials = nil
            }
            return result
        }
        
        // Fallback: use stored credentials logic
        storedCredentials = nil
        return .success(())
    }

    func getGitHubToken() async -> Result<String, KeychainError> {
        getGitHubTokenCallCount += 1
        
        // If result is explicitly set, use it
        if let result = getGitHubTokenResult {
            return result
        }
        
        // Fallback: use stored credentials logic
        guard let credentials = storedCredentials else {
            return .failure(.itemNotFound)
        }
        return .success(credentials.token)
    }

    // MARK: - Test Helper Methods
    
    /// Legacy helper method - sets stored credentials (backward compatibility)
    func setStoredCredentials(username: String, token: String) {
        storedCredentials = (username: username, token: token)
    }

    /// Legacy helper method - clears stored credentials (backward compatibility)
    func clearStoredCredentials() {
        storedCredentials = nil
    }

    /// Legacy helper method - checks if credentials exist (backward compatibility)
    func hasStoredCredentials() -> Bool {
        return storedCredentials != nil
    }
    
    /// Reset all mock state
    func resetMockState() {
        saveResult = nil
        retrieveResult = nil
        deleteResult = nil
        getGitHubTokenResult = nil
        
        saveCallCount = 0
        retrieveCallCount = 0
        deleteCallCount = 0
        getGitHubTokenCallCount = 0
        
        lastSaveUsername = nil
        lastSaveToken = nil
        storedCredentials = nil
    }
    
    // MARK: - Result-Driven Configuration Methods
    
    /// Configure save to fail with specific error
    func setSaveFailure(_ error: KeychainError) {
        saveResult = .failure(error)
    }
    
    /// Configure retrieve to fail with specific error
    func setRetrieveFailure(_ error: KeychainError) {
        retrieveResult = .failure(error)
    }
    
    /// Configure delete to fail with specific error
    func setDeleteFailure(_ error: KeychainError) {
        deleteResult = .failure(error)
    }
    
    /// Configure getGitHubToken to fail with specific error
    func setGetGitHubTokenFailure(_ error: KeychainError) {
        getGitHubTokenResult = .failure(error)
    }
    
    // MARK: - Legacy Flag Properties (Deprecated - Use result-driven methods instead)
    
    /// @deprecated Use setSaveFailure(_ error:) instead
    var shouldFailSave: Bool {
        get { 
            if case .failure = saveResult { return true }
            return false
        }
        set { 
            if newValue {
                saveResult = .failure(.unhandledError(status: -1))
            } else {
                saveResult = nil
            }
        }
    }
    
    /// @deprecated Use setRetrieveFailure(_ error:) instead  
    var shouldFailRetrieve: Bool {
        get { 
            if case .failure = retrieveResult { return true }
            return false
        }
        set { 
            if newValue {
                retrieveResult = .failure(.itemNotFound)
                getGitHubTokenResult = .failure(.itemNotFound)
            } else {
                retrieveResult = nil
                getGitHubTokenResult = nil
            }
        }
    }
    
    /// @deprecated Use setDeleteFailure(_ error:) instead
    var shouldFailDelete: Bool {
        get { 
            if case .failure = deleteResult { return true }
            return false
        }
        set { 
            if newValue {
                deleteResult = .failure(.unhandledError(status: -1))
            } else {
                deleteResult = nil
            }
        }
    }
}
