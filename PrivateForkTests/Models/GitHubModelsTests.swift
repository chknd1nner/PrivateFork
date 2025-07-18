import XCTest
@testable import PrivateFork

final class GitHubModelsTests: XCTestCase {

    // MARK: - GitHubUser Tests

    func testGitHubUser_Decoding_ShouldDecodeCorrectly() {
        // Given: Valid GitHub user JSON
        let json = """
        {
            "login": "testuser",
            "id": 12345,
            "name": "Test User",
            "email": "test@example.com",
            "company": "Test Company",
            "location": "Test Location",
            "bio": "Test bio",
            "public_repos": 10,
            "owned_private_repos": 5,
            "total_private_repos": 5,
            "plan": {
                "name": "pro",
                "space": 976562499,
                "collaborators": 0,
                "private_repos": 9999
            }
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let user = try decoder.decode(GitHubUser.self, from: data)

            // Then: Should decode all fields correctly
            XCTAssertEqual(user.login, "testuser")
            XCTAssertEqual(user.id, 12345)
            XCTAssertEqual(user.name, "Test User")
            XCTAssertEqual(user.email, "test@example.com")
            XCTAssertEqual(user.company, "Test Company")
            XCTAssertEqual(user.location, "Test Location")
            XCTAssertEqual(user.bio, "Test bio")
            XCTAssertEqual(user.publicRepos, 10)
            XCTAssertEqual(user.privateRepos, 5)
            XCTAssertEqual(user.totalPrivateRepos, 5)
            XCTAssertNotNil(user.plan)
            XCTAssertEqual(user.plan?.name, "pro")
            XCTAssertEqual(user.plan?.space, 976562499)
            XCTAssertEqual(user.plan?.collaborators, 0)
            XCTAssertEqual(user.plan?.privateRepos, 9999)
        } catch {
            XCTFail("Failed to decode GitHubUser: \(error)")
        }
    }

    func testGitHubUser_DecodingWithNullValues_ShouldDecodeCorrectly() {
        // Given: GitHub user JSON with null values
        let json = """
        {
            "login": "testuser",
            "id": 12345,
            "name": null,
            "email": null,
            "company": null,
            "location": null,
            "bio": null,
            "public_repos": 10,
            "owned_private_repos": 5,
            "total_private_repos": 5,
            "plan": null
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let user = try decoder.decode(GitHubUser.self, from: data)

            // Then: Should decode correctly with nil values
            XCTAssertEqual(user.login, "testuser")
            XCTAssertEqual(user.id, 12345)
            XCTAssertNil(user.name)
            XCTAssertNil(user.email)
            XCTAssertNil(user.company)
            XCTAssertNil(user.location)
            XCTAssertNil(user.bio)
            XCTAssertEqual(user.publicRepos, 10)
            XCTAssertEqual(user.privateRepos, 5)
            XCTAssertEqual(user.totalPrivateRepos, 5)
            XCTAssertNil(user.plan)
        } catch {
            XCTFail("Failed to decode GitHubUser with null values: \(error)")
        }
    }

    // MARK: - GitHubRepository Tests

