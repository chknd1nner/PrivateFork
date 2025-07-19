import Foundation

// MARK: - Shell Protocol
protocol ShellProtocol {
    func execute(command: String, arguments: [String], workingDirectory: URL?, timeout: TimeInterval) async -> Result<String, ShellError>
}

// MARK: - Shell Error Types
enum ShellError: Error, LocalizedError {
    case commandNotFound(String)
    case executionFailed(exitCode: Int32, stderr: String)
    case timeout(command: String, duration: TimeInterval)
    case invalidWorkingDirectory(URL)
    case processingError(String)
    
    var errorDescription: String? {
        switch self {
        case .commandNotFound(let command):
            return "Command not found: \(command)"
        case .executionFailed(let exitCode, let stderr):
            return "Command failed with exit code \(exitCode): \(stderr)"
        case .timeout(let command, let duration):
            return "Command '\(command)' timed out after \(duration) seconds"
        case .invalidWorkingDirectory(let url):
            return "Invalid working directory: \(url.path)"
        case .processingError(let message):
            return "Process error: \(message)"
        }
    }
}

// MARK: - Shell Implementation
class Shell: ShellProtocol {
    
    func execute(command: String, arguments: [String] = [], workingDirectory: URL? = nil, timeout: TimeInterval = 30.0) async -> Result<String, ShellError> {
        
        // Validate working directory if provided
        if let workingDir = workingDirectory {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: workingDir.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                return .failure(.invalidWorkingDirectory(workingDir))
            }
        }
        
        return await withCheckedContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            // Use NSLock to prevent race conditions between timeout and completion
            let lock = NSLock()
            var hasResumed = false
            
            // Configure process
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            // Set working directory if provided
            if let workingDir = workingDirectory {
                process.currentDirectoryURL = workingDir
            }
            
            // Use Task for timeout to avoid Sendable issues
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if process.isRunning {
                    process.terminate()
                    // Only resume if we haven't already
                    lock.lock()
                    if !hasResumed {
                        hasResumed = true
                        lock.unlock()
                        continuation.resume(returning: .failure(.timeout(command: command, duration: timeout)))
                    } else {
                        lock.unlock()
                    }
                }
            }
            
            process.terminationHandler = { process in
                timeoutTask.cancel()
                
                // Only resume if we haven't already (prevents double resume)
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    
                    // Read all data after process termination to avoid concurrency issues
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    // Convert data to strings
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    
                    // Check exit status
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: .success(output.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        // Exit code 127 indicates command not found
                        if process.terminationStatus == 127 {
                            continuation.resume(returning: .failure(.commandNotFound(command)))
                        } else {
                            continuation.resume(returning: .failure(.executionFailed(exitCode: process.terminationStatus, stderr: error.trimmingCharacters(in: .whitespacesAndNewlines))))
                        }
                    }
                } else {
                    lock.unlock()
                }
            }
            
            // Launch process
            do {
                try process.run()
            } catch {
                timeoutTask.cancel()
                // Only resume if we haven't already
                lock.lock()
                if !hasResumed {
                    hasResumed = true
                    lock.unlock()
                    continuation.resume(returning: .failure(.commandNotFound(command)))
                } else {
                    lock.unlock()
                }
            }
        }
    }
}