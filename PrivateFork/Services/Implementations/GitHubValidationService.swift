import Foundation

class GitHubValidationService: GitHubValidationServiceProtocol {
    private let baseURL = "https://api.github.com"

    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError> {
        // Basic format validation
        guard !username.isEmpty, isValidUsername(username) else {
            return .failure(.invalidUsername)
        }

        guard !token.isEmpty, isValidTokenFormat(token) else {
            return .failure(.invalidToken)
        }

        // Validate against GitHub API
        return await validateWithGitHubAPI(username: username, token: token)
    }

    // MARK: - Private Helper Methods

    private func isValidUsername(_ username: String) -> Bool {
        // GitHub username rules: 1-39 characters, alphanumeric and hyphens, can't start/end with hyphen
        let pattern = "^[a-zA-Z0-9]([a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: username.utf16.count)
        return regex?.firstMatch(in: username, options: [], range: range) != nil
    }

    private func isValidTokenFormat(_ token: String) -> Bool {
        // GitHub Personal Access Tokens are typically 40 characters (classic) or start with ghp_ (fine-grained)
        if token.count == 40 && token.allSatisfy({ $0.isHexDigit }) {
            return true // Classic token
        }

        if token.hasPrefix("ghp_") && token.count > 4 {
            return true // Fine-grained personal access token
        }

        if token.hasPrefix("github_pat_") {
            return true // New fine-grained token format
        }

        return false
    }

    private func validateWithGitHubAPI(username: String, token: String) async -> Result<Bool, GitHubValidationError> {
        guard let url = URL(string: "\(baseURL)/user") else {
            return .failure(.networkError)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("PrivateFork/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError)
            }

            switch httpResponse.statusCode {
            case 200:
                // Parse response to verify username matches
                return await verifyUsernameFromResponse(data: data, expectedUsername: username)
            case 401:
                return .failure(.authenticationFailed)
            case 403:
                // Check if it's rate limiting
                if let rateLimitRemaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
                   rateLimitRemaining == "0" {
                    return .failure(.rateLimitExceeded)
                }
                return .failure(.authenticationFailed)
            case 500...599:
                return .failure(.serverError)
            default:
                return .failure(.networkError)
            }
        } catch {
            return .failure(.networkError)
        }
    }

    private func verifyUsernameFromResponse(
        data: Data,
        expectedUsername: String
    ) async -> Result<Bool, GitHubValidationError> {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let login = json["login"] as? String else {
                return .failure(.serverError)
            }

            // Case-insensitive username comparison
            let isValid = login.lowercased() == expectedUsername.lowercased()
            return .success(isValid)
        } catch {
            return .failure(.serverError)
        }
    }
}

extension Character {
    var isHexDigit: Bool {
        return isNumber || (lowercased().first! >= "a" && lowercased().first! <= "f")
    }
}
