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
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showSettings()
                }, label: {
                    Image(systemName: "gear")
                        .imageScale(.large)
                })
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Settings")
                .accessibilityHint("Open application settings")
            }
            .padding(.top)

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

                if !viewModel.hasCredentials {
                    Button("Configure") {
                        viewModel.showSettings()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
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
        .sheet(isPresented: $viewModel.isShowingSettings, onDismiss: {
            viewModel.hideSettings()
        }) {
            SettingsView(keychainService: keychainService, gitHubValidationService: gitHubValidationService)
        }
    }
}

#Preview {
    MainView(viewModel: MainViewModel(keychainService: KeychainService()),
             keychainService: KeychainService(),
             gitHubValidationService: GitHubValidationService())
}
