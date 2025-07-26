import Foundation

// MARK: - GitHub Device Flow Models

// MARK: Request Models (Encodable)

/// Request body for initiating GitHub OAuth device flow
struct GitHubDeviceCodeRequest: Encodable {
    let clientId: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case scope
    }
}

/// Request body for polling GitHub OAuth device flow token endpoint
struct GitHubTokenPollingRequest: Encodable {
    let clientId: String
    let deviceCode: String
    let grantType: String
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case deviceCode = "device_code"
        case grantType = "grant_type"
    }
    
    init(clientId: String, deviceCode: String) {
        self.clientId = clientId
        self.deviceCode = deviceCode
        self.grantType = "urn:ietf:params:oauth:grant-type:device_code"
    }
}

// MARK: Response Models (Decodable)

/// Response from GitHub device code initiation endpoint
struct GitHubDeviceCodeResponse: Codable {
    let deviceCode: String
    let userCode: String
    let verificationUri: String
    let expiresIn: Int
    let interval: Int
    
    enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}

/// Response from successful GitHub OAuth token exchange
struct GitHubAccessTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}

/// Error response from GitHub OAuth device flow token polling
struct GitHubTokenPollingErrorResponse: Codable {
    let error: String
    let errorDescription: String?
    let errorUri: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorUri = "error_uri"
    }
}


// MARK: - GitHub User Model
struct GitHubUser: Codable {
    let login: String
    let id: Int
    let name: String?
    let email: String?
    let company: String?
    let location: String?
    let bio: String?
    let publicRepos: Int
    let privateRepos: Int
    let totalPrivateRepos: Int
    let plan: GitHubPlan?

    enum CodingKeys: String, CodingKey {
        case login, id, name, email, company, location, bio
        case publicRepos = "public_repos"
        case privateRepos = "owned_private_repos"
        case totalPrivateRepos = "total_private_repos"
        case plan
    }
}

// MARK: - GitHub Plan Model
struct GitHubPlan: Codable {
    let name: String
    let space: Int
    let collaborators: Int
    let privateRepos: Int

    enum CodingKeys: String, CodingKey {
        case name, space, collaborators
        case privateRepos = "private_repos"
    }
}

// MARK: - GitHub Repository Model
struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let fullName: String
    let description: String?
    let isPrivate: Bool
    let htmlUrl: String
    let cloneUrl: String
    let sshUrl: String
    let createdAt: String
    let updatedAt: String
    let pushedAt: String?
    let size: Int
    let language: String?
    let owner: GitHubOwner

    enum CodingKeys: String, CodingKey {
        case id, name, description, size, language, owner
        case fullName = "full_name"
        case isPrivate = "private"
        case htmlUrl = "html_url"
        case cloneUrl = "clone_url"
        case sshUrl = "ssh_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pushedAt = "pushed_at"
    }
}

// MARK: - GitHub Owner Model
struct GitHubOwner: Codable {
    let login: String
    let id: Int
    let type: String
}

// MARK: - GitHub API Error Model
struct GitHubAPIError: Codable {
    let message: String
    let documentationUrl: String?
    let errors: [GitHubFieldError]?

    enum CodingKeys: String, CodingKey {
        case message, errors
        case documentationUrl = "documentation_url"
    }
}

// MARK: - GitHub Field Error Model
struct GitHubFieldError: Codable {
    let resource: String?
    let code: String
    let field: String?
    let message: String?
}

// MARK: - GitHub Repository Request Model
struct GitHubRepositoryRequest: Codable {
    let name: String
    let description: String?
    let isPrivate: Bool
    let hasIssues: Bool
    let hasProjects: Bool
    let hasWiki: Bool
    let autoInit: Bool

    enum CodingKeys: String, CodingKey {
        case name, description
        case isPrivate = "private"
        case hasIssues = "has_issues"
        case hasProjects = "has_projects"
        case hasWiki = "has_wiki"
        case autoInit = "auto_init"
    }
    
    // Custom encoding to include null values explicitly
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(hasIssues, forKey: .hasIssues)
        try container.encode(hasProjects, forKey: .hasProjects)
        try container.encode(hasWiki, forKey: .hasWiki)
        try container.encode(autoInit, forKey: .autoInit)
    }
}

