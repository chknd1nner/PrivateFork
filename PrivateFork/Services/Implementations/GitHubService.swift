import Foundation

class GitHubService: GitHubServiceProtocol {
    private let keychainService: KeychainServiceProtocol
    private let urlSession: URLSession
    private let baseURL: URL

    // MARK: - Initialization

    init(keychainService: KeychainServiceProtocol, urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://api.github.com")!) {
        self.keychainService = keychainService
        self.urlSession = urlSession
        self.baseURL = baseURL
    }

    // MARK: - Public Methods

    func validateCredentials() async -> Result<GitHubUser, GitHubServiceError> {
        return await getCurrentUser()
    }

    func createPrivateRepository(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError> {
        guard !name.isEmpty, isValidRepositoryName(name) else {
            return .failure(.invalidRepositoryName)
        }

        // Validate repository doesn't already exist
        let validationResult = await validateRepositoryDoesNotExist(name: name)
        switch validationResult {
        case .success:
            break // Repository doesn't exist, continue with creation
        case .failure(let error):
            return .failure(error)
        }

        // Build and execute repository creation request
        return await executeRepositoryCreationRequest(name: name, description: description)
    }

    func getCurrentUser() async -> Result<GitHubUser, GitHubServiceError> {
        let url = baseURL.appendingPathComponent("user")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        // Get credentials and set authorization header
        let credentialsResult = await getCredentials()
        switch credentialsResult {
        case .success(let credentials):
            request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
        case .failure(let error):
            return .failure(error)
        }

        return await performRequest(request: request, responseType: GitHubUser.self)
    }

    func repositoryExists(name: String) async -> Result<Bool, GitHubServiceError> {
        // Get current user first to build the repository URL
        let userResult = await getCurrentUser()
        switch userResult {
        case .success(let user):
            let url = baseURL.appendingPathComponent("repos/\(user.login)/\(name)")
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

            // Get credentials and set authorization header
            let credentialsResult = await getCredentials()
            switch credentialsResult {
            case .success(let credentials):
                request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
            case .failure(let error):
                return .failure(error)
            }

            // Make the request
            do {
                let (_, response) = try await urlSession.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        return .success(true)
                    case 404:
                        return .success(false)
                    default:
                        let error = await handleHTTPError(response: httpResponse, data: Data())
                        return .failure(error)
                    }
                }

                return .failure(.invalidResponse)
            } catch {
                return .failure(.networkError(error))
            }

        case .failure(let error):
            return .failure(error)
        }
    }
    
    func deleteRepository(name: String) async -> Result<Void, GitHubServiceError> {
        guard !name.isEmpty, isValidRepositoryName(name) else {
            return .failure(.invalidRepositoryName)
        }
        
        // Get current user first to build the repository URL
        let userResult = await getCurrentUser()
        switch userResult {
        case .success(let user):
            let url = baseURL.appendingPathComponent("repos/\(user.login)/\(name)")
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            
            // Get credentials and set authorization header
            let credentialsResult = await getCredentials()
            switch credentialsResult {
            case .success(let credentials):
                request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
            case .failure(let error):
                return .failure(error)
            }
            
            // Make the request
            do {
                let (_, response) = try await urlSession.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 204:
                        return .success(())
                    case 404:
                        return .failure(.repositoryNotFound)
                    case 403:
                        return .failure(.insufficientPermissions)
                    default:
                        let error = await handleHTTPError(response: httpResponse, data: Data())
                        return .failure(error)
                    }
                }
                
                return .failure(.invalidResponse)
            } catch {
                return .failure(.networkError(error))
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Methods

    private func validateRepositoryDoesNotExist(name: String) async -> Result<Void, GitHubServiceError> {
        let existsResult = await repositoryExists(name: name)
        switch existsResult {
        case .success(let exists):
            if exists {
                return .failure(.repositoryNameConflict(name))
            }
            return .success(())
        case .failure(let error):
            // If we can't check existence, continue with creation attempt
            // This handles cases where the repository might be private and we can't see it
            if case .repositoryNotFound = error {
                // Repository doesn't exist, continue with creation
                return .success(())
            } else {
                return .failure(error)
            }
        }
    }

    private func executeRepositoryCreationRequest(name: String, description: String?) async -> Result<GitHubRepository, GitHubServiceError> {
        // Build repository creation request
        let repositoryRequest = buildRepositoryRequest(name: name, description: description)
        
        // Create URL request
        let url = baseURL.appendingPathComponent("user/repos")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        // Get credentials and set authorization header
        let credentialsResult = await getCredentials()
        switch credentialsResult {
        case .success(let credentials):
            request.setValue(credentials.authorizationHeader, forHTTPHeaderField: "Authorization")
        case .failure(let error):
            return .failure(error)
        }

        // Encode request body
        do {
            let jsonData = try JSONEncoder().encode(repositoryRequest)
            request.httpBody = jsonData
        } catch {
            return .failure(.unexpectedError("Failed to encode repository request: \(error.localizedDescription)"))
        }

        // Make the request
        return await performRequest(request: request, responseType: GitHubRepository.self)
    }

    private func buildRepositoryRequest(name: String, description: String?) -> GitHubRepositoryRequest {
        return GitHubRepositoryRequest(
            name: name,
            description: description,
            isPrivate: true,
            hasIssues: true,
            hasProjects: false,
            hasWiki: false,
            autoInit: false
        )
    }

    private func getCredentials() async -> Result<GitHubCredentials, GitHubServiceError> {
        let result = await keychainService.retrieve()
        switch result {
        case .success(let (username, token)):
            return .success(GitHubCredentials(username: username, personalAccessToken: token))
        case .failure(let keychainError):
            switch keychainError {
            case .itemNotFound:
                return .failure(.credentialsNotFound)
            case .invalidData, .unexpectedData:
                return .failure(.invalidCredentials)
            case .duplicateItem, .unhandledError:
                return .failure(.unexpectedError("Keychain error: \(keychainError.localizedDescription)"))
            }
        }
    }

    private func performRequest<T: Codable>(request: URLRequest, responseType: T.Type) async -> Result<T, GitHubServiceError> {
        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(responseType, from: data)
                    return .success(result)
                } catch {
                    return .failure(.invalidResponse)
                }
            default:
                let error = await handleHTTPError(response: httpResponse, data: data)
                return .failure(error)
            }
        } catch {
            return .failure(.networkError(error))
        }
    }

    private func handleHTTPError(response: HTTPURLResponse, data: Data) async -> GitHubServiceError {
        switch response.statusCode {
        case 401:
            return .authenticationFailed
        case 403:
            // Check if it's a rate limit error
            if let retryAfter = response.value(forHTTPHeaderField: "X-RateLimit-Reset") {
                let retryDate = parseRetryAfterHeader(retryAfter)
                return .rateLimited(retryAfter: retryDate)
            }
            return .insufficientPermissions
        case 404:
            return .repositoryNotFound
        case 422:
            // Parse the error response to get more details
            if let apiError = parseAPIError(data: data) {
                return .apiError(apiError)
            }
            return .invalidRepositoryName
        case 429:
            let retryAfter = response.value(forHTTPHeaderField: "Retry-After")
            let retryDate = retryAfter != nil ? parseRetryAfterHeader(retryAfter!) : nil
            return .rateLimited(retryAfter: retryDate)
        default:
            if let apiError = parseAPIError(data: data) {
                return .apiError(apiError)
            }
            return .unexpectedError("HTTP \(response.statusCode)")
        }
    }

    private func parseAPIError(data: Data) -> GitHubAPIError? {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(GitHubAPIError.self, from: data)
        } catch {
            return nil
        }
    }

    private func parseRetryAfterHeader(_ retryAfter: String) -> Date? {
        if let timestamp = TimeInterval(retryAfter) {
            return Date(timeIntervalSince1970: timestamp)
        }
        return nil
    }

    private func isValidRepositoryName(_ name: String) -> Bool {
        // GitHub repository name validation rules:
        // - Must be 1-100 characters
        // - Can contain alphanumeric characters, hyphens, underscores, and periods
        // - Cannot start or end with a period
        // - Cannot contain consecutive periods
        // - Cannot be empty

        let trimmed = name.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty && trimmed.count <= 100 else {
            return false
        }

        guard !trimmed.hasPrefix(".") && !trimmed.hasSuffix(".") else {
            return false
        }

        guard !trimmed.contains("..") else {
            return false
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return trimmed.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
}
