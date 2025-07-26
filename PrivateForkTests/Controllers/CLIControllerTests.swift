import XCTest
@testable import PrivateFork

final class CLIControllerTests: XCTestCase {

    var cliController: CLIController!
    var mockCLIService: MockCLIService!
    var mockKeychainService: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockCLIService = MockCLIService()
        mockKeychainService = MockKeychainService()
        cliController = CLIController(cliService: mockCLIService, keychainService: mockKeychainService)
    }

    override func tearDown() {
        cliController = nil
        mockCLIService = nil
        mockKeychainService = nil
        super.tearDown()
    }

    // MARK: - Success Scenarios

    func testExecute_ValidArgumentsAndCredentials_ShouldReturnSuccess() async {
        // Given: Valid arguments and credentials
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .success(())
        mockKeychainService.setStoredOAuthTokens(accessToken: "test-token", refreshToken: "refresh-token", expiresIn: Date().addingTimeInterval(3600))

        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/tmp/test"])

        // Then: Should return success exit code
        XCTAssertEqual(exitCode, CLIExitCode.success.rawValue)
    }

    // MARK: - Argument Parsing Failures

    func testExecute_InvalidArguments_ShouldReturnInvalidArgumentsExitCode() async {
        // Given: Invalid arguments
        mockCLIService.parseArgumentsResult = .failure(.invalidArguments("test error"))

        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork"])

        // Then: Should return invalid arguments exit code and print usage
        XCTAssertEqual(exitCode, CLIExitCode.invalidArguments.rawValue)
        XCTAssertTrue(mockCLIService.printUsageCalled)
    }

    func testExecute_InvalidURL_ShouldReturnInvalidArgumentsExitCode() async {
        // Given: Invalid URL
        let arguments = CLIArguments(repositoryURL: "bad-url", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .failure(.invalidURL("bad-url"))

        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "bad-url", "/tmp/test"])

        // Then: Should return invalid arguments exit code
        XCTAssertEqual(exitCode, CLIExitCode.invalidArguments.rawValue)
    }

    func testExecute_InvalidPath_ShouldReturnInvalidArgumentsExitCode() async {
        // Given: Invalid path
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/bad/path")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .failure(.invalidPath("/bad/path"))

        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/bad/path"])

        // Then: Should return invalid arguments exit code
        XCTAssertEqual(exitCode, CLIExitCode.invalidArguments.rawValue)
    }

    // MARK: - Deferred Credential Validation Tests
    // Note: Credential validation is now deferred to avoid keychain security dialogs during CLI startup
    // These tests validate that the CLI can start successfully with missing credentials,
    // following the improved automation-friendly design

    func testExecute_CredentialsNotConfigured_ShouldReturnSuccess() async {
        // Given: Valid arguments but no credentials (credentials validation is deferred)
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .success(())
        mockKeychainService.clearStoredOAuthTokens()

        // When: Executing CLI controller (argument parsing and validation only)
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/tmp/test"])

        // Then: Should return success because credential validation is deferred until actually needed
        XCTAssertEqual(exitCode, CLIExitCode.success.rawValue)
    }

    func testExecute_EmptyToken_ShouldReturnSuccess() async {
        // Given: Valid arguments but empty token (credentials validation is deferred)
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .success(())
        mockKeychainService.setStoredOAuthTokens(accessToken: "", refreshToken: "refresh-token", expiresIn: Date().addingTimeInterval(3600))

        // When: Executing CLI controller (argument parsing and validation only)
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/tmp/test"])

        // Then: Should return success because credential validation is deferred until actually needed
        XCTAssertEqual(exitCode, CLIExitCode.success.rawValue)
    }

    // MARK: - Static Run Method

    func testRun_StaticMethod_ShouldExecuteCorrectly() async {
        // Given: Valid test arguments
        let arguments = ["PrivateFork", "https://github.com/user/repo", "/tmp/test"]

        // When: Running static method
        let exitCode = await CLIController.run(arguments: arguments)

        // Then: Should return success exit code for valid arguments (credentials validation deferred)
        XCTAssertEqual(exitCode, CLIExitCode.success.rawValue)
    }

    // MARK: - Future Integration Tests
    // Note: These tests would validate credential validation when actually needed
    // They should be implemented when the full fork operation is integrated
    
    /* Example future test:
    func testForkOperation_WhenCredentialsMissing_ShouldFailWithCredentialsError() async {
        // This test would validate that when the fork operation actually tries to use credentials,
        // missing credentials cause the operation to fail with the appropriate exit code
    }
    */
}
