import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init(keychainService: KeychainServiceProtocol = KeychainService(),
         gitHubValidationService: GitHubValidationServiceProtocol = GitHubValidationService()) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            keychainService: keychainService,
            gitHubValidationService: gitHubValidationService
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with title and cancel button
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
            }
            .padding(.bottom, 10)

            // GitHub Credentials Section
            VStack(alignment: .leading, spacing: 12) {
                Text("GitHub Credentials")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("GitHub Username")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter your GitHub username", text: $viewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isValidating)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Access Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    CustomSecureField("Enter your Personal Access Token", text: $viewModel.token)
                        .disabled(viewModel.isValidating)
                }
            }

            // Buttons Section
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await viewModel.validateAndSave()
                    }
                }) {
                    Text("Validate & Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.username.isEmpty || viewModel.token.isEmpty || viewModel.isValidating)

                Button(action: {
                    Task {
                        await viewModel.clear()
                    }
                }) {
                    Text("Clear")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isValidating)
                .foregroundColor(.red)
            }

            // Status Messages
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isValidating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Validating credentials...")
                            .foregroundColor(.secondary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if viewModel.isSaved {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Credentials saved successfully")
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 480, height: 360)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    SettingsView(keychainService: KeychainService(),
                gitHubValidationService: GitHubValidationService())
}
