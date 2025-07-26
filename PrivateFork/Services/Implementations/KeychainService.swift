import Foundation
import Security

actor KeychainService: KeychainServiceProtocol {
    
    // MARK: - Constants
    
    private enum KeychainConstants {
        static let service = "com.example.PrivateFork.oauth"
        static let tokenKey = "oauth_tokens"
        
        enum Legacy {
            static let service = "com.example.PrivateFork.github"
            static let usernameKey = "username"
            static let tokenKey = "token"
        }
    }
    
    private let service = KeychainConstants.service
    private let tokenKey = KeychainConstants.tokenKey

    func saveOAuthTokens(accessToken: String, refreshToken: String, expiresIn: Date) async -> Result<Void, KeychainError> {
        // Create AuthToken struct and encode as single atomic data
        let authToken = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
        
        do {
            let tokenData = try JSONEncoder().encode(authToken)
            return await saveItem(key: tokenKey, value: tokenData)
        } catch {
            return .failure(.invalidData)
        }
    }

    func retrieveOAuthTokens() async -> Result<AuthToken, KeychainError> {
        let result = await retrieveItem(key: tokenKey)
        
        switch result {
        case .success(let tokenData):
            do {
                let authToken = try JSONDecoder().decode(AuthToken.self, from: tokenData)
                return .success(authToken)
            } catch {
                return .failure(.unexpectedData)
            }
        case .failure(.itemNotFound):
            // Hygienic cleanup: Remove any legacy PAT credentials on first run
            await cleanupLegacyPATCredentials()
            return .failure(.itemNotFound)
        case .failure(let error):
            return .failure(error)
        }
    }

    func deleteOAuthTokens() async -> Result<Void, KeychainError> {
        let result = await deleteItem(key: tokenKey)
        
        switch result {
        case .success:
            return .success(())
        case .failure(.itemNotFound):
            return .success(()) // No item to delete is considered success
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Helper Methods

    private func saveItem(key: String, value: Data) async -> Result<Void, KeychainError> {
        // First try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: value
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return .success(())
        }
        
        // If update failed because item doesn't exist, add new item
        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecValueData as String: value,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            
            switch addStatus {
            case errSecSuccess:
                return .success(())
            default:
                return .failure(.unhandledError(status: addStatus))
            }
        }
        
        return .failure(.unhandledError(status: updateStatus))
    }

    private func retrieveItem(key: String) async -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                return .failure(.unexpectedData)
            }
            return .success(data)
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unhandledError(status: status))
        }
    }

    private func deleteItem(key: String) async -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess:
            return .success(())
        case errSecItemNotFound:
            return .failure(.itemNotFound)
        default:
            return .failure(.unhandledError(status: status))
        }
    }
    
    // MARK: - Legacy Cleanup
    
    /// Performs one-time cleanup of legacy PAT credentials
    /// This is a fire-and-forget operation for security hygiene
    private func cleanupLegacyPATCredentials() async {
        let legacyKeys = [KeychainConstants.Legacy.usernameKey, KeychainConstants.Legacy.tokenKey]
        
        for key in legacyKeys {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: KeychainConstants.Legacy.service,
                kSecAttrAccount as String: key
            ]
            
            // Fire-and-forget deletion - we don't care about the result
            _ = SecItemDelete(query as CFDictionary)
        }
    }
}
