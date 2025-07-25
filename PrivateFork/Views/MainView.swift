import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    private let keychainService: KeychainServiceProtocol
    private let gitHubValidationService: GitHubValidationServiceProtocol

    init(viewModel: MainViewModel, 
         keychainService: KeychainServiceProtocol,
         gitHubValidationService: GitHubValidationServiceProtocol) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.keychainService = keychainService
        self.gitHubValidationService = gitHubValidationService
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("PrivateFork")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create private mirrors of GitHub repositories")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Credentials Status Indicator
            HStack {
                Image(systemName: viewModel.hasCredentials ? "checkmark.circle" : "exclamationmark.triangle")
                    .foregroundColor(viewModel.hasCredentials ? .green : .orange)

                Text(viewModel.credentialsStatusMessage)
                    .font(.caption)
                    .foregroundColor(viewModel.hasCredentials ? .green : .orange)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Repository URL")
                    .font(.headline)
                    .fontWeight(.medium)

                TextField("https://github.com/owner/repository", text: $viewModel.repoURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(!viewModel.isUIEnabled)
                    .accessibilityLabel("Repository URL")
                    .accessibilityHint("Enter the GitHub repository URL to fork")
                    .accessibilityIdentifier("repository-url-field")
                    .onChange(of: viewModel.repoURL) { _, newValue in
                        viewModel.updateRepositoryURL(newValue)
                    }

                if !viewModel.urlValidationMessage.isEmpty {
                    HStack {
                        Image(systemName: viewModel.isValidURL ? "checkmark.circle" : "exclamationmark.triangle")
                            .foregroundColor(viewModel.isValidURL ? .green : .orange)

                        Text(viewModel.urlValidationMessage)
                            .font(.caption)
                            .foregroundColor(viewModel.isValidURL ? .green : .orange)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 6) {
                Text("Local Directory")
                    .font(.headline)
                    .fontWeight(.medium)

                HStack {
                    Button(action: {
                        Task {
                            await viewModel.selectDirectory()
                        }
                    }) {
                        HStack {
                            Image(systemName: "folder")
                            Text("Select Folder")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isUIEnabled)
                    .accessibilityLabel("Select Folder")
                    .accessibilityHint("Choose the local directory where the fork will be created")
                    .accessibilityIdentifier("select-folder-button")

                    Spacer()
                }

                if viewModel.hasSelectedDirectory {
                    Text(viewModel.getFormattedPath())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Status Display Area
            VStack(alignment: .leading, spacing: 8) {
                Text("Status")
                    .font(.headline)
                    .fontWeight(.medium)

                HStack {
                    if viewModel.isForking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }

                    Text(viewModel.statusMessage)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Create Private Fork Button
            Button(action: {
                Task {
                    await viewModel.createPrivateFork()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isForking ? "arrow.clockwise" : "doc.badge.plus")
                    Text(viewModel.isForking ? "Creating Fork..." : "Create Private Fork")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isCreateButtonEnabled)
            .accessibilityLabel(viewModel.isForking ? "Creating Fork" : "Create Private Fork")
            .accessibilityHint(viewModel.isForking ? "Fork creation in progress" : "Start creating a private fork of the repository")
            .accessibilityIdentifier("create-private-fork-button")
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            // LAZY KEYCHAIN ACCESS: Only check credentials when GUI actually loads
            // This maintains GUI functionality while keeping CLI mode free of keychain dialogs
            Task {
                await viewModel.initializeCredentialsCheck()
            }
        }
        .frame(width: 500, height: 480)
        .padding()
    }
}

#Preview {
    // Use mock services for preview to prevent Keychain access during development
    let mockKeychainService = PreviewMockKeychainService()
    let mockOrchestrator = PreviewMockOrchestrator()
    let mockGitHubValidationService = PreviewMockGitHubValidationService()
    
    MainView(
        viewModel: MainViewModel(
            keychainService: mockKeychainService, 
            privateForkOrchestrator: mockOrchestrator
        ),
        keychainService: mockKeychainService,
        gitHubValidationService: mockGitHubValidationService
    )
}

// MARK: - Preview Mock Services
private class PreviewMockKeychainService: KeychainServiceProtocol {
    func save(username: String, token: String) async -> Result<Void, KeychainError> { .success(()) }
    func retrieve() async -> Result<(username: String, token: String), KeychainError> { .success(("preview", "token")) }
    func delete() async -> Result<Void, KeychainError> { .success(()) }
    func getGitHubToken() async -> Result<String, KeychainError> { .success("preview-token") }
}

private class PreviewMockOrchestrator: PrivateForkOrchestratorProtocol {
    func createPrivateFork(repositoryURL: String, localPath: String, statusCallback: @escaping (String) -> Void) async -> Result<String, PrivateForkError> {
        statusCallback("Preview mode - no actual fork created")
        return .success("Preview mode success")
    }
}

private class PreviewMockGitHubValidationService: GitHubValidationServiceProtocol {
    func validateCredentials(username: String, token: String) async -> Result<Bool, GitHubValidationError> { .success(true) }
}
