import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            keychainService: KeychainService(),
            gitHubValidationService: GitHubValidationService()
        ))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub Credentials")) {
                    TextField("GitHub Username", text: $viewModel.username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isValidating)

                    SecureField("Personal Access Token", text: $viewModel.token)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isValidating)
                }

                Section {
                    Button("Validate & Save") {
                        Task {
                            await viewModel.validateAndSave()
                        }
                    }
                    .disabled(viewModel.username.isEmpty || viewModel.token.isEmpty || viewModel.isValidating)

                    Button("Clear") {
                        Task {
                            await viewModel.clear()
                        }
                    }
                    .disabled(viewModel.isValidating)
                    .foregroundColor(.red)
                }

                if viewModel.isValidating {
                    Section {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating credentials...")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                if viewModel.isSaved {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Credentials saved successfully")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    SettingsView()
}
