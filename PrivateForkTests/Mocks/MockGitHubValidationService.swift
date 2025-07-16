import Foundation
@testable import PrivateFork

class MockGitHubValidationService: GitHubValidationServiceProtocol {
    var shouldReturnValid = true
    var shouldFailWithError: GitHubValidationError?
    var validatedCredentials: [(username: String, token: String)] = []

    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError> {
        validatedCredentials.append((username: username, token: token))

        if let error = shouldFailWithError {
            return .failure(error)
        }

        return .success(shouldReturnValid)
    }

    // Test helper methods
    func reset() {
        shouldReturnValid = true
        shouldFailWithError = nil
        validatedCredentials.removeAll()
    }

    func setValidationResult(isValid: Bool) {
        shouldReturnValid = isValid
        shouldFailWithError = nil
    }

    func setValidationError(_ error: GitHubValidationError) {
        shouldFailWithError = error
    }

    func getLastValidatedCredentials() -> (username: String, token: String)? {
        return validatedCredentials.last
    }
}
