import Foundation

protocol CLIServiceProtocol {
    func parseArguments(_ args: [String]) async -> Result<CLIArguments, CLIError>
    func validateArguments(_ arguments: CLIArguments) async -> Result<Void, CLIError>
    func printUsage()
}
