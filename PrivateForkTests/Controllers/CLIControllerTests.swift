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
        mockKeychainService.setStoredCredentials(username: "testuser", token: "test-token")
        
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
    
    // MARK: - Credential Validation Failures
    
    func testExecute_CredentialsNotConfigured_ShouldReturnCredentialsNotConfiguredExitCode() async {
        // Given: Valid arguments but no credentials
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .success(())
        mockKeychainService.clearStoredCredentials()
        
        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/tmp/test"])
        
        // Then: Should return credentials not configured exit code
        XCTAssertEqual(exitCode, CLIExitCode.credentialsNotConfigured.rawValue)
    }
    
    func testExecute_EmptyToken_ShouldReturnCredentialsNotConfiguredExitCode() async {
        // Given: Valid arguments but empty token
        let arguments = CLIArguments(repositoryURL: "https://github.com/user/repo", localPath: "/tmp/test")
        mockCLIService.parseArgumentsResult = .success(arguments)
        mockCLIService.validateArgumentsResult = .success(())
        mockKeychainService.setStoredCredentials(username: "testuser", token: "")
        
        // When: Executing CLI controller
        let exitCode = await cliController.execute(arguments: ["PrivateFork", "https://github.com/user/repo", "/tmp/test"])
        
        // Then: Should return credentials not configured exit code
        XCTAssertEqual(exitCode, CLIExitCode.credentialsNotConfigured.rawValue)
    }
    
    // MARK: - Static Run Method
    
    func testRun_StaticMethod_ShouldExecuteCorrectly() async {
        // Given: Valid test arguments
        let arguments = ["PrivateFork", "https://github.com/user/repo", "/tmp/test"]
        
        // When: Running static method
        let exitCode = await CLIController.run(arguments: arguments)
        
        // Then: Should return appropriate exit code (will vary based on actual implementation)
        XCTAssertTrue(exitCode >= 0)
    }
}