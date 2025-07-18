import Foundation

class CLIService: CLIServiceProtocol {
    // Security limits for argument validation
    private static let maxUrlLength = 2048      // Standard URL limit
    private static let maxPathLength = 1024     // Reasonable path limit
    func parseArguments(_ args: [String]) async -> Result<CLIArguments, CLIError> {
        let filteredArgs = args.dropFirst().filter { arg in
            !arg.contains("/DerivedData/") &&
            !arg.contains("/Build/Products/") &&
            !arg.hasPrefix("-NS") &&
            !arg.hasPrefix("-ApplePersistence") &&
            !arg.hasPrefix("-psn_") &&           // Process Serial Number
            !arg.hasPrefix("-XS") &&             // Xcode Server  
            !arg.hasPrefix("-AppleLocale") &&
            !arg.hasPrefix("-AppleLanguages") &&
            !arg.hasPrefix("-AppleTextDirection") &&
            !arg.hasPrefix("-com.apple.")
        }

        guard filteredArgs.count == 2 else {
            return .failure(.invalidArguments("Expected 2 arguments: <repository-url> <local-path>"))
        }

        let repositoryURL = String(filteredArgs[0])
        let localPath = String(filteredArgs[1])

        let arguments = CLIArguments(repositoryURL: repositoryURL, localPath: localPath)
        return .success(arguments)
    }

    func validateArguments(_ arguments: CLIArguments) async -> Result<Void, CLIError> {
        // Length validation for security
        guard arguments.repositoryURL.count <= Self.maxUrlLength else {
            return .failure(.invalidURL("URL too long (max \(Self.maxUrlLength) characters)"))
        }

        guard arguments.localPath.count <= Self.maxPathLength else {
            return .failure(.invalidPath("Path too long (max \(Self.maxPathLength) characters)"))
        }

        guard let url = URL(string: arguments.repositoryURL),
              url.scheme == "https",
              url.host == "github.com" else {
            return .failure(.invalidURL(arguments.repositoryURL))
        }

        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let pathExists = fileManager.fileExists(atPath: arguments.localPath, isDirectory: &isDirectory)

        if pathExists && !isDirectory.boolValue {
            return .failure(.invalidPath("Path exists but is not a directory: \(arguments.localPath)"))
        }

        if !pathExists {
            let parentPath = (arguments.localPath as NSString).deletingLastPathComponent
            if !fileManager.fileExists(atPath: parentPath) {
                return .failure(.invalidPath("Parent directory does not exist: \(parentPath)"))
            }
        }

        return .success(())
    }

    func printUsage() {
        print("""
        PrivateFork CLI

        Usage: PrivateFork <repository-url> <local-path>

        Arguments:
          repository-url    GitHub repository URL (https://github.com/user/repo)
          local-path        Local directory path for the forked repository

        Example:
          PrivateFork https://github.com/user/awesome-repo ~/Projects/my-fork

        Note: GitHub credentials must be configured via the GUI before using CLI.
        """)
    }
}
