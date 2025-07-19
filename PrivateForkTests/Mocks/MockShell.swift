import Foundation
@testable import PrivateFork

class MockShell: ShellProtocol {
    
    // MARK: - Mock Configuration Properties
    var executeResult: Result<String, ShellError> = .success("")
    var executeCallCount = 0
    var lastCommand: String?
    var lastArguments: [String] = []
    var lastWorkingDirectory: URL?
    var lastTimeout: TimeInterval?
    
    // MARK: - Call History
    struct ExecuteCall {
        let command: String
        let arguments: [String]
        let workingDirectory: URL?
        let timeout: TimeInterval
    }
    
    var executeCalls: [ExecuteCall] = []
    
    // MARK: - Mock Implementation
    
    func execute(command: String, arguments: [String], workingDirectory: URL?, timeout: TimeInterval) async -> Result<String, ShellError> {
        executeCallCount += 1
        lastCommand = command
        lastArguments = arguments
        lastWorkingDirectory = workingDirectory
        lastTimeout = timeout
        
        // Record the call
        executeCalls.append(ExecuteCall(
            command: command,
            arguments: arguments,
            workingDirectory: workingDirectory,
            timeout: timeout
        ))
        
        return executeResult
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        executeResult = .success("")
        executeCallCount = 0
        lastCommand = nil
        lastArguments = []
        lastWorkingDirectory = nil
        lastTimeout = nil
        executeCalls = []
    }
    
    func setResult(_ result: Result<String, ShellError>) {
        executeResult = result
    }
    
    func setSuccess(_ output: String) {
        executeResult = .success(output)
    }
    
    func setFailure(_ error: ShellError) {
        executeResult = .failure(error)
    }
    
    // MARK: - Verification Helpers
    
    func wasCalledWith(command: String, arguments: [String]) -> Bool {
        return executeCalls.contains { call in
            call.command == command && call.arguments == arguments
        }
    }
    
    func wasCalledWith(command: String, argumentsContaining: String) -> Bool {
        return executeCalls.contains { call in
            call.command == command && call.arguments.contains(argumentsContaining)
        }
    }
    
    func getLastCall() -> ExecuteCall? {
        return executeCalls.last
    }
}