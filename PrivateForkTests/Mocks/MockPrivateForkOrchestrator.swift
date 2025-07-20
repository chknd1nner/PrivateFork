import Foundation
@testable import PrivateFork

class MockPrivateForkOrchestrator: PrivateForkOrchestratorProtocol {
    // Mock state
    private var successMessage: String = "Private fork created successfully!"
    private var shouldFail = false
    private var errorToReturn: PrivateForkError?
    private var statusCallbacks: [String] = []
    
    // Call tracking
    var createPrivateForkCallCount = 0
    var lastRepositoryURL: String?
    var lastLocalPath: String?
    
    // MARK: - Test Configuration Methods
    
    func setSuccessResult(message: String = "Private fork created successfully!") {
        shouldFail = false
        successMessage = message
        errorToReturn = nil
    }
    
    func setFailureResult(error: PrivateForkError) {
        shouldFail = true
        errorToReturn = error
    }
    
    func getStatusCallbacks() -> [String] {
        return statusCallbacks
    }
    
    func reset() {
        createPrivateForkCallCount = 0
        lastRepositoryURL = nil
        lastLocalPath = nil
        statusCallbacks.removeAll()
        shouldFail = false
        errorToReturn = nil
        successMessage = "Private fork created successfully!"
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
        
        if shouldFail {
            let error = errorToReturn ?? .workflowInterrupted("Mock failure")
            statusCallbacks.append("Error: \(error.localizedDescription)")
            statusCallback("Error: \(error.localizedDescription)")
            return .failure(error)
        }
        
        statusCallbacks.append(successMessage)
        statusCallback(successMessage)
        return .success(successMessage)
    }
}

// MARK: - Test Helper Extensions

extension MockPrivateForkOrchestrator {
    
    /// Convenience method to simulate credential validation failure
    func simulateCredentialValidationFailure() {
        setFailureResult(error: .credentialValidationFailed(.itemNotFound))
    }
    
    /// Convenience method to simulate repository creation failure
    func simulateRepositoryCreationFailure() {
        setFailureResult(error: .repositoryCreationFailed(.repositoryNameConflict("test-repo")))
    }
    
    /// Convenience method to simulate git operation failure
    func simulateGitOperationFailure() {
        setFailureResult(error: .gitOperationFailed(GitServiceError.authenticationFailed))
    }
    
    /// Convenience method to simulate invalid repository URL
    func simulateInvalidRepositoryURL() {
        setFailureResult(error: .invalidRepositoryURL)
    }
    
    /// Convenience method to simulate invalid local path
    func simulateInvalidLocalPath() {
        setFailureResult(error: .invalidLocalPath)
    }
}