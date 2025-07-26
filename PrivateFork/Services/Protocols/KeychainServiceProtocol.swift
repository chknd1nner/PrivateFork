import Foundation

protocol KeychainServiceProtocol {
    // OAuth token methods
    func saveOAuthTokens(accessToken: String, refreshToken: String, expiresIn: Date) async -> Result<Void, KeychainError>
    func retrieveOAuthTokens() async -> Result<AuthToken, KeychainError>
    func deleteOAuthTokens() async -> Result<Void, KeychainError>
}

enum KeychainError: Error, LocalizedError, Equatable {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedData
    case unhandledError(status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "No credentials found in Keychain"
        case .duplicateItem:
            return "Credentials already exist in Keychain"
        case .invalidData:
            return "Invalid credential data"
        case .unexpectedData:
            return "Unexpected data format in Keychain"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}
