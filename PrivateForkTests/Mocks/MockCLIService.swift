import Foundation
@testable import PrivateFork

class MockCLIService: CLIServiceProtocol {
    var parseArgumentsResult: Result<CLIArguments, CLIError>?
    var validateArgumentsResult: Result<Void, CLIError>?
    var printUsageCalled = false
    
    func parseArguments(_ args: [String]) async -> Result<CLIArguments, CLIError> {
        return parseArgumentsResult ?? .failure(.invalidArguments("Mock not configured"))
    }
    
    func validateArguments(_ arguments: CLIArguments) async -> Result<Void, CLIError> {
        return validateArgumentsResult ?? .failure(.invalidArguments("Mock not configured"))
    }
    
    func printUsage() {
        printUsageCalled = true
    }
}