// MARK: - GitHub Credentials Model
struct GitHubCredentials {
    let oAuthToken: String

    var authorizationHeader: String {
        "Bearer \(oAuthToken)"
    }
}

// MARK: - GitHub Service Error Types
enum GitHubServiceError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case credentialsNotFound
    case authenticationFailed
    case insufficientPermissions
    case repositoryNameConflict(String)
    case rateLimited(retryAfter: Date?)
    case networkError(Error)
    case invalidResponse
    case repositoryNotFound
    case invalidRepositoryName
    case apiError(GitHubAPIError)
    case unexpectedError(String)
    
    // MARK: - Device Flow Specific Errors
    case deviceFlowInitiationFailed
    case deviceFlowAuthorizationPending
    case deviceFlowSlowDown
    case deviceFlowExpired
    case deviceFlowAccessDenied
    case deviceFlowPollingTimeout
    case deviceFlowUnexpectedResponse

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid GitHub credentials provided"
        case .credentialsNotFound:
            return "GitHub credentials not found in Keychain"
        case .authenticationFailed:
            return "GitHub authentication failed. Please check your Personal Access Token"
        case .insufficientPermissions:
            return "Insufficient permissions. Please ensure your Personal Access Token has 'repo' scope"
        case .repositoryNameConflict(let name):
            return "Repository '\(name)' already exists"
        case .rateLimited(let retryAfter):
            let retryMessage = retryAfter?.timeIntervalSinceNow.formatted() ?? "later"
            return "GitHub API rate limit exceeded. Please retry \(retryMessage)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from GitHub API"
        case .repositoryNotFound:
            return "Repository not found"
        case .invalidRepositoryName:
            return "Invalid repository name provided"
        case .apiError(let apiError):
            return "GitHub API error: \(apiError.message)"
        case .unexpectedError(let message):
            return "Unexpected error: \(message)"
        
        // MARK: - Device Flow Error Descriptions
        case .deviceFlowInitiationFailed:
            return "Failed to initiate GitHub device flow authentication"
        case .deviceFlowAuthorizationPending:
            return "GitHub device flow authorization is still pending"
        case .deviceFlowSlowDown:
            return "Device flow polling rate limit exceeded"
        case .deviceFlowExpired:
            return "GitHub device flow session has expired"
        case .deviceFlowAccessDenied:
            return "User denied access during GitHub device flow"
        case .deviceFlowPollingTimeout:
            return "GitHub device flow polling timed out"
        case .deviceFlowUnexpectedResponse:
            return "Unexpected response from GitHub device flow API"
        }
    }

    // MARK: - Equatable Implementation

    static func == (lhs: GitHubServiceError, rhs: GitHubServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidCredentials, .invalidCredentials),
             (.credentialsNotFound, .credentialsNotFound),
             (.authenticationFailed, .authenticationFailed),
             (.insufficientPermissions, .insufficientPermissions),
             (.invalidResponse, .invalidResponse),
             (.repositoryNotFound, .repositoryNotFound),
             (.invalidRepositoryName, .invalidRepositoryName),
             (.deviceFlowInitiationFailed, .deviceFlowInitiationFailed),
             (.deviceFlowAuthorizationPending, .deviceFlowAuthorizationPending),
             (.deviceFlowSlowDown, .deviceFlowSlowDown),
             (.deviceFlowExpired, .deviceFlowExpired),
             (.deviceFlowAccessDenied, .deviceFlowAccessDenied),
             (.deviceFlowPollingTimeout, .deviceFlowPollingTimeout),
             (.deviceFlowUnexpectedResponse, .deviceFlowUnexpectedResponse):
            return true
        case (.repositoryNameConflict(let name1), .repositoryNameConflict(let name2)):
            return name1 == name2
        case (.rateLimited(let date1), .rateLimited(let date2)):
            return date1 == date2
        case (.networkError(let error1), .networkError(let error2)):
            return (error1 as NSError).domain == (error2 as NSError).domain &&
                   (error1 as NSError).code == (error2 as NSError).code
        case (.apiError(let apiError1), .apiError(let apiError2)):
            return apiError1.message == apiError2.message
        case (.unexpectedError(let message1), .unexpectedError(let message2)):
            return message1 == message2
        default:
            return false
        }
    }
}

