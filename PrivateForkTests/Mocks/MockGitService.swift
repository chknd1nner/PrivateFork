import Foundation
@testable import PrivateFork

class MockGitService: GitServiceProtocol {
    
    // MARK: - Mock Configuration Properties
    var cloneResult: Result<String, Error> = .success("Repository cloned successfully")
    var addRemoteResult: Result<String, Error> = .success("Remote added successfully")
    var setRemoteURLResult: Result<String, Error> = .success("Remote URL updated successfully")
    var pushResult: Result<String, Error> = .success("Push completed successfully")
    var statusResult: Result<String, Error> = .success("Working tree clean")
    var isValidRepositoryResult: Result<Bool, Error> = .success(true)
    
    // MARK: - Call Tracking
    var cloneCallCount = 0
    var addRemoteCallCount = 0
    var setRemoteURLCallCount = 0
    var pushCallCount = 0
    var statusCallCount = 0
    var isValidRepositoryCallCount = 0
    
    // MARK: - Last Call Parameters
    var lastCloneRepoURL: URL?
    var lastCloneLocalPath: URL?
    var lastAddRemoteName: String?
    var lastAddRemoteURL: URL?
    var lastAddRemotePath: URL?
    var lastSetRemoteName: String?
    var lastSetRemoteURL: URL?
    var lastSetRemotePath: URL?
    var lastPushRemoteName: String?
    var lastPushBranch: String?
    var lastPushPath: URL?
    var lastPushForce: Bool?
    var lastStatusPath: URL?
    var lastValidationPath: URL?
    
    // MARK: - GitServiceProtocol Implementation
    
    func clone(repoURL: URL, to localPath: URL) async -> Result<String, Error> {
        cloneCallCount += 1
        lastCloneRepoURL = repoURL
        lastCloneLocalPath = localPath
        return cloneResult
    }
    
    func addRemote(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        addRemoteCallCount += 1
        lastAddRemoteName = name
        lastAddRemoteURL = url
        lastAddRemotePath = path
        return addRemoteResult
    }
    
    func setRemoteURL(name: String, url: URL, at path: URL) async -> Result<String, Error> {
        setRemoteURLCallCount += 1
        lastSetRemoteName = name
        lastSetRemoteURL = url
        lastSetRemotePath = path
        return setRemoteURLResult
    }
    
    func push(remoteName: String, branch: String, at path: URL, force: Bool) async -> Result<String, Error> {
        pushCallCount += 1
        lastPushRemoteName = remoteName
        lastPushBranch = branch
        lastPushPath = path
        lastPushForce = force
        return pushResult
    }
    
    func status(at path: URL) async -> Result<String, Error> {
        statusCallCount += 1
        lastStatusPath = path
        return statusResult
    }
    
    func isValidRepository(at path: URL) async -> Result<Bool, Error> {
        isValidRepositoryCallCount += 1
        lastValidationPath = path
        return isValidRepositoryResult
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        // Reset results to defaults
        cloneResult = .success("Repository cloned successfully")
        addRemoteResult = .success("Remote added successfully")
        setRemoteURLResult = .success("Remote URL updated successfully")
        pushResult = .success("Push completed successfully")
        statusResult = .success("Working tree clean")
        isValidRepositoryResult = .success(true)
        
        // Reset call counts
        cloneCallCount = 0
        addRemoteCallCount = 0
        setRemoteURLCallCount = 0
        pushCallCount = 0
        statusCallCount = 0
        isValidRepositoryCallCount = 0
        
        // Reset last call parameters
        lastCloneRepoURL = nil
        lastCloneLocalPath = nil
        lastAddRemoteName = nil
        lastAddRemoteURL = nil
        lastAddRemotePath = nil
        lastSetRemoteName = nil
        lastSetRemoteURL = nil
        lastSetRemotePath = nil
        lastPushRemoteName = nil
        lastPushBranch = nil
        lastPushPath = nil
        lastPushForce = nil
        lastStatusPath = nil
        lastValidationPath = nil
    }
    
    // MARK: - Result Configuration Helpers
    
    func setCloneFailure(_ error: Error) {
        cloneResult = .failure(error)
    }
    
    func setAddRemoteFailure(_ error: Error) {
        addRemoteResult = .failure(error)
    }
    
    func setPushFailure(_ error: Error) {
        pushResult = .failure(error)
    }
    
    func setRepositoryInvalid() {
        isValidRepositoryResult = .success(false)
    }
    
    func setValidationFailure(_ error: Error) {
        isValidRepositoryResult = .failure(error)
    }
}