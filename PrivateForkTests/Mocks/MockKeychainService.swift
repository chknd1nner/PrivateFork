import Foundation
@testable import PrivateFork

class MockKeychainService: KeychainServiceProtocol {
    private var storedCredentials: (username: String, token: String)?
    var shouldFailSave = false
    var shouldFailRetrieve = false
    var shouldFailDelete = false

    func save(username: String, token: String) async -> Result<Void, KeychainError> {
        if shouldFailSave {
            return .failure(.unhandledError(status: -1))
        }
        storedCredentials = (username: username, token: token)
        return .success(())
    }

    func retrieve() async -> Result<(username: String, token: String), KeychainError> {
        if shouldFailRetrieve {
            return .failure(.itemNotFound)
        }

        guard let credentials = storedCredentials else {
            return .failure(.itemNotFound)
        }

        return .success(credentials)
    }

    func delete() async -> Result<Void, KeychainError> {
        if shouldFailDelete {
            return .failure(.unhandledError(status: -1))
        }
        storedCredentials = nil
        return .success(())
    }
    
    func getGitHubToken() async -> Result<String, KeychainError> {
        if shouldFailRetrieve {
            return .failure(.itemNotFound)
        }
        
        guard let credentials = storedCredentials else {
            return .failure(.itemNotFound)
        }
        
        return .success(credentials.token)
    }

    // Test helper methods
    func setStoredCredentials(username: String, token: String) {
        storedCredentials = (username: username, token: token)
    }

    func clearStoredCredentials() {
        storedCredentials = nil
    }

    func hasStoredCredentials() -> Bool {
        return storedCredentials != nil
    }
}
