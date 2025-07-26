import Foundation
import Security

class KeychainService: KeychainServiceProtocol {
    private let service = "com.example.PrivateFork.oauth"
    private let accessTokenKey = "oauth_access_token"
    private let refreshTokenKey = "oauth_refresh_token"
    private let expiresInKey = "oauth_expires_in"

    func saveOAuthTokens(accessToken: String, refreshToken: String, expiresIn: Date) async -> Result<Void, KeychainError> {
        // First delete any existing OAuth tokens
        _ = await deleteOAuthTokens()

        // Save access token
        let accessTokenResult = await saveItem(key: accessTokenKey, value: accessToken.data(using: .utf8)!)
        if case .failure(let error) = accessTokenResult {
            return .failure(error)
        }

        // Save refresh token
        let refreshTokenResult = await saveItem(key: refreshTokenKey, value: refreshToken.data(using: .utf8)!)
        if case .failure(let error) = refreshTokenResult {
            // Clean up access token if refresh token save fails
            _ = await deleteItem(key: accessTokenKey)
            return .failure(error)
        }

        // Save expiration date
        let expiresInData = try! JSONEncoder().encode(expiresIn)
        let expiresInResult = await saveItem(key: expiresInKey, value: expiresInData)
        if case .failure(let error) = expiresInResult {
            // Clean up previous tokens if expiration save fails
            _ = await deleteItem(key: accessTokenKey)
            _ = await deleteItem(key: refreshTokenKey)
            return .failure(error)
        }

        return .success(())
    }

    func retrieveOAuthTokens() async -> Result<AuthToken, KeychainError> {
        let accessTokenResult = await retrieveItem(key: accessTokenKey)
        let refreshTokenResult = await retrieveItem(key: refreshTokenKey)
        let expiresInResult = await retrieveItem(key: expiresInKey)

        switch (accessTokenResult, refreshTokenResult, expiresInResult) {
        case (.success(let accessTokenData), .success(let refreshTokenData), .success(let expiresInData)):
            guard let accessToken = String(data: accessTokenData, encoding: .utf8),
                  let refreshToken = String(data: refreshTokenData, encoding: .utf8),
                  let expiresIn = try? JSONDecoder().decode(Date.self, from: expiresInData) else {
                return .failure(.unexpectedData)
            }
            let authToken = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
            return .success(authToken)
        case (.failure(let error), _, _), (_, .failure(let error), _), (_, _, .failure(let error)):
            return .failure(error)
        }
    }

    func deleteOAuthTokens() async -> Result<Void, KeychainError> {
        let accessTokenResult = await deleteItem(key: accessTokenKey)
        let refreshTokenResult = await deleteItem(key: refreshTokenKey)
        let expiresInResult = await deleteItem(key: expiresInKey)

        // Return success if at least one deletion succeeded or if items didn't exist
        switch (accessTokenResult, refreshTokenResult, expiresInResult) {
        case (.success, .success, .success),
             (.success, .success, .failure(.itemNotFound)),
             (.success, .failure(.itemNotFound), .success),
             (.failure(.itemNotFound), .success, .success),
             (.success, .failure(.itemNotFound), .failure(.itemNotFound)),
             (.failure(.itemNotFound), .success, .failure(.itemNotFound)),
             (.failure(.itemNotFound), .failure(.itemNotFound), .success):
            return .success(())
        case (.failure(.itemNotFound), .failure(.itemNotFound), .failure(.itemNotFound)):
            return .success(()) // No items to delete
        case (.failure(let error), _, _), (_, .failure(let error), _), (_, _, .failure(let error)):
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
