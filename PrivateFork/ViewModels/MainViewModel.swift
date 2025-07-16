import SwiftUI
import Foundation
import AppKit

@MainActor
final class MainViewModel: ObservableObject {
    @Published var isShowingSettings: Bool = false
    @Published var repoURL: String = ""
    @Published var isValidURL: Bool = false
    @Published var urlValidationMessage: String = ""
    @Published var localPath: String = ""
    @Published var hasSelectedDirectory: Bool = false

    private var debounceTimer: Timer?

    init() {
        // Initialization code will be added as needed
    }

    func showSettings() {
        isShowingSettings = true
    }

    func hideSettings() {
        isShowingSettings = false
    }

    func updateRepositoryURL(_ url: String) {
        repoURL = url

        // Cancel previous timer
        debounceTimer?.invalidate()

        // Start new timer with 0.3 second delay
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task { @MainActor in
                await self.validateURL()
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

    func selectDirectory() async -> Result<Void, DirectorySelectionError> {
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
                localPath = url.path
                hasSelectedDirectory = true
                return .success(())
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
