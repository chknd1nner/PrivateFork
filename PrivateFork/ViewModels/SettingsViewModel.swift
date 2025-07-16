import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var token: String = ""
    @Published var isValidating: Bool = false
    @Published var errorMessage: String?
    @Published var isSaved: Bool = false

    private let keychainService: KeychainServiceProtocol
    private let gitHubValidationService: GitHubValidationServiceProtocol

    init(
        keychainService: KeychainServiceProtocol = KeychainService(),
        gitHubValidationService: GitHubValidationServiceProtocol = GitHubValidationService()
    ) {
        self.keychainService = keychainService
        self.gitHubValidationService = gitHubValidationService

        Task {
            await loadExistingCredentials()
        }
    }

    func validateAndSave() async {
        clearMessages()
        isValidating = true

        do {
            // Validate credentials with GitHub API
            let validationResult = await gitHubValidationService.validateCredentials(
                username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                token: token.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            switch validationResult {
            case .success(let isValid):
                if isValid {
                    // Save to Keychain
                    let saveResult = await keychainService.save(
                        username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                        token: token.trimmingCharacters(in: .whitespacesAndNewlines)
                    )

                    switch saveResult {
                    case .success:
                        isSaved = true
                        errorMessage = nil
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = "Credential validation failed"
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }

        isValidating = false
    }

    func clear() async {
        clearMessages()

        let deleteResult = await keychainService.delete()
        switch deleteResult {
        case .success:
            username = ""
            token = ""
            isSaved = false
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func loadExistingCredentials() async {
        let retrieveResult = await keychainService.retrieve()
        switch retrieveResult {
        case .success(let credentials):
            username = credentials.username
            token = credentials.token
            isSaved = true
        case .failure:
            // No existing credentials, start with empty fields
            break
        }
    }

    private func clearMessages() {
        errorMessage = nil
        isSaved = false
    }
}
