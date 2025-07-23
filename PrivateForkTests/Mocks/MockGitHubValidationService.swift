import Foundation
@testable import PrivateFork

class MockGitHubValidationService: GitHubValidationServiceProtocol {
    // Result-driven property for the protocol method
    var validateCredentialsResult: Result<Bool, GitHubValidationError> = .success(true)
    
    // Call tracking
    var validateCredentialsCallCount = 0
    var validatedCredentials: [(username: String, token: String)] = []

    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError> {
        validateCredentialsCallCount += 1
        validatedCredentials.append((username: username, token: token))
        return validateCredentialsResult
    }

    // MARK: - Test Helper Methods
    
    func resetMockState() {
        validateCredentialsResult = .success(true)
        validateCredentialsCallCount = 0
        validatedCredentials.removeAll()
    }

    func setValidationResult(isValid: Bool) {
        validateCredentialsResult = .success(isValid)
    }

    func setValidationError(_ error: GitHubValidationError) {
        validateCredentialsResult = .failure(error)
    }

    func getLastValidatedCredentials() -> (username: String, token: String)? {
        return validatedCredentials.last
    }
    
    // MARK: - Legacy Properties (Deprecated - Use result-driven methods instead)
    
    /// @deprecated Use setValidationResult(isValid:) instead
    var shouldReturnValid: Bool {
        get {
            if case .success(let isValid) = validateCredentialsResult {
                return isValid
            }
            return true
        }
        set {
            validateCredentialsResult = .success(newValue)
        }
    }
    
    /// @deprecated Use setValidationError(_:) instead
    var shouldFailWithError: GitHubValidationError? {
        get {
            if case .failure(let error) = validateCredentialsResult {
                return error
            }
            return nil
        }
        set {
            if let error = newValue {
                validateCredentialsResult = .failure(error)
            } else {
                validateCredentialsResult = .success(true)
            }
        }
    }
}
