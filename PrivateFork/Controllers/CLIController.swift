import Foundation

class CLIController {
    private let cliService: CLIServiceProtocol
    private let keychainService: KeychainServiceProtocol

    init(cliService: CLIServiceProtocol = CLIService(),
         keychainService: KeychainServiceProtocol = KeychainService()) {
        self.cliService = cliService
        self.keychainService = keychainService
    }

    static func run(arguments: [String]) async -> Int32 {
        let controller = CLIController()
        return await controller.execute(arguments: arguments)
    }

    func execute(arguments: [String]) async -> Int32 {
        do {
            let parsedArgs = try await parseAndValidateArguments(arguments)
            // DEFERRED: Credential validation now happens only when actually needed
            // This eliminates keychain security dialogs during CLI startup

            print("✅ Arguments validated successfully")
            print("Repository: \(parsedArgs.repositoryURL)")
            print("Local Path: \(parsedArgs.localPath)")

            return CLIExitCode.success.rawValue

        } catch let error as CLIError {
            await handleCLIError(error)
            return exitCodeForError(error)
        } catch {
            fputs("❌ Unexpected error: \(error.localizedDescription)\n", stderr)
            return CLIExitCode.operationFailed.rawValue
        }
    }

    private func parseAndValidateArguments(_ arguments: [String]) async throws -> CLIArguments {
        let parseResult = await cliService.parseArguments(arguments)

        switch parseResult {
        case .success(let parsedArgs):
            let validationResult = await cliService.validateArguments(parsedArgs)
            switch validationResult {
            case .success:
                return parsedArgs
            case .failure(let error):
                throw error
            }
        case .failure(let error):
            throw error
        }
    }

    private func validateCredentials() async throws {
        let credentialsResult = await keychainService.getGitHubToken()

        switch credentialsResult {
        case .success(let token):
            if token.isEmpty {
                throw CLIError.credentialsNotConfigured
            }
        case .failure:
            throw CLIError.credentialsNotConfigured
        }
    }

    private func handleCLIError(_ error: CLIError) async {
        switch error {
        case .invalidArguments:
            fputs("❌ \(error.localizedDescription)\n\n", stderr)
            cliService.printUsage()
        case .credentialsNotConfigured:
            fputs("❌ \(error.localizedDescription)\n", stderr)
            fputs("💡 Run 'open -a PrivateFork' to configure your GitHub credentials.\n", stderr)
        default:
            fputs("❌ \(error.localizedDescription)\n", stderr)
        }
    }

    /// Validates credentials only when actually needed for GitHub operations
    /// This method should be called before any GitHub API calls, not during startup
    private func validateCredentialsWhenNeeded() async throws {
        let credentialsResult = await keychainService.getGitHubToken()

        switch credentialsResult {
        case .success(let token):
            if token.isEmpty {
                throw CLIError.credentialsNotConfigured
            }
        case .failure:
            throw CLIError.credentialsNotConfigured
        }
    }

    private func exitCodeForError(_ error: CLIError) -> Int32 {
        switch error {
        case .invalidArguments, .invalidURL, .invalidPath:
            return CLIExitCode.invalidArguments.rawValue
        case .credentialsNotConfigured:
            return CLIExitCode.credentialsNotConfigured.rawValue
        case .credentialValidationFailed:
            return CLIExitCode.credentialValidationFailed.rawValue
        case .operationFailed:
            return CLIExitCode.operationFailed.rawValue
        }
    }
}
