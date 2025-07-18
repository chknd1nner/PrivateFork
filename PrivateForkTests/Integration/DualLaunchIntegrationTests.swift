import XCTest
@testable import PrivateFork

final class DualLaunchIntegrationTests: XCTestCase {
    
    // MARK: - CLI Mode Detection Tests
    
    func testShouldRunInCLIMode_EmptyArguments_ShouldReturnFalse() {
        // Given: Only the executable name
        let arguments = ["PrivateFork"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return false (GUI mode)
        XCTAssertFalse(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithValidArguments_ShouldReturnTrue() {
        // Given: Valid CLI arguments
        let arguments = ["PrivateFork", "https://github.com/user/repo", "/tmp/test"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return true (CLI mode)
        XCTAssertTrue(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithXcodeArguments_ShouldReturnFalse() {
        // Given: Only Xcode development arguments
        let arguments = ["PrivateFork", "-NSDocumentRevisionsDebugMode", "YES", "-ApplePersistenceIgnoreState", "YES"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return false (GUI mode)
        XCTAssertFalse(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithSystemArguments_ShouldReturnFalse() {
        // Given: System arguments that should be filtered
        let arguments = ["PrivateFork", "-psn_0_123456", "-AppleLocale", "en_US", "-com.apple.CoreGraphics.MaxFrameRate", "60"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return false (GUI mode)
        XCTAssertFalse(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithTooManyArguments_ShouldReturnTrue() {
        // Given: Too many arguments (potential attack)
        let arguments = Array(repeating: "arg", count: 15)
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return true (CLI mode for error handling)
        XCTAssertTrue(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithVeryLongArguments_ShouldReturnTrue() {
        // Given: Arguments that are too long
        let veryLongArg = String(repeating: "a", count: 5000)
        let arguments = ["PrivateFork", veryLongArg]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return true (CLI mode for error handling)
        XCTAssertTrue(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithMixedArguments_ShouldReturnTrue() {
        // Given: Mix of Xcode and valid CLI arguments
        let arguments = ["PrivateFork", "-NSDocumentRevisionsDebugMode", "https://github.com/user/repo", "/tmp/test", "-ApplePersistenceIgnoreState"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return true (CLI mode) as valid arguments are present
        XCTAssertTrue(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithDerivedDataPath_ShouldReturnFalse() {
        // Given: Arguments containing DerivedData path
        let arguments = ["PrivateFork", "/Users/dev/Library/Developer/Xcode/DerivedData/PrivateFork-abc/Build/Products/Debug/PrivateFork.app"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return false (GUI mode)
        XCTAssertFalse(shouldRunCLI)
    }
    
    func testShouldRunInCLIMode_WithBuildProductsPath_ShouldReturnFalse() {
        // Given: Arguments containing Build/Products path
        let arguments = ["PrivateFork", "/path/to/Build/Products/Debug/PrivateFork"]
        
        // When: Checking if should run in CLI mode
        let shouldRunCLI = AppLauncher.shouldRunInCLIMode(arguments: arguments)
        
        // Then: Should return false (GUI mode)
        XCTAssertFalse(shouldRunCLI)
    }
    
    // MARK: - Integration Test Helpers
    
    func testCLIService_Integration_WithRealArguments() async {
        // Given: Real CLI service and valid arguments
        let cliService = CLIService()
        let args = ["PrivateFork", "https://github.com/octocat/Hello-World", "/tmp"]
        
        // When: Parsing and validating arguments
        let parseResult = await cliService.parseArguments(args)
        
        // Then: Should successfully parse
        switch parseResult {
        case .success(let arguments):
            XCTAssertEqual(arguments.repositoryURL, "https://github.com/octocat/Hello-World")
            XCTAssertEqual(arguments.localPath, "/tmp")
            
            // When: Validating parsed arguments
            let validateResult = await cliService.validateArguments(arguments)
            
            // Then: Should successfully validate
            switch validateResult {
            case .success:
                break // Expected
            case .failure(let error):
                XCTFail("Validation failed: \(error)")
            }
        case .failure(let error):
            XCTFail("Parsing failed: \(error)")
        }
    }
}