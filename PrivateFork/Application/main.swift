import SwiftUI
import Foundation

/// Phase 3 Priority 5: Architectural Improvement - Clean Application Entry Point
/// Uses AppLauncher to decouple CLI/GUI initialization and eliminate keychain dialogs in CLI mode

// Top-level execution using clean AppLauncher pattern
AppLauncher.launch(arguments: CommandLine.arguments)
