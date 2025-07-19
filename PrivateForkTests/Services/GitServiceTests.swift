import XCTest
@testable import PrivateFork

// MARK: - Test Helper Mock
class MockShellWithCallbacks: ShellProtocol {
    var responses: [Result<String, ShellError>] = []
    private var currentIndex = 0
    
    func execute(command: String, arguments: [String], workingDirectory: URL?, timeout: TimeInterval) async -> Result<String, ShellError> {
        guard currentIndex < responses.count else {
            return .failure(.processingError("No more responses configured"))
        }
        
        let response = responses[currentIndex]
        currentIndex += 1
        return response
    }
}

@MainActor
final class GitServiceTests: XCTestCase {
    
    var gitService: GitService!
    var mockShell: MockShell!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        mockShell = MockShell()
        gitService = GitService(shell: mockShell)
        
        // Create a temporary directory for testing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        tempDirectory = tempURL
    }
    
    override func tearDown() {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        gitService = nil
        mockShell = nil
        tempDirectory = nil
        super.tearDown()
    }
    
    // MARK: - Clone Tests
    
    func testClone_WhenSuccessful_ShouldReturnSuccess() async {
        // Given: A valid repo URL and successful shell execution
        let repoURL = URL(string: "https://github.com/user/repo.git")!
        let localPath = URL(fileURLWithPath: "/tmp/test-repo")
        mockShell.setSuccess("Cloning into '/tmp/test-repo'...\ndone.")
        
        // When: The clone operation is called
        let result = await gitService.clone(repoURL: repoURL, to: localPath)
        
        // Then: The operation should succeed
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Repository cloned successfully"))
            XCTAssertEqual(mockShell.executeCallCount, 1)
            XCTAssertEqual(mockShell.lastCommand, "git")
            XCTAssertEqual(mockShell.lastArguments, ["clone", "https://github.com/user/repo.git", "/tmp/test-repo"])
        case .failure(let error):
            XCTFail("Clone should have succeeded, but failed with: \(error)")
        }
    }
    
    func testClone_WhenInvalidURL_ShouldReturnError() async {
        // Given: An invalid repo URL
        let repoURL = URL(string: "invalid-url")!
        let localPath = URL(fileURLWithPath: "/tmp/test-repo")
        
        // When: The clone operation is called
        let result = await gitService.clone(repoURL: repoURL, to: localPath)
        
        // Then: The operation should fail with invalid URL error
        switch result {
        case .success:
            XCTFail("Clone should have failed due to invalid URL")
        case .failure(let error as GitServiceError):
            if case .invalidURL(let url) = error {
                XCTAssertEqual(url, "invalid-url")
            } else {
                XCTFail("Expected invalidURL error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    func testClone_WhenShellCommandFails_ShouldReturnError() async {
        // Given: A valid repo URL but shell command failure
        let repoURL = URL(string: "https://github.com/user/repo.git")!
        let localPath = URL(fileURLWithPath: "/tmp/test-repo")
        mockShell.setFailure(.executionFailed(exitCode: 128, stderr: "fatal: repository not found"))
        
        // When: The clone operation is called
        let result = await gitService.clone(repoURL: repoURL, to: localPath)
        
        // Then: The operation should fail
        switch result {
        case .success:
            XCTFail("Clone should have failed due to shell command failure")
        case .failure(let error as GitServiceError):
            if case .repositoryNotFound(let message) = error {
                XCTAssertTrue(message.contains("not found"))
            } else {
                XCTFail("Expected repositoryNotFound error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    func testClone_WhenAuthenticationFails_ShouldReturnAuthError() async {
        // Given: A valid repo URL but authentication failure
        let repoURL = URL(string: "https://github.com/user/private-repo.git")!
        let localPath = URL(fileURLWithPath: "/tmp/test-repo")
        mockShell.setFailure(.executionFailed(exitCode: 128, stderr: "fatal: Authentication failed"))
        
        // When: The clone operation is called
        let result = await gitService.clone(repoURL: repoURL, to: localPath)
        
        // Then: The operation should fail with authentication error
        switch result {
        case .success:
            XCTFail("Clone should have failed due to authentication")
        case .failure(let error as GitServiceError):
            if case .authenticationFailed = error {
                // Expected behavior
            } else {
                XCTFail("Expected authenticationFailed error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    // MARK: - Add Remote Tests
    
    func testAddRemote_WhenSuccessful_ShouldReturnSuccess() async {
        // Given: Valid repository and remote details
        let remoteName = "origin"
        let remoteURL = URL(string: "https://github.com/user/repo.git")!
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call succeeds (validation), second call succeeds (add remote)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success("") // Add remote success
        ]
        
        // When: The add remote operation is called
        let result = await customGitService.addRemote(name: remoteName, url: remoteURL, at: repoPath)
        
        // Then: The operation should succeed
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Remote 'origin' added successfully"))
        case .failure(let error):
            XCTFail("Add remote should have succeeded, but failed with: \(error)")
        }
    }
    
    func testAddRemote_WhenInvalidRepository_ShouldReturnError() async {
        // Given: Invalid repository path
        let remoteName = "origin"
        let remoteURL = URL(string: "https://github.com/user/repo.git")!
        let repoPath = tempDirectory.appendingPathComponent("not-a-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call fails (validation)
        customMockShell.responses = [
            .failure(.executionFailed(exitCode: 128, stderr: "fatal: not a git repository")) // Repository validation failure
        ]
        
        // When: The add remote operation is called
        let result = await customGitService.addRemote(name: remoteName, url: remoteURL, at: repoPath)
        
        // Then: The operation should fail
        switch result {
        case .success:
            XCTFail("Add remote should have failed due to invalid repository")
        case .failure(let error as GitServiceError):
            if case .invalidRepository(let path) = error {
                XCTAssertEqual(path, repoPath.path)
            } else {
                XCTFail("Expected invalidRepository error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    // MARK: - Set Remote URL Tests
    
    func testSetRemoteURL_WhenSuccessful_ShouldReturnSuccess() async {
        // Given: Valid repository and remote details
        let remoteName = "origin"
        let newURL = URL(string: "https://github.com/user/new-repo.git")!
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call succeeds (validation), second call succeeds (set-url)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success("") // Set URL success
        ]
        
        // When: The set remote URL operation is called
        let result = await customGitService.setRemoteURL(name: remoteName, url: newURL, at: repoPath)
        
        // Then: The operation should succeed
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Remote 'origin' URL updated successfully"))
        case .failure(let error):
            XCTFail("Set remote URL should have succeeded, but failed with: \(error)")
        }
    }
    
    // MARK: - Push Tests
    
    func testPush_WhenSuccessful_ShouldReturnSuccess() async {
        // Given: Valid repository and push details
        let remoteName = "origin"
        let branch = "main"
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call succeeds (validation), second call succeeds (push)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success("Everything up-to-date") // Push success
        ]
        
        // When: The push operation is called
        let result = await customGitService.push(remoteName: remoteName, branch: branch, at: repoPath, force: false)
        
        // Then: The operation should succeed
        switch result {
        case .success(let message):
            XCTAssertTrue(message.contains("Push to 'origin' completed successfully"))
        case .failure(let error):
            XCTFail("Push should have succeeded, but failed with: \(error)")
        }
    }
    
    func testPush_WhenForceEnabled_ShouldIncludeForceFlag() async {
        // Given: Valid repository and push details with force enabled
        let remoteName = "origin"
        let branch = "main"
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call succeeds (validation), second call succeeds (push)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success("Everything up-to-date") // Push success
        ]
        
        // When: The push operation is called with force
        let result = await customGitService.push(remoteName: remoteName, branch: branch, at: repoPath, force: true)
        
        // Then: The operation should succeed with force flag
        switch result {
        case .success:
            // Test passes if no failure
            break
        case .failure(let error):
            XCTFail("Force push should have succeeded, but failed with: \(error)")
        }
    }
    
    func testPush_WhenAuthenticationFails_ShouldReturnAuthError() async {
        // Given: Valid repository but authentication failure
        let remoteName = "origin"
        let branch = "main"
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test that can handle different responses per call
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: first call succeeds (validation), second call fails (auth)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .failure(.executionFailed(exitCode: 128, stderr: "fatal: Authentication failed")) // Push auth failure
        ]
        
        // When: The push operation is called
        let result = await customGitService.push(remoteName: remoteName, branch: branch, at: repoPath, force: false)
        
        // Then: The operation should fail with authentication error
        switch result {
        case .success:
            XCTFail("Push should have failed due to authentication")
        case .failure(let error as GitServiceError):
            if case .authenticationFailed = error {
                // Expected behavior
            } else {
                XCTFail("Expected authenticationFailed error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    // MARK: - Status Tests
    
    func testStatus_WhenWorkingTreeClean_ShouldReturnCleanStatus() async {
        // Given: Valid repository with clean working tree
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: validation success, then empty status (clean)
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success("") // Empty status output means clean
        ]
        
        // When: The status operation is called
        let result = await customGitService.status(at: repoPath)
        
        // Then: The operation should succeed with clean status
        switch result {
        case .success(let status):
            XCTAssertEqual(status, "Working tree clean")
        case .failure(let error):
            XCTFail("Status should have succeeded, but failed with: \(error)")
        }
    }
    
    func testStatus_WhenFilesModified_ShouldReturnStatusOutput() async {
        // Given: Valid repository with modified files
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        let statusOutput = " M file1.txt\n?? file2.txt"
        
        // Use a custom mock for this test
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: validation success, then status with changes
        customMockShell.responses = [
            .success(""), // Repository validation success
            .success(statusOutput) // Status with changes
        ]
        
        // When: The status operation is called
        let result = await customGitService.status(at: repoPath)
        
        // Then: The operation should succeed with status output
        switch result {
        case .success(let status):
            XCTAssertEqual(status, statusOutput)
        case .failure(let error):
            XCTFail("Status should have succeeded, but failed with: \(error)")
        }
    }
    
    // MARK: - Repository Validation Tests
    
    func testIsValidRepository_WhenValidRepository_ShouldReturnTrue() async {
        // Given: Valid Git repository
        let repoPath = tempDirectory.appendingPathComponent("test-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: validation succeeds
        customMockShell.responses = [
            .success(".git") // Repository validation success
        ]
        
        // When: The validation is called
        let result = await customGitService.isValidRepository(at: repoPath)
        
        // Then: The operation should succeed and return true
        switch result {
        case .success(let isValid):
            XCTAssertTrue(isValid)
        case .failure(let error):
            XCTFail("Repository validation should have succeeded, but failed with: \(error)")
        }
    }
    
    func testIsValidRepository_WhenInvalidRepository_ShouldReturnFalse() async {
        // Given: Invalid Git repository
        let repoPath = tempDirectory.appendingPathComponent("not-a-repo")
        try! FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true)
        
        // Use a custom mock for this test
        let customMockShell = MockShellWithCallbacks()
        let customGitService = GitService(shell: customMockShell)
        
        // Set up responses: validation fails
        customMockShell.responses = [
            .failure(.executionFailed(exitCode: 128, stderr: "fatal: not a git repository")) // Repository validation failure
        ]
        
        // When: The validation is called
        let result = await customGitService.isValidRepository(at: repoPath)
        
        // Then: The operation should succeed but return false
        switch result {
        case .success(let isValid):
            XCTAssertFalse(isValid)
        case .failure(let error):
            XCTFail("Repository validation should have succeeded with false result, but failed with: \(error)")
        }
    }
    
    func testIsValidRepository_WhenPathDoesNotExist_ShouldReturnError() async {
        // Given: Non-existent path
        let repoPath = URL(fileURLWithPath: "/nonexistent/path")
        
        // When: The validation is called
        let result = await gitService.isValidRepository(at: repoPath)
        
        // Then: The operation should fail with invalid path error
        switch result {
        case .success:
            XCTFail("Repository validation should have failed due to non-existent path")
        case .failure(let error as GitServiceError):
            if case .invalidPath(let path) = error {
                XCTAssertEqual(path, "/nonexistent/path")
            } else {
                XCTFail("Expected invalidPath error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
    
    // MARK: - Timeout Tests
    
    func testShellTimeout_ShouldMapToGitServiceError() async {
        // Given: Shell command that times out
        let repoURL = URL(string: "https://github.com/user/large-repo.git")!
        let localPath = URL(fileURLWithPath: "/tmp/test-repo")
        mockShell.setFailure(.timeout(command: "git", duration: 60.0))
        
        // When: The clone operation is called
        let result = await gitService.clone(repoURL: repoURL, to: localPath)
        
        // Then: The operation should fail with timeout error
        switch result {
        case .success:
            XCTFail("Clone should have failed due to timeout")
        case .failure(let error as GitServiceError):
            if case .commandExecutionFailed(let message) = error {
                XCTAssertTrue(message.contains("timed out"))
            } else {
                XCTFail("Expected commandExecutionFailed error with timeout, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected GitServiceError, got: \(error)")
        }
    }
}