import Foundation
import Security

class KeychainService: KeychainServiceProtocol {
    private let service = "com.example.PrivateFork.github"
    private let usernameKey = "username"
    private let tokenKey = "token"

    func save(username: String, token: String) async -> Result<Void, KeychainError> {
        // First delete any existing items
        _ = await delete()

        // Save username
        let usernameResult = await saveItem(key: usernameKey, value: username.data(using: .utf8)!)
        if case .failure(let error) = usernameResult {
            return .failure(error)
        }

        // Save token
        let tokenResult = await saveItem(key: tokenKey, value: token.data(using: .utf8)!)
        if case .failure(let error) = tokenResult {
            // Clean up username if token save fails
            _ = await deleteItem(key: usernameKey)
            return .failure(error)
        }

        return .success(())
    }

    func retrieve() async -> Result<(username: String, token: String), KeychainError> {
        let usernameResult = await retrieveItem(key: usernameKey)
        let tokenResult = await retrieveItem(key: tokenKey)

        switch (usernameResult, tokenResult) {
        case (.success(let usernameData), .success(let tokenData)):
            guard let username = String(data: usernameData, encoding: .utf8),
                  let token = String(data: tokenData, encoding: .utf8) else {
                return .failure(.unexpectedData)
            }
            return .success((username: username, token: token))
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }

    func delete() async -> Result<Void, KeychainError> {
        let usernameResult = await deleteItem(key: usernameKey)
        let tokenResult = await deleteItem(key: tokenKey)

        // Return success if at least one deletion succeeded or if items didn't exist
        switch (usernameResult, tokenResult) {
        case (.success, .success), (.success, .failure(.itemNotFound)), (.failure(.itemNotFound), .success):
            return .success(())
        case (.failure(.itemNotFound), .failure(.itemNotFound)):
            return .success(()) // No items to delete
        case (.failure(let error), _), (_, .failure(let error)):
            return .failure(error)
        }
    }
    
    func getGitHubToken() async -> Result<String, KeychainError> {
        let tokenResult = await retrieveItem(key: tokenKey)
        
        switch tokenResult {
        case .success(let tokenData):
            guard let token = String(data: tokenData, encoding: .utf8) else {
                return .failure(.unexpectedData)
            }
            return .success(token)
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Helper Methods

    private func saveItem(key: String, value: Data) async -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return .success(())
        case errSecDuplicateItem:
            return .failure(.duplicateItem)
        default:
            return .failure(.unhandledError(status: status))
        }
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
}
