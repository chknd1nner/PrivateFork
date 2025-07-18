import XCTest
@testable import PrivateFork

final class CLIModelsTests: XCTestCase {

    func testCLIArguments_Initialization() {
        // Given: Valid repository URL and local path
        let repositoryURL = "https://github.com/user/repo"
        let localPath = "/Users/test/projects"

        // When: Creating CLIArguments
        let arguments = CLIArguments(repositoryURL: repositoryURL, localPath: localPath)

        // Then: Arguments should be set correctly
        XCTAssertEqual(arguments.repositoryURL, repositoryURL)
        XCTAssertEqual(arguments.localPath, localPath)
    }

    func testCLIError_ErrorDescriptions() {
        // Given: Various CLI errors
        let invalidArgsError = CLIError.invalidArguments("test details")
        let invalidURLError = CLIError.invalidURL("bad-url")
        let invalidPathError = CLIError.invalidPath("/bad/path")
        let credentialsError = CLIError.credentialsNotConfigured
        let validationError = CLIError.credentialValidationFailed
        let operationError = CLIError.operationFailed("test failure")

        // Then: Each error should have appropriate description
        XCTAssertEqual(invalidArgsError.errorDescription, "Invalid arguments: test details")
        XCTAssertEqual(invalidURLError.errorDescription, "Invalid repository URL: bad-url")
        XCTAssertEqual(invalidPathError.errorDescription, "Invalid local path: /bad/path")
        XCTAssertEqual(credentialsError.errorDescription, "Credentials not configured. Please launch the GUI to configure GitHub credentials.")
        XCTAssertEqual(validationError.errorDescription, "Credential validation failed. Please check your GitHub token in the GUI.")
        XCTAssertEqual(operationError.errorDescription, "Operation failed: test failure")
    }

    func testCLIExitCode_RawValues() {
        // Then: Exit codes should have correct raw values
        XCTAssertEqual(CLIExitCode.success.rawValue, 0)
        XCTAssertEqual(CLIExitCode.invalidArguments.rawValue, 1)
        XCTAssertEqual(CLIExitCode.credentialsNotConfigured.rawValue, 2)
        XCTAssertEqual(CLIExitCode.credentialValidationFailed.rawValue, 3)
        XCTAssertEqual(CLIExitCode.operationFailed.rawValue, 4)
    }
}
