import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

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

            // Create Private Fork Button
            Button(action: {
                // TODO: Implement fork creation logic
            }) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Create Private Fork")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isCreateButtonEnabled)
            .padding(.horizontal)

            Spacer()
        }
        .frame(width: 500, height: 400)
        .padding()
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
    }
}
