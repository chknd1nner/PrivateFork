import Foundation

protocol KeychainServiceProtocol {
    func save(username: String, token: String) async -> Result<Void, KeychainError>
    func retrieve() async -> Result<(username: String, token: String), KeychainError>
    func delete() async -> Result<Void, KeychainError>
    func getGitHubToken() async -> Result<String, KeychainError>
}

enum KeychainError: Error, LocalizedError {
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
