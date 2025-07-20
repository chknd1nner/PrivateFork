import Foundation

@MainActor
class PrivateForkOrchestrator: PrivateForkOrchestratorProtocol {
    private let keychainService: KeychainServiceProtocol
    private let gitHubService: GitHubServiceProtocol
    private let gitService: GitServiceProtocol
    
    // MARK: - Initialization
    
    init(
        keychainService: KeychainServiceProtocol,
        gitHubService: GitHubServiceProtocol,
        gitService: GitServiceProtocol
    ) {
        self.keychainService = keychainService
        self.gitHubService = gitHubService
        self.gitService = gitService
    }
    
    // MARK: - Public Methods
    
    func createPrivateFork(
        repositoryURL: String,
        localPath: String,
        statusCallback: @escaping (String) -> Void
    ) async -> Result<String, PrivateForkError> {
        
        // Parse repository information from URL
        guard let repoInfo = parseRepositoryURL(repositoryURL) else {
            return .failure(.invalidRepositoryURL)
        }
        
        // Validate local path
        guard isValidLocalPath(localPath) else {
            return .failure(.invalidLocalPath)
        }
        
        let privateRepoName = "\(repoInfo.owner)-\(repoInfo.repo)-private"
        var createdPrivateRepo: GitHubRepository?
        
        do {
            // Step 1: Validate credentials
            statusCallback("Validating GitHub credentials...")
            let credentials = try await validateCredentials()
            
            // Step 2: Create private repository
            statusCallback("Creating private repository '\(privateRepoName)'...")
            createdPrivateRepo = try await createPrivateRepository(
                name: privateRepoName,
                description: "Private fork of \(repoInfo.owner)/\(repoInfo.repo)"
            )
            
            // Step 3: Clone original repository
            statusCallback("Cloning original repository...")
            let clonePath = try await cloneRepository(
                from: repositoryURL,
                to: localPath,
                statusCallback: statusCallback
            )
            
            // Step 4: Configure remotes and push
            statusCallback("Configuring remotes...")
            try await configureRemotes(
                clonePath: clonePath,
                privateRepoURL: createdPrivateRepo!.cloneUrl,
                statusCallback: statusCallback
            )
            
            statusCallback("Pushing to private repository...")
            try await pushToPrivateRepository(
                clonePath: clonePath,
                statusCallback: statusCallback
            )
            
            return .success("Private fork created successfully! Repository: \(createdPrivateRepo!.htmlUrl)")
            
        } catch let error as PrivateForkError {
            // Handle cleanup if repository was created but subsequent steps failed
            if let privateRepo = createdPrivateRepo {
                statusCallback("Cleaning up failed operation...")
                await performCleanup(privateRepo: privateRepo)
            }
            return .failure(error)
            
        } catch {
            // Handle unexpected errors
            if let privateRepo = createdPrivateRepo {
                statusCallback("Cleaning up failed operation...")
                await performCleanup(privateRepo: privateRepo)
            }
            return .failure(.workflowInterrupted("Unexpected error: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Private Implementation Methods
    
    private func parseRepositoryURL(_ urlString: String) -> (owner: String, repo: String)? {
        guard let url = URL(string: urlString) else { return nil }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else { return nil }
        
        let owner = pathComponents[0]
        let repo = pathComponents[1].replacingOccurrences(of: ".git", with: "")
        
        guard !owner.isEmpty && !repo.isEmpty else { return nil }
        return (owner: owner, repo: repo)
    }
    
    private func isValidLocalPath(_ path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let parentDirectory = url.deletingLastPathComponent()
        return FileManager.default.fileExists(atPath: parentDirectory.path)
    }
    
    private func validateCredentials() async throws -> GitHubCredentials {
        let result = await keychainService.retrieve()
        switch result {
        case .success(let (username, token)):
            // Validate credentials with GitHub API
            let validationResult = await gitHubService.validateCredentials()
            switch validationResult {
            case .success:
                return GitHubCredentials(username: username, personalAccessToken: token)
            case .failure(let error):
                throw PrivateForkError.credentialValidationFailed(KeychainError.unhandledError(status: -1))
            }
        case .failure(let keychainError):
            throw PrivateForkError.credentialValidationFailed(keychainError)
        }
    }
    
    private func createPrivateRepository(name: String, description: String) async throws -> GitHubRepository {
        let result = await gitHubService.createPrivateRepository(name: name, description: description)
        switch result {
        case .success(let repository):
            return repository
        case .failure(let error):
            throw PrivateForkError.repositoryCreationFailed(error)
        }
    }
    
    private func cloneRepository(
        from repositoryURL: String,
        to localPath: String,
        statusCallback: @escaping (String) -> Void
    ) async throws -> URL {
        guard let repoURL = URL(string: repositoryURL) else {
            throw PrivateForkError.invalidRepositoryURL
        }
        
        let clonePath = URL(fileURLWithPath: localPath)
        
        // Provide granular status updates during clone
        statusCallback("Initializing clone operation...")
        
        let result = await gitService.clone(repoURL: repoURL, to: clonePath)
        switch result {
        case .success:
            statusCallback("Repository cloned successfully")
            return clonePath
        case .failure(let error):
            throw PrivateForkError.gitOperationFailed(error)
        }
    }
    
    private func configureRemotes(
        clonePath: URL,
        privateRepoURL: String,
        statusCallback: @escaping (String) -> Void
    ) async throws {
        guard let privateURL = URL(string: privateRepoURL) else {
            throw PrivateForkError.gitOperationFailed(GitServiceError.invalidURL(privateRepoURL))
        }
        
        // Add private repository as 'private' remote
        statusCallback("Adding private remote...")
        let addRemoteResult = await gitService.addRemote(name: "private", url: privateURL, at: clonePath)
        switch addRemoteResult {
        case .success:
            statusCallback("Private remote configured")
        case .failure(let error):
            throw PrivateForkError.gitOperationFailed(error)
        }
    }
    
    private func pushToPrivateRepository(
        clonePath: URL,
        statusCallback: @escaping (String) -> Void
    ) async throws {
        statusCallback("Pushing all branches to private repository...")
        
        // Push all branches to private remote
        let pushResult = await gitService.push(remoteName: "private", branch: "--all", at: clonePath, force: false)
        switch pushResult {
        case .success:
            statusCallback("All branches pushed successfully")
            
            // Also push tags
            statusCallback("Pushing tags...")
            let pushTagsResult = await gitService.push(remoteName: "private", branch: "--tags", at: clonePath, force: false)
            switch pushTagsResult {
            case .success:
                statusCallback("Tags pushed successfully")
            case .failure(let error):
                // Tags push failure is not critical, log but continue
                statusCallback("Warning: Failed to push tags - \(error.localizedDescription)")
            }
            
        case .failure(let error):
            throw PrivateForkError.gitOperationFailed(error)
        }
    }
    
    private func performCleanup(privateRepo: GitHubRepository) async {
        // TODO: Implement cleanup logic to delete the created private repository
        // This would require adding a deleteRepository method to GitHubService
        // For now, we log the cleanup requirement
        print("⚠️ Cleanup required: Private repository '\(privateRepo.name)' was created but workflow failed")
        print("   Repository URL: \(privateRepo.htmlUrl)")
        print("   Manual cleanup may be required")
    }
}

