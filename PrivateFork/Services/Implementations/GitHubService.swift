import Foundation
import OAuthSwift

class GitHubService: GitHubServiceProtocol {
    private let keychainService: KeychainServiceProtocol
    private let urlSession: URLSession
    private let baseURL: URL
    private let oauthswift: OAuth2Swift
    private let clientId: String

    // MARK: - Initialization

    init(keychainService: KeychainServiceProtocol, urlSession: URLSession = .shared, baseURL: URL = URL(string: "https://api.github.com")!, clientId: String = "Ov23liJgSwc0an0X22QL") {
        self.keychainService = keychainService
        self.urlSession = urlSession
        self.baseURL = baseURL
        self.clientId = clientId
        
        // Configure OAuthSwift for GitHub (for general OAuth functionality)
        self.oauthswift = OAuth2Swift(
            consumerKey: clientId,
            consumerSecret: "", // Device flow for public clients must not use a secret
            authorizeUrl: "https://github.com/login/oauth/authorize",
            accessTokenUrl: "https://github.com/login/oauth/access_token",
            responseType: "code"
        )
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

    // MARK: - OAuth Device Flow Methods
    
    /// Initiates the GitHub OAuth 2.0 device flow
    /// - Returns: A result containing device flow response data on success or GitHubServiceError on failure
    func initiateDeviceFlow() async -> Result<GitHubDeviceCodeResponse, GitHubServiceError> {
        let deviceCodeURL = "https://github.com/login/device/code"
        
        guard let url = URL(string: deviceCodeURL) else {
            return .failure(.deviceFlowInitiationFailed)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = GitHubDeviceCodeRequest(clientId: clientId, scope: "repo user")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(requestBody)
        } catch {
            return .failure(.deviceFlowInitiationFailed)
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.deviceFlowInitiationFailed)
            }
            
            guard httpResponse.statusCode == 200 else {
                return .failure(.deviceFlowInitiationFailed)
            }
            
            let decoder = JSONDecoder()
            let deviceResponse = try decoder.decode(GitHubDeviceCodeResponse.self, from: data)
            return .success(deviceResponse)
            
        } catch {
            return .failure(.deviceFlowInitiationFailed)
        }
    }
    
    /// Polls the GitHub OAuth token endpoint for device flow completion
    /// - Parameters:
    ///   - deviceCode: The device code from initiation response
    ///   - interval: Polling interval in seconds
    ///   - expiresIn: Expiration time in seconds
    /// - Returns: A result containing success or GitHubServiceError on failure
    func pollForAccessToken(deviceCode: String, interval: Int, expiresIn: Int) async -> Result<Void, GitHubServiceError> {
        let tokenURL = "https://github.com/login/oauth/access_token"
        let startTime = Date()
        var pollingInterval = TimeInterval(interval)
        
        guard let url = URL(string: tokenURL) else {
            return .failure(.deviceFlowUnexpectedResponse)
        }
        
        while Date().timeIntervalSince(startTime) < TimeInterval(expiresIn) {
            // Wait for the specified interval before making the next request
            try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody = GitHubTokenPollingRequest(clientId: clientId, deviceCode: deviceCode)
            
            do {
                let encoder = JSONEncoder()
                request.httpBody = try encoder.encode(requestBody)
            } catch {
                return .failure(.deviceFlowUnexpectedResponse)
            }
            
            do {
                let (data, response) = try await urlSession.data(for: request)
                let decoder = JSONDecoder()
                
                // First, try to decode a success response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200,
                   let tokenResponse = try? decoder.decode(GitHubAccessTokenResponse.self, from: data) {
                    
                    // Success! Store the token and inject it into OAuthSwift
                    let authToken = AuthToken(
                        accessToken: tokenResponse.accessToken,
                        refreshToken: "", // GitHub device flow doesn't provide refresh tokens
                        expiresIn: Date(timeIntervalSinceNow: TimeInterval(8 * 3600)) // GitHub tokens expire in 8 hours
                    )
                    
                    // Save to keychain
                    let saveResult = await keychainService.saveOAuthTokens(
                        accessToken: authToken.accessToken,
                        refreshToken: authToken.refreshToken,
                        expiresIn: authToken.expiresIn
                    )
                    
                    switch saveResult {
                    case .success:
                        // Inject token into OAuthSwift for future API calls
                        oauthswift.client.credential.oauthToken = tokenResponse.accessToken
                        oauthswift.client.credential.oauthRefreshToken = ""
                        oauthswift.client.credential.oauthTokenExpiresAt = authToken.expiresIn
                        return .success(())
                    case .failure:
                        return .failure(.unexpectedError("Failed to save OAuth tokens to keychain"))
                    }
                }
                
                // If that fails, try to decode a known error response
                if let errorResponse = try? decoder.decode(GitHubTokenPollingErrorResponse.self, from: data) {
                    switch errorResponse.error {
                    case "authorization_pending":
                        continue // This is expected, keep polling
                    case "slow_down":
                        pollingInterval += 5.0 // Increase interval and keep polling
                        continue
                    case "expired_token":
                        return .failure(.deviceFlowExpired)
                    case "access_denied":
                        return .failure(.deviceFlowAccessDenied)
                    default:
                        return .failure(.deviceFlowUnexpectedResponse)
                    }
                }
                
                // If neither success nor a known error could be decoded, the response is unexpected
                return .failure(.deviceFlowUnexpectedResponse)
                
            } catch {
                return .failure(.networkError(error))
            }
        }
        
        // If the while loop finishes, it means the expires_in time was exceeded
        return .failure(.deviceFlowPollingTimeout)
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
        let result = await keychainService.retrieveOAuthTokens()
        switch result {
        case .success(let authToken):
            return .success(GitHubCredentials(oAuthToken: authToken.accessToken))
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
