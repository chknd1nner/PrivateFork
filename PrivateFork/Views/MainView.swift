import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 20) {
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Repository URL")
                    .font(.headline)
                    .fontWeight(.medium)

                TextField("https://github.com/owner/repository", text: $viewModel.repoURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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

            Spacer()
        }
        .frame(width: 500, height: 400)
        .padding()
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView()
        }
    }
}
