import XCTest
@testable import PrivateFork

@MainActor
final class ShellTests: XCTestCase {
    
    var shell: Shell!
    
    override func setUp() {
        super.setUp()
        shell = Shell()
    }
    
    override func tearDown() {
        shell = nil
        super.tearDown()
    }
    
    // MARK: - Successful Command Execution Tests
    
    func testExecute_WhenValidCommand_ShouldReturnSuccess() async {
        // Given: A simple command that should succeed
        let command = "echo"
        let arguments = ["Hello, World!"]
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: The command should succeed and return output
        switch result {
        case .success(let output):
            XCTAssertEqual(output, "Hello, World!")
        case .failure(let error):
            XCTFail("Command should have succeeded, but failed with: \(error)")
        }
    }
    
    func testExecute_WhenCommandWithWorkingDirectory_ShouldUseCorrectDirectory() async {
        // Given: A command that lists directory contents and a valid working directory
        let command = "pwd"
        let arguments: [String] = []
        let workingDirectory = URL(fileURLWithPath: "/tmp")
        
        // When: The command is executed with working directory
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: workingDirectory, timeout: 5.0)
        
        // Then: The command should succeed and show the working directory
        switch result {
        case .success(let output):
            XCTAssertTrue(output.contains("/tmp") || output.contains("/private/tmp")) // macOS sometimes uses /private/tmp
        case .failure(let error):
            XCTFail("Command should have succeeded, but failed with: \(error)")
        }
    }
    
    // MARK: - Command Failure Tests
    
    func testExecute_WhenCommandNotFound_ShouldReturnCommandNotFoundError() async {
        // Given: A non-existent command
        let command = "nonexistentcommand12345"
        let arguments: [String] = []
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: The command should fail with command not found error
        switch result {
        case .success:
            XCTFail("Command should have failed due to command not found")
        case .failure(let error as ShellError):
            if case .commandNotFound(let cmd) = error {
                XCTAssertEqual(cmd, command)
            } else {
                XCTFail("Expected commandNotFound error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    func testExecute_WhenCommandFailsWithExitCode_ShouldReturnExecutionFailedError() async {
        // Given: A command that will fail (trying to list non-existent directory)
        let command = "ls"
        let arguments = ["/nonexistent/directory/path"]
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: The command should fail with execution failed error
        switch result {
        case .success:
            XCTFail("Command should have failed due to non-existent directory")
        case .failure(let error as ShellError):
            if case .executionFailed(let exitCode, let stderr) = error {
                XCTAssertNotEqual(exitCode, 0)
                XCTAssertTrue(stderr.contains("No such file or directory") || stderr.contains("cannot access"))
            } else {
                XCTFail("Expected executionFailed error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    // MARK: - Working Directory Tests
    
    func testExecute_WhenInvalidWorkingDirectory_ShouldReturnError() async {
        // Given: An invalid working directory
        let command = "echo"
        let arguments = ["test"]
        let invalidWorkingDirectory = URL(fileURLWithPath: "/nonexistent/directory")
        
        // When: The command is executed with invalid working directory
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: invalidWorkingDirectory, timeout: 5.0)
        
        // Then: The command should fail with invalid working directory error
        switch result {
        case .success:
            XCTFail("Command should have failed due to invalid working directory")
        case .failure(let error as ShellError):
            if case .invalidWorkingDirectory(let url) = error {
                XCTAssertEqual(url.path, "/nonexistent/directory")
            } else {
                XCTFail("Expected invalidWorkingDirectory error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    func testExecute_WhenWorkingDirectoryIsFile_ShouldReturnError() async {
        // Given: A working directory that points to a file instead of directory
        let command = "echo"
        let arguments = ["test"]
        
        // Create a temporary file
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_file.txt")
        try! "test content".write(to: tempFileURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        
        // When: The command is executed with file as working directory
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: tempFileURL, timeout: 5.0)
        
        // Then: The command should fail with invalid working directory error
        switch result {
        case .success:
            XCTFail("Command should have failed due to working directory being a file")
        case .failure(let error as ShellError):
            if case .invalidWorkingDirectory = error {
                // Expected behavior
            } else {
                XCTFail("Expected invalidWorkingDirectory error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    // MARK: - Timeout Tests
    
    func testExecute_WhenCommandTimesOut_ShouldReturnTimeoutError() async {
        // Given: A command that will run longer than the timeout
        let command = "sleep"
        let arguments = ["3"] // Sleep for 3 seconds
        let timeout: TimeInterval = 1.0 // But timeout after 1 second
        
        // When: The command is executed with short timeout
        let startTime = Date()
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: timeout)
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Then: The command should fail with timeout error within reasonable time
        XCTAssertLessThan(executionTime, 2.0, "Command should have timed out quickly")
        
        switch result {
        case .success:
            XCTFail("Command should have failed due to timeout")
        case .failure(let error as ShellError):
            if case .timeout(let cmd, let duration) = error {
                XCTAssertEqual(cmd, command)
                XCTAssertEqual(duration, timeout)
            } else {
                XCTFail("Expected timeout error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    // MARK: - Output Handling Tests
    
    func testExecute_WhenCommandProducesLargeOutput_ShouldCaptureAllOutput() async {
        // Given: A command that produces multiple lines of output
        let command = "seq"
        let arguments = ["1", "10"] // Generate numbers 1 through 10
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: All output should be captured
        switch result {
        case .success(let output):
            let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            XCTAssertEqual(lines.count, 10)
            XCTAssertEqual(lines.first, "1")
            XCTAssertEqual(lines.last, "10")
        case .failure(let error):
            XCTFail("Command should have succeeded, but failed with: \(error)")
        }
    }
    
    func testExecute_WhenCommandProducesErrorOutput_ShouldCaptureStderr() async {
        // Given: A command that writes to stderr
        let command = "sh"
        let arguments = ["-c", "echo 'error message' >&2; exit 1"] // Write to stderr and exit with error
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: The stderr should be captured in the error
        switch result {
        case .success:
            XCTFail("Command should have failed")
        case .failure(let error as ShellError):
            if case .executionFailed(let exitCode, let stderr) = error {
                XCTAssertEqual(exitCode, 1)
                XCTAssertTrue(stderr.contains("error message"))
            } else {
                XCTFail("Expected executionFailed error, got: \(error)")
            }
        case .failure(let error):
            XCTFail("Expected ShellError, got: \(error)")
        }
    }
    
    // MARK: - Argument Handling Tests
    
    func testExecute_WhenCommandHasMultipleArguments_ShouldHandleCorrectly() async {
        // Given: A command with multiple arguments
        let command = "echo"
        let arguments = ["arg1", "arg2", "arg3"]
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: All arguments should be passed correctly
        switch result {
        case .success(let output):
            XCTAssertEqual(output, "arg1 arg2 arg3")
        case .failure(let error):
            XCTFail("Command should have succeeded, but failed with: \(error)")
        }
    }
    
    func testExecute_WhenArgumentsContainSpaces_ShouldHandleCorrectly() async {
        // Given: Arguments containing spaces
        let command = "echo"
        let arguments = ["argument with spaces", "another argument"]
        
        // When: The command is executed
        let result = await shell.execute(command: command, arguments: arguments, workingDirectory: nil, timeout: 5.0)
        
        // Then: Arguments with spaces should be handled correctly
        switch result {
        case .success(let output):
            XCTAssertEqual(output, "argument with spaces another argument")
        case .failure(let error):
            XCTFail("Command should have succeeded, but failed with: \(error)")
        }
    }
    
    // MARK: - Error Description Tests
    
    func testShellErrorDescriptions_ShouldProvideHelpfulMessages() {
        // Given: Various shell errors
        let commandNotFoundError = ShellError.commandNotFound("testcmd")
        let executionFailedError = ShellError.executionFailed(exitCode: 1, stderr: "error message")
        let timeoutError = ShellError.timeout(command: "sleep", duration: 30.0)
        let invalidDirError = ShellError.invalidWorkingDirectory(URL(fileURLWithPath: "/invalid"))
        let processingError = ShellError.processingError("process failed")
        
        // When/Then: Error descriptions should be helpful
        XCTAssertEqual(commandNotFoundError.errorDescription, "Command not found: testcmd")
        XCTAssertEqual(executionFailedError.errorDescription, "Command failed with exit code 1: error message")
        XCTAssertEqual(timeoutError.errorDescription, "Command 'sleep' timed out after 30.0 seconds")
        XCTAssertEqual(invalidDirError.errorDescription, "Invalid working directory: /invalid")
        XCTAssertEqual(processingError.errorDescription, "Process error: process failed")
    }
}