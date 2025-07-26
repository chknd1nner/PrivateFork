import Foundation
@testable import PrivateFork

class MockKeychainService: KeychainServiceProtocol {
    // Result-driven properties for OAuth methods
    var saveOAuthTokensResult: Result<Void, KeychainError>?
    var retrieveOAuthTokensResult: Result<AuthToken, KeychainError>?
    var deleteOAuthTokensResult: Result<Void, KeychainError>?
    
    // Call tracking for verification
    var saveOAuthTokensCallCount = 0
    var retrieveOAuthTokensCallCount = 0
    var deleteOAuthTokensCallCount = 0
    
    // Last call parameters for verification
    var lastSaveAccessToken: String?
    var lastSaveRefreshToken: String?
    var lastSaveExpiresIn: Date?
    
    // Stored OAuth tokens for helper methods
    private var storedOAuthTokens: AuthToken?

    func saveOAuthTokens(accessToken: String, refreshToken: String, expiresIn: Date) async -> Result<Void, KeychainError> {
        saveOAuthTokensCallCount += 1
        lastSaveAccessToken = accessToken
        lastSaveRefreshToken = refreshToken
        lastSaveExpiresIn = expiresIn
        
        // If result is explicitly set, use it
        if let result = saveOAuthTokensResult {
            // Update stored tokens on success for helper methods
            if case .success = result {
                storedOAuthTokens = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
            }
            return result
        }
        
        // Fallback: use stored tokens logic
        storedOAuthTokens = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
        return .success(())
    }

    func retrieveOAuthTokens() async -> Result<AuthToken, KeychainError> {
        retrieveOAuthTokensCallCount += 1
        
        // If result is explicitly set, use it
        if let result = retrieveOAuthTokensResult {
            return result
        }
        
        // Fallback: use stored tokens logic
        guard let tokens = storedOAuthTokens else {
            return .failure(.itemNotFound)
        }
        return .success(tokens)
    }

    func deleteOAuthTokens() async -> Result<Void, KeychainError> {
        deleteOAuthTokensCallCount += 1
        
        // If result is explicitly set, use it
        if let result = deleteOAuthTokensResult {
            // Clear stored tokens on success for helper methods
            if case .success = result {
                storedOAuthTokens = nil
            }
            return result
        }
        
        // Fallback: use stored tokens logic
        storedOAuthTokens = nil
        return .success(())
    }

    // MARK: - Test Helper Methods
    
    /// Sets stored OAuth tokens directly (for test setup)
    func setStoredOAuthTokens(accessToken: String, refreshToken: String, expiresIn: Date) {
        storedOAuthTokens = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
    }

    /// Sets stored OAuth tokens with AuthToken object (for test setup)
    func setStoredOAuthTokens(_ authToken: AuthToken) {
        storedOAuthTokens = authToken
    }

    /// Clears stored OAuth tokens
    func clearStoredOAuthTokens() {
        storedOAuthTokens = nil
    }

    /// Checks if OAuth tokens exist
    func hasStoredOAuthTokens() -> Bool {
        return storedOAuthTokens != nil
    }
    
    /// Reset all mock state for OAuth methods
    func resetMockState() {
        saveOAuthTokensResult = nil
        retrieveOAuthTokensResult = nil
        deleteOAuthTokensResult = nil
        
        saveOAuthTokensCallCount = 0
        retrieveOAuthTokensCallCount = 0
        deleteOAuthTokensCallCount = 0
        
        lastSaveAccessToken = nil
        lastSaveRefreshToken = nil
        lastSaveExpiresIn = nil
        storedOAuthTokens = nil
    }
    
    // MARK: - Result-Driven Configuration Methods
    
    /// Configure saveOAuthTokens to fail with specific error
    func setSaveOAuthTokensFailure(_ error: KeychainError) {
        saveOAuthTokensResult = .failure(error)
    }
    
    /// Configure retrieveOAuthTokens to fail with specific error
    func setRetrieveOAuthTokensFailure(_ error: KeychainError) {
        retrieveOAuthTokensResult = .failure(error)
    }
    
    /// Configure deleteOAuthTokens to fail with specific error
    func setDeleteOAuthTokensFailure(_ error: KeychainError) {
        deleteOAuthTokensResult = .failure(error)
    }
}
