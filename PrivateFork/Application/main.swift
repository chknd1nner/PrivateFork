import SwiftUI
import Foundation

struct PrivateForkMain {
    // Protection against malicious input
    private static let maxArgumentLength = 4096  // Reasonable for paths/URLs
    private static let maxTotalArguments = 10    // Prevent argument flooding
    
    static func shouldRunInCLIMode(arguments: [String]) -> Bool {
        // CONSERVATIVE APPROACH: Default to GUI mode unless we're certain it's CLI
        
        // Early protection against malicious input
        guard arguments.count <= maxTotalArguments else {
            return true  // Let CLI handle the error properly
        }

        guard arguments.allSatisfy({ $0.count <= maxArgumentLength }) else {
            return true  // Let CLI handle the error properly
        }
        
        // Much more comprehensive filtering - be aggressive about filtering system args
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
            // FIXED: Only allow paths that look like user-intentional paths
            (!arg.hasPrefix("/") || 
             (arg.hasPrefix("/") && !arg.contains("/System/") && !arg.contains("/usr/") && !arg.contains("/Applications/") && !arg.contains("/Library/")))
        }
        
        // Only enter CLI mode if we have EXACTLY what we expect for CLI usage
        // This is much more restrictive - require explicit CLI patterns
        if filteredArgs.count == 2 {
            // Check if first arg looks like a GitHub URL
            let potentialURL = filteredArgs[0]
            if potentialURL.hasPrefix("https://github.com/") {
                return true  // This looks like intentional CLI usage
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

// Top-level execution
let arguments = CommandLine.arguments

if PrivateForkMain.shouldRunInCLIMode(arguments: arguments) {
    // CLI Mode - execute outside SwiftUI lifecycle
    Task {
        let exitCode = await CLIController.run(arguments: arguments)
        exit(exitCode)
    }
    RunLoop.main.run() // Keep alive for async operations
} else {
    // GUI Mode - normal SwiftUI initialization
    PrivateForkApp.main()
}