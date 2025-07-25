import SwiftUI
import Foundation
import AppKit

@MainActor
final class MainViewModel: ObservableObject {
    @Published var repoURL: String = ""
    @Published var isValidURL: Bool = false
    @Published var urlValidationMessage: String = ""
    @Published var localPath: String = ""
    @Published var hasSelectedDirectory: Bool = false
    @Published var hasCredentials: Bool = false
    @Published var credentialsStatusMessage: String = ""
    @Published var statusMessage: String = "Ready."
    @Published var isForking: Bool = false

    private var debounceTimer: Timer?
    private let keychainService: KeychainServiceProtocol
    private let privateForkOrchestrator: PrivateForkOrchestratorProtocol
    private var debounceInterval: TimeInterval = 0.3

    init(
        keychainService: KeychainServiceProtocol,
        privateForkOrchestrator: PrivateForkOrchestratorProtocol
    ) {
        self.keychainService = keychainService
        self.privateForkOrchestrator = privateForkOrchestrator

        // LAZY INITIALIZATION: No immediate keychain access
        // Keychain will be accessed on-demand when explicitly needed
        // This prevents security dialogs during CLI mode startup
    }

    // MARK: - Convenience Initializer with Test Protection
    convenience init() {
        #if DEBUG
        // Detect test environment and prevent real service usage
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            fatalError("❌ MainViewModel() must not be used in tests. Use dependency injection with mock services instead.")
        }
        #endif
        let keychainService = KeychainService()
        let gitHubService = GitHubService(keychainService: keychainService)
        let gitService = GitService()
        let orchestrator = PrivateForkOrchestrator(
            keychainService: keychainService,
            gitHubService: gitHubService,
            gitService: gitService
        )
        self.init(keychainService: keychainService, privateForkOrchestrator: orchestrator)
    }

    /// Configure debounce interval for testing purposes
    func setDebounceInterval(_ interval: TimeInterval) {
        debounceInterval = interval
    }


    func updateRepositoryURL(_ url: String) {
        repoURL = url

        // Cancel previous timer
        debounceTimer?.invalidate()

        // If debounce interval is 0 or very small, validate immediately
        if debounceInterval <= 0.001 {
            Task { @MainActor in
                await self.validateURL()
            }
        } else {
            // Start new timer with configurable debounce delay
            debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
                Task { @MainActor in
                    await self.validateURL()
                }
            }
        }
    }

    private func validateURL() async {
        let result = await validateGitHubURL(repoURL)

        switch result {
        case .success:
            isValidURL = true
            urlValidationMessage = "Valid GitHub repository URL"
        case .failure(let error):
            isValidURL = false
            urlValidationMessage = error.localizedDescription
        }
    }

    private func validateGitHubURL(_ urlString: String) async -> Result<Void, URLValidationError> {
        // Empty URL
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.emptyURL)
        }

        // Valid URL format
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }

        // Check if URL has proper scheme and host (catch malformed URLs)
        guard url.scheme != nil && url.host != nil else {
            return .failure(.invalidURL)
        }

        // Check for GitHub domain
        guard let host = url.host?.lowercased(),
              host == "github.com" || host == "www.github.com" else {
            return .failure(.notGitHub)
        }

        // Check for repository path structure (user/repo)
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else {
            return .failure(.invalidRepositoryPath)
        }

        // Additional validation for repository format
        let owner = pathComponents[0]
        let repo = pathComponents[1]

        guard !owner.isEmpty && !repo.isEmpty else {
            return .failure(.invalidRepositoryPath)
        }

        // Check for valid characters in owner and repo names
        let validPattern = "^[a-zA-Z0-9._-]+$"
        let regex = try? NSRegularExpression(pattern: validPattern)

        let ownerRange = NSRange(location: 0, length: owner.count)
        let repoRange = NSRange(location: 0, length: repo.count)

        guard regex?.firstMatch(in: owner, options: [], range: ownerRange) != nil,
              regex?.firstMatch(in: repo, options: [], range: repoRange) != nil else {
            return .failure(.invalidRepositoryPath)
        }

        return .success(())
    }

    func selectDirectory() async {
        let result = await performDirectorySelection()

        switch result {
        case .success(let path):
            localPath = path
            hasSelectedDirectory = true
        case .failure:
            // User cancelled or no URL selected - maintain current state
            break
        }
    }

    private func performDirectorySelection() async -> Result<String, DirectorySelectionError> {
        let panel = NSOpenPanel()
        panel.title = "Select Folder"
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        let response = await panel.begin()

        if response == .OK {
            if let url = panel.url {
                return .success(url.path)
            } else {
                return .failure(.noURLSelected)
            }
        } else {
            return .failure(.userCancelled)
        }
    }

    func getFormattedPath() -> String {
        if localPath.isEmpty {
            return "No folder selected"
        }

        // Format the path for display
        let url = URL(fileURLWithPath: localPath)
        let lastComponent = url.lastPathComponent
        let parentPath = url.deletingLastPathComponent().path

        // Show the last component and parent for context
        if parentPath == "/" {
            return lastComponent
        } else {
            return "\(parentPath)/\(lastComponent)"
        }
    }

    // MARK: - Credentials Management

    /// Explicitly check credentials when GUI actually needs them
    /// Call this when MainView appears or user interacts with UI
    func initializeCredentialsCheck() async {
        await checkCredentialsStatus()
    }

    func checkCredentialsStatus() async {
        let result = await keychainService.retrieve()

        switch result {
        case .success:
            hasCredentials = true
            credentialsStatusMessage = "GitHub credentials configured"
        case .failure(let error):
            hasCredentials = false
            if case .itemNotFound = error {
                credentialsStatusMessage = "GitHub credentials not configured."
            } else {
                credentialsStatusMessage = "Error checking credentials: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - UI State Computed Properties

    var isUIEnabled: Bool {
        return hasCredentials
    }

    var isCreateButtonEnabled: Bool {
        return hasCredentials && isValidURL && hasSelectedDirectory && !isForking
    }

    // MARK: - Fork Creation

    func createPrivateFork() async {
        guard isCreateButtonEnabled else { return }

        isForking = true
        statusMessage = "Preparing to create private fork..."

        let result = await privateForkOrchestrator.createPrivateFork(
            repositoryURL: repoURL,
            localPath: localPath
        ) { status in
            // Status callback for real-time updates
            Task { @MainActor in
                self.statusMessage = status
            }
        }

        switch result {
        case .success(let message):
            statusMessage = message
            // Reset form after successful fork creation
            Task { @MainActor in
                try await Task.sleep(for: .seconds(2))
                await resetForm()
            }
        case .failure(let error):
            statusMessage = "Error: \(error.localizedDescription)"
        }

        isForking = false
    }

    private func resetForm() async {
        statusMessage = "Ready."
    }
}

enum URLValidationError: Error, LocalizedError {
    case emptyURL
    case invalidURL
    case notGitHub
    case invalidRepositoryPath

    var errorDescription: String? {
        switch self {
        case .emptyURL:
            return "Please enter a repository URL"
        case .invalidURL:
            return "Invalid URL format"
        case .notGitHub:
            return "Please enter a GitHub repository URL"
        case .invalidRepositoryPath:
            return "Invalid repository path. Expected format: github.com/owner/repository"
        }
    }
}

enum DirectorySelectionError: Error, LocalizedError {
    case userCancelled
    case noURLSelected

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Directory selection was cancelled"
        case .noURLSelected:
            return "No directory was selected"
        }
    }
}
