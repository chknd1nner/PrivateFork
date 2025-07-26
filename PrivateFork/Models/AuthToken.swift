import Foundation

/// Represents OAuth authentication tokens for GitHub API access
struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Date
    
    /// Initializes an AuthToken with the provided credentials
    /// - Parameters:
    ///   - accessToken: The OAuth access token for GitHub API authentication
    ///   - refreshToken: The OAuth refresh token for token renewal
    ///   - expiresIn: The expiration date of the access token
    init(accessToken: String, refreshToken: String, expiresIn: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
}

// MARK: - Security Measures
extension AuthToken: CustomStringConvertible, CustomDebugStringConvertible {
    /// Prevents token exposure in logs by redacting sensitive data
    var description: String {
        return "AuthToken(accessToken: [REDACTED], refreshToken: [REDACTED], expiresIn: \(expiresIn))"
    }
    
    /// Prevents token exposure in debug logs by redacting sensitive data
    var debugDescription: String {
        return description
    }
}