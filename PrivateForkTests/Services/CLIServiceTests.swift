import XCTest
@testable import PrivateFork

final class CLIServiceTests: XCTestCase {

    var cliService: CLIService!

    override func setUp() {
        super.setUp()
        cliService = CLIService()
    }

    override func tearDown() {
        cliService = nil
        super.tearDown()
    }

    // MARK: - Argument Parsing Tests

    func testParseArguments_ValidArguments_ShouldSucceed() async {
        // Given: Valid command line arguments
        let args = ["PrivateFork", "https://github.com/user/repo", "/Users/test/projects"]

        // When: Parsing arguments
        let result = await cliService.parseArguments(args)

        // Then: Should succeed with correct values
        switch result {
        case .success(let arguments):
            XCTAssertEqual(arguments.repositoryURL, "https://github.com/user/repo")
            XCTAssertEqual(arguments.localPath, "/Users/test/projects")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testParseArguments_TooFewArguments_ShouldFail() async {
        // Given: Too few arguments
        let args = ["PrivateFork", "https://github.com/user/repo"]

        // When: Parsing arguments
        let result = await cliService.parseArguments(args)

        // Then: Should fail with invalid arguments error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidArguments("Expected 2 arguments: <repository-url> <local-path>"))
        }
    }

    func testParseArguments_TooManyArguments_ShouldFail() async {
        // Given: Too many arguments
        let args = ["PrivateFork", "https://github.com/user/repo", "/Users/test/projects", "extra"]

        // When: Parsing arguments
        let result = await cliService.parseArguments(args)

        // Then: Should fail with invalid arguments error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidArguments("Expected 2 arguments: <repository-url> <local-path>"))
        }
    }

    func testParseArguments_FilterXcodeArguments_ShouldSucceed() async {
        // Given: Arguments with Xcode development arguments
        let args = ["PrivateFork", "-NSDocumentRevisionsDebugMode", "https://github.com/user/repo", "/Users/test/projects", "-ApplePersistenceIgnoreState"]

        // When: Parsing arguments
        let result = await cliService.parseArguments(args)

        // Then: Should succeed filtering out Xcode arguments
        switch result {
        case .success(let arguments):
            XCTAssertEqual(arguments.repositoryURL, "https://github.com/user/repo")
            XCTAssertEqual(arguments.localPath, "/Users/test/projects")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testParseArguments_FilterSystemArguments_ShouldSucceed() async {
        // Given: Arguments with system arguments
        let args = ["PrivateFork", "-psn_0_123456", "https://github.com/user/repo", "/Users/test/projects", "-com.apple.Test"]

        // When: Parsing arguments
        let result = await cliService.parseArguments(args)

        // Then: Should succeed filtering out system arguments
        switch result {
        case .success(let arguments):
            XCTAssertEqual(arguments.repositoryURL, "https://github.com/user/repo")
            XCTAssertEqual(arguments.localPath, "/Users/test/projects")
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    // MARK: - Argument Validation Tests

    func testValidateArguments_ValidGitHubURL_ShouldSucceed() async {
        // Given: Valid GitHub URL and path
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp")

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should succeed
        switch result {
        case .success:
            break // Expected
        case .failure:
            XCTFail("Expected success but got failure")
        }
    }

    func testValidateArguments_InvalidURL_ShouldFail() async {
        // Given: Invalid URL
        let arguments = CLIArguments(repositoryURL: "not-a-url", localPath: "/tmp")

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with invalid URL error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidURL("not-a-url"))
        }
    }

    func testValidateArguments_NonGitHubURL_ShouldFail() async {
        // Given: Non-GitHub URL
        let arguments = CLIArguments(repositoryURL: "https://gitlab.com/user/repo", localPath: "/tmp")

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with invalid URL error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidURL("https://gitlab.com/user/repo"))
        }
    }

    func testValidateArguments_HTTPSRequired_ShouldFail() async {
        // Given: HTTP URL instead of HTTPS
        let arguments = CLIArguments(repositoryURL: "http://github.com/user/repo", localPath: "/tmp")

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with invalid URL error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertEqual(error, .invalidURL("http://github.com/user/repo"))
        }
    }

    func testValidateArguments_ExistingFileAsPath_ShouldFail() async {
        // Given: Path that points to an existing file
        let tempFile = NSTemporaryDirectory() + "test-file"
        FileManager.default.createFile(atPath: tempFile, contents: nil)
        defer { try? FileManager.default.removeItem(atPath: tempFile) }

        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: tempFile)

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with invalid path error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .invalidPath(let path) = error {
                XCTAssertTrue(path.contains("Path exists but is not a directory"))
            } else {
                XCTFail("Expected invalidPath error")
            }
        }
    }

    func testValidateArguments_URLTooLong_ShouldFail() async {
        // Given: URL that exceeds length limit
        let veryLongURL = "https://github.com/user/" + String(repeating: "repo", count: 600)
        let arguments = CLIArguments(repositoryURL: veryLongURL, localPath: "/tmp")

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with URL too long error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .invalidURL(let message) = error {
                XCTAssertTrue(message.contains("URL too long"))
            } else {
                XCTFail("Expected invalidURL error with length message")
            }
        }
    }

    func testValidateArguments_PathTooLong_ShouldFail() async {
        // Given: Path that exceeds length limit (1024 characters)
        let veryLongPath = "/" + String(repeating: "directory/", count: 105) // 105 * 10 + 1 = 1051 characters
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: veryLongPath)

        // When: Validating arguments
        let result = await cliService.validateArguments(arguments)

        // Then: Should fail with path too long error
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .invalidPath(let message) = error {
                XCTAssertTrue(message.contains("Path too long"))
            } else {
                XCTFail("Expected invalidPath error with length message")
            }
        }
    }
}
