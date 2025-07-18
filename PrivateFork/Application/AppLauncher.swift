import SwiftUI
import Foundation

/// AppLauncher: Clean separation of CLI and GUI initialization paths
/// Implements Phase 3 Priority 5 architectural improvements to eliminate
/// keychain security dialogs during CLI startup through lazy dependency injection
final class AppLauncher {

    // MARK: - Security Configuration
    private static let maxArgumentLength = 4096
    private static let maxTotalArguments = 10

    // MARK: - Public Interface

    /// Main entry point - determines execution mode and routes appropriately
    static func launch(arguments: [String]) {
        if shouldRunInCLIMode(arguments: arguments) {
            runCLI(arguments: arguments)
        } else {
            runGUI()
        }
    }

    /// CLI Mode: Initialize only CLI-required services
    /// NO keychain access during initialization - lazy loading only
    static func runCLI(arguments: [String]) {
        // CRITICAL: Only initialize CLI dependencies
        // KeychainService will be lazily accessed by CLIController when needed
        Task {
            let exitCode = await CLIController.run(arguments: arguments)
            exit(exitCode)
        }
        RunLoop.main.run() // Keep alive for async operations
    }

    /// GUI Mode: Initialize full GUI application with all dependencies
    static func runGUI() {
        // Full SwiftUI app initialization with all GUI dependencies
        PrivateForkApp.main()
    }

    // MARK: - Mode Detection Logic

    static func shouldRunInCLIMode(arguments: [String]) -> Bool {
        // CONSERVATIVE APPROACH: Default to GUI mode unless certain it's CLI

        // Early protection against malicious input
        guard arguments.count <= maxTotalArguments else {
            return true  // Let CLI handle the error properly
        }

        guard arguments.allSatisfy({ $0.count <= maxArgumentLength }) else {
            return true  // Let CLI handle the error properly
        }

        // Comprehensive filtering - aggressive about filtering system arguments
        let filteredArgs = arguments.dropFirst().filter { arg in
            // Filter out ANY development/system arguments
            !arg.contains("/DerivedData/") &&
            !arg.contains("/Build/Products/") &&
            !arg.contains("/Library/Developer/") &&
            !arg.contains(".xcodeproj") &&
            !arg.contains(".app/") &&
            !arg.hasPrefix("-NS") &&
            !arg.hasPrefix("-ApplePersistence") &&
            !arg.hasPrefix("-Apple") &&
            !arg.hasPrefix("-psn_") &&
            !arg.hasPrefix("-XS") &&
            !arg.hasPrefix("-com.apple.") &&
            !arg.hasPrefix("-D") &&         // Debug flags
            !arg.hasPrefix("-O") &&         // Optimization flags
            arg != "YES" &&                // Common flag values
            arg != "NO" &&
            !arg.isEmpty &&
            // Only allow paths that look like user-intentional paths
            (!arg.hasPrefix("/") ||
             (arg.hasPrefix("/") && !arg.contains("/System/") && !arg.contains("/usr/") && !arg.contains("/Applications/") && !arg.contains("/Library/")))
        }

        // Only enter CLI mode with explicit CLI patterns
        if filteredArgs.count == 2 {
            // Check if first arg looks like a GitHub URL
            let potentialURL = filteredArgs[0]
            if potentialURL.hasPrefix("https://github.com/") {
                return true  // Intentional CLI usage
            }
        }

        // Check for help flags
        if filteredArgs.contains("--help") || filteredArgs.contains("-h") || filteredArgs.contains("--version") {
            return true
        }

        // Default to GUI mode for everything else
        return false
    }
}
