import Foundation
@testable import PrivateFork

class MockPrivateForkOrchestrator: PrivateForkOrchestratorProtocol {
    // Result-driven property for the protocol method
    var createPrivateForkResult: Result<String, PrivateForkError>!
    
    // Status callback tracking for verification
    private var statusCallbacks: [String] = []
    
    // Call tracking for verification
    var createPrivateForkCallCount = 0
    var lastRepositoryURL: String?
    var lastLocalPath: String?
    
    // MARK: - Test Configuration Methods
    
    func setSuccessResult(message: String = "Private fork created successfully!") {
        createPrivateForkResult = .success(message)
    }
    
    func setFailureResult(error: PrivateForkError) {
        createPrivateForkResult = .failure(error)
    }
    
    func getStatusCallbacks() -> [String] {
        return statusCallbacks
    }
    
    func resetMockState() {
        createPrivateForkResult = nil
        createPrivateForkCallCount = 0
        lastRepositoryURL = nil
        lastLocalPath = nil
        statusCallbacks.removeAll()
    }
    
    func setupSuccessResult() {
        createPrivateForkResult = .success("Private fork created successfully!")
    }
    
    // MARK: - PrivateForkOrchestratorProtocol Implementation
    
    func createPrivateFork(
        repositoryURL: String,
        localPath: String,
        statusCallback: @escaping (String) -> Void
    ) async -> Result<String, PrivateForkError> {
        
        createPrivateForkCallCount += 1
        lastRepositoryURL = repositoryURL
        lastLocalPath = localPath
        
        // Simulate workflow status updates
        let statusUpdates = [
            "Validating GitHub credentials...",
            "Creating private repository...",
            "Cloning original repository...", 
            "Configuring remotes...",
            "Pushing to private repository..."
        ]
        
        for status in statusUpdates {
            statusCallbacks.append(status)
            statusCallback(status)
            
            // Small delay to simulate real work
            try? await Task.sleep(for: .milliseconds(10))
        }
        
        // Return the pre-configured result
        switch createPrivateForkResult! {
        case .success(let message):
            statusCallbacks.append(message)
            statusCallback(message)
            return .success(message)
        case .failure(let error):
            let errorMessage = "Error: \(error.localizedDescription)"
            statusCallbacks.append(errorMessage)
            statusCallback(errorMessage)
            return .failure(error)
        }
    }
}

// MARK: - Test Helper Extensions

extension MockPrivateForkOrchestrator {
    
    /// Convenience method to simulate credential validation failure
    func simulateCredentialValidationFailure() {
        createPrivateForkResult = .failure(.credentialValidationFailed(.itemNotFound))
    }
    
    /// Convenience method to simulate repository creation failure
    func simulateRepositoryCreationFailure() {
        createPrivateForkResult = .failure(.repositoryCreationFailed(.repositoryNameConflict("test-repo")))
    }
    
    /// Convenience method to simulate git operation failure
    func simulateGitOperationFailure() {
        createPrivateForkResult = .failure(.gitOperationFailed(GitServiceError.authenticationFailed))
    }
    
    /// Convenience method to simulate invalid repository URL
    func simulateInvalidRepositoryURL() {
        createPrivateForkResult = .failure(.invalidRepositoryURL)
    }
    
    /// Convenience method to simulate invalid local path
    func simulateInvalidLocalPath() {
        createPrivateForkResult = .failure(.invalidLocalPath)
    }
}