    func testGitHubRepository_Decoding_ShouldDecodeCorrectly() {
        // Given: Valid GitHub repository JSON
        let json = """
        {
            "id": 67890,
            "name": "test-repo",
            "full_name": "testuser/test-repo",
            "description": "Test repository",
            "private": true,
            "html_url": "https://github.com/testuser/test-repo",
            "clone_url": "https://github.com/testuser/test-repo.git",
            "ssh_url": "git@github.com:testuser/test-repo.git",
            "created_at": "2023-01-01T00:00:00Z",
            "updated_at": "2023-01-01T00:00:00Z",
            "pushed_at": "2023-01-01T00:00:00Z",
            "size": 1024,
            "language": "Swift",
            "owner": {
                "login": "testuser",
                "id": 12345,
                "type": "User"
            }
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let repo = try decoder.decode(GitHubRepository.self, from: data)

            // Then: Should decode all fields correctly
            XCTAssertEqual(repo.id, 67890)
            XCTAssertEqual(repo.name, "test-repo")
            XCTAssertEqual(repo.fullName, "testuser/test-repo")
            XCTAssertEqual(repo.description, "Test repository")
            XCTAssertTrue(repo.isPrivate)
            XCTAssertEqual(repo.htmlUrl, "https://github.com/testuser/test-repo")
            XCTAssertEqual(repo.cloneUrl, "https://github.com/testuser/test-repo.git")
            XCTAssertEqual(repo.sshUrl, "git@github.com:testuser/test-repo.git")
            XCTAssertEqual(repo.createdAt, "2023-01-01T00:00:00Z")
            XCTAssertEqual(repo.updatedAt, "2023-01-01T00:00:00Z")
            XCTAssertEqual(repo.pushedAt, "2023-01-01T00:00:00Z")
            XCTAssertEqual(repo.size, 1024)
            XCTAssertEqual(repo.language, "Swift")
            XCTAssertEqual(repo.owner.login, "testuser")
            XCTAssertEqual(repo.owner.id, 12345)
            XCTAssertEqual(repo.owner.type, "User")
        } catch {
            XCTFail("Failed to decode GitHubRepository: \(error)")
        }
    }

    func testGitHubRepository_DecodingWithNullValues_ShouldDecodeCorrectly() {
        // Given: GitHub repository JSON with null values
        let json = """
        {
            "id": 67890,
            "name": "test-repo",
            "full_name": "testuser/test-repo",
            "description": null,
            "private": false,
            "html_url": "https://github.com/testuser/test-repo",
            "clone_url": "https://github.com/testuser/test-repo.git",
            "ssh_url": "git@github.com:testuser/test-repo.git",
            "created_at": "2023-01-01T00:00:00Z",
            "updated_at": "2023-01-01T00:00:00Z",
            "pushed_at": null,
            "size": 0,
            "language": null,
            "owner": {
                "login": "testuser",
                "id": 12345,
                "type": "User"
            }
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let repo = try decoder.decode(GitHubRepository.self, from: data)

            // Then: Should decode correctly with nil values
            XCTAssertEqual(repo.id, 67890)
            XCTAssertEqual(repo.name, "test-repo")
            XCTAssertEqual(repo.fullName, "testuser/test-repo")
            XCTAssertNil(repo.description)
            XCTAssertFalse(repo.isPrivate)
            XCTAssertEqual(repo.htmlUrl, "https://github.com/testuser/test-repo")
            XCTAssertEqual(repo.cloneUrl, "https://github.com/testuser/test-repo.git")
            XCTAssertEqual(repo.sshUrl, "git@github.com:testuser/test-repo.git")
            XCTAssertEqual(repo.createdAt, "2023-01-01T00:00:00Z")
            XCTAssertEqual(repo.updatedAt, "2023-01-01T00:00:00Z")
            XCTAssertNil(repo.pushedAt)
            XCTAssertEqual(repo.size, 0)
            XCTAssertNil(repo.language)
        } catch {
            XCTFail("Failed to decode GitHubRepository with null values: \(error)")
        }
    }

    // MARK: - GitHubAPIError Tests

    func testGitHubAPIError_Decoding_ShouldDecodeCorrectly() {
        // Given: Valid GitHub API error JSON
        let json = """
        {
            "message": "Repository creation failed.",
            "documentation_url": "https://docs.github.com/rest/reference/repos#create-a-repository-for-the-authenticated-user",
            "errors": [
                {
                    "resource": "Repository",
                    "code": "already_exists",
                    "field": "name",
                    "message": "name already exists on this account"
                }
            ]
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let error = try decoder.decode(GitHubAPIError.self, from: data)

            // Then: Should decode all fields correctly
            XCTAssertEqual(error.message, "Repository creation failed.")
            XCTAssertEqual(error.documentationUrl, "https://docs.github.com/rest/reference/repos#create-a-repository-for-the-authenticated-user")
            XCTAssertNotNil(error.errors)
            XCTAssertEqual(error.errors?.count, 1)
            XCTAssertEqual(error.errors?[0].resource, "Repository")
            XCTAssertEqual(error.errors?[0].code, "already_exists")
            XCTAssertEqual(error.errors?[0].field, "name")
            XCTAssertEqual(error.errors?[0].message, "name already exists on this account")
        } catch {
            XCTFail("Failed to decode GitHubAPIError: \(error)")
        }
    }

    func testGitHubAPIError_SimpleError_ShouldDecodeCorrectly() {
        // Given: Simple GitHub API error JSON
        let json = """
        {
            "message": "Bad credentials"
        }
        """

        // When: Decoding the JSON
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        do {
            let error = try decoder.decode(GitHubAPIError.self, from: data)

            // Then: Should decode correctly with minimal fields
            XCTAssertEqual(error.message, "Bad credentials")
            XCTAssertNil(error.documentationUrl)
            XCTAssertNil(error.errors)
        } catch {
            XCTFail("Failed to decode simple GitHubAPIError: \(error)")
        }
    }

    // MARK: - GitHubRepositoryRequest Tests

    func testGitHubRepositoryRequest_Encoding_ShouldEncodeCorrectly() {
        // Given: Repository request
        let request = GitHubRepositoryRequest(
            name: "test-repo",
            description: "Test repository",
            isPrivate: true,
            hasIssues: true,
            hasProjects: false,
            hasWiki: false,
            autoInit: false
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()

        do {
            let data = try encoder.encode(request)
            let json = String(data: data, encoding: .utf8)!

            // Then: Should encode all fields correctly
            XCTAssertTrue(json.contains("\"name\":\"test-repo\""))
            XCTAssertTrue(json.contains("\"description\":\"Test repository\""))
            XCTAssertTrue(json.contains("\"private\":true"))
            XCTAssertTrue(json.contains("\"has_issues\":true"))
            XCTAssertTrue(json.contains("\"has_projects\":false"))
            XCTAssertTrue(json.contains("\"has_wiki\":false"))
            XCTAssertTrue(json.contains("\"auto_init\":false"))
        } catch {
            XCTFail("Failed to encode GitHubRepositoryRequest: \(error)")
        }
    }

    func testGitHubRepositoryRequest_EncodingWithNullDescription_ShouldEncodeCorrectly() {
        // Given: Repository request with null description
        let request = GitHubRepositoryRequest(
            name: "test-repo",
            description: nil,
            isPrivate: true,
            hasIssues: true,
            hasProjects: false,
            hasWiki: false,
            autoInit: false
        )

        // When: Encoding to JSON
        let encoder = JSONEncoder()

        do {
            let data = try encoder.encode(request)
            let json = String(data: data, encoding: .utf8)!

            // Then: Should encode correctly with null description
            XCTAssertTrue(json.contains("\"name\":\"test-repo\""))
            XCTAssertTrue(json.contains("\"description\":null"))
            XCTAssertTrue(json.contains("\"private\":true"))
        } catch {
            XCTFail("Failed to encode GitHubRepositoryRequest with null description: \(error)")
        }
    }

    // MARK: - GitHubCredentials Tests

    func testGitHubCredentials_AuthorizationHeader_ShouldFormatCorrectly() {
        // Given: GitHub credentials
        let credentials = GitHubCredentials(
            username: "testuser",
            personalAccessToken: "test_token_123"
        )

        // When: Getting authorization header
        let authHeader = credentials.authorizationHeader

        // Then: Should format correctly
        XCTAssertEqual(authHeader, "token test_token_123")
    }

    // MARK: - GitHubServiceError Tests

    func testGitHubServiceError_ErrorDescriptions_ShouldProvideUserFriendlyMessages() {
        // Given: Various GitHub service errors
        let errors: [GitHubServiceError] = [
            .invalidCredentials,
            .credentialsNotFound,
            .authenticationFailed,
            .insufficientPermissions,
            .repositoryNameConflict("test-repo"),
            .rateLimited(retryAfter: Date()),
            .networkError(NSError(domain: "TestError", code: -1)),
            .invalidResponse,
            .repositoryNotFound,
            .invalidRepositoryName,
            .apiError(GitHubAPIError(message: "Test API error", documentationUrl: nil, errors: nil)),
            .unexpectedError("Test unexpected error")
        ]

        // When: Getting error descriptions
        // Then: Should provide user-friendly messages
        XCTAssertEqual(errors[0].errorDescription, "Invalid GitHub credentials provided")
        XCTAssertEqual(errors[1].errorDescription, "GitHub credentials not found in Keychain")
        XCTAssertEqual(errors[2].errorDescription, "GitHub authentication failed. Please check your Personal Access Token")
        XCTAssertEqual(errors[3].errorDescription, "Insufficient permissions. Please ensure your Personal Access Token has 'repo' scope")
        XCTAssertEqual(errors[4].errorDescription, "Repository 'test-repo' already exists")
        XCTAssertTrue(errors[5].errorDescription?.contains("GitHub API rate limit exceeded") ?? false)
        XCTAssertTrue(errors[6].errorDescription?.contains("Network error") ?? false)
        XCTAssertEqual(errors[7].errorDescription, "Invalid response from GitHub API")
        XCTAssertEqual(errors[8].errorDescription, "Repository not found")
        XCTAssertEqual(errors[9].errorDescription, "Invalid repository name provided")
        XCTAssertEqual(errors[10].errorDescription, "GitHub API error: Test API error")
        XCTAssertEqual(errors[11].errorDescription, "Unexpected error: Test unexpected error")
    }

    func testGitHubServiceError_Equality_ShouldCompareCorrectly() {
        // Given: Similar errors
        let error1 = GitHubServiceError.invalidCredentials
        let error2 = GitHubServiceError.invalidCredentials
        let error3 = GitHubServiceError.authenticationFailed
        let error4 = GitHubServiceError.repositoryNameConflict("test-repo")
        let error5 = GitHubServiceError.repositoryNameConflict("test-repo")
        let error6 = GitHubServiceError.repositoryNameConflict("other-repo")

        // When: Comparing errors
        // Then: Should compare correctly
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
        XCTAssertEqual(error4, error5)
        XCTAssertNotEqual(error4, error6)
    }
}
