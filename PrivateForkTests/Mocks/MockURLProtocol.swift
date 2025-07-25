import Foundation
@testable import PrivateFork

class MockURLProtocol: URLProtocol {
    // Thread-safe storage for mock responses
    private static let queue = DispatchQueue(label: "MockURLProtocol.queue", attributes: .concurrent)
    private static var _mockResponses: [String: MockResponse] = [:]

    struct MockResponse {
        let data: Data
        let statusCode: Int
        let headers: [String: String]
        let error: Error?

        init(data: Data, statusCode: Int, headers: [String: String] = [:], error: Error? = nil) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
            self.error = error
        }
    }

    // MARK: - Public Interface

    static func setMockResponse(for url: String, response: MockResponse) {
        queue.async(flags: .barrier) {
            _mockResponses[url] = response
        }
    }

    static func setMockResponse(for url: String, data: Data, statusCode: Int, headers: [String: String] = [:]) {
        let response = MockResponse(data: data, statusCode: statusCode, headers: headers)
        setMockResponse(for: url, response: response)
    }

    static func setMockError(for url: String, error: Error) {
        let response = MockResponse(data: Data(), statusCode: 500, error: error)
        setMockResponse(for: url, response: response)
    }

    static func clearMockResponses() {
        queue.async(flags: .barrier) {
            _mockResponses.removeAll()
        }
    }

    static func getMockResponse(for url: String) -> MockResponse? {
        return queue.sync {
            return _mockResponses[url]
        }
    }

    // MARK: - URLProtocol Implementation

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url?.absoluteString else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        // Look for exact URL match first
        var mockResponse = MockURLProtocol.getMockResponse(for: url)

        // If no exact match, try to find a match based on path and method
        if mockResponse == nil {
            let path = request.url?.path ?? ""
            let method = request.httpMethod ?? "GET"
            let key = "\(method) \(path)"
            mockResponse = MockURLProtocol.getMockResponse(for: key)
        }

        guard let response = mockResponse else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock response configured for URL: \(url)"]))
            return
        }

        // If there's an error, return it
        if let error = response.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        // Create HTTP response
        guard let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        ) else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create HTTP response"]))
            return
        }

        // Send the response
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // Nothing to do here
    }
}

// MARK: - Helper Extensions for Testing

extension MockURLProtocol {
    static func mockSuccessfulUser() -> Data {
        let user = GitHubUser(
            login: "testuser",
            id: 12345,
            name: "Test User",
            email: "test@example.com",
            company: "Test Company",
            location: "Test Location",
            bio: "Test bio",
            publicRepos: 5,
            privateRepos: 2,
            totalPrivateRepos: 2,
            plan: GitHubPlan(
                name: "pro",
                space: 976562499,
                collaborators: 0,
                privateRepos: 9999
            )
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            return try encoder.encode(user)
        } catch {
            fatalError("Failed to encode mock User object: \(error)")
        }
    }

    static func mockSuccessfulRepository(name: String, description: String? = nil) -> Data {
        let repo = GitHubRepository(
            id: 67890,
            name: name,
            fullName: "testuser/\(name)",
            description: description,
            isPrivate: true,
            htmlUrl: "https://github.com/testuser/\(name)",
            cloneUrl: "https://github.com/testuser/\(name).git",
            sshUrl: "git@github.com:testuser/\(name).git",
            createdAt: "2023-01-01T00:00:00Z",
            updatedAt: "2023-01-01T00:00:00Z",
            pushedAt: "2023-01-01T00:00:00Z",
            size: 0,
            language: "Swift",
            owner: GitHubOwner(login: "testuser", id: 12345, type: "User")
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            return try encoder.encode(repo)
        } catch {
            fatalError("Failed to encode mock Repository object: \(error)")
        }
    }

    static func mockAPIError(message: String = "Test error") -> Data {
        let error = GitHubAPIError(
            message: message,
            documentationUrl: "https://docs.github.com/rest",
            errors: nil
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            return try encoder.encode(error)
        } catch {
            fatalError("Failed to encode mock API Error object: \(error)")
        }
    }

    static func mockNameConflictError(name: String) -> Data {
        let error = GitHubAPIError(
            message: "Repository creation failed.",
            documentationUrl: "https://docs.github.com/rest/reference/repos#create-a-repository-for-the-authenticated-user",
            errors: [
                GitHubFieldError(
                    resource: "Repository",
                    code: "already_exists",
                    field: "name",
                    message: "name already exists on this account"
                )
            ]
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            return try encoder.encode(error)
        } catch {
            fatalError("Failed to encode mock Name Conflict Error object: \(error)")
        }
    }
}

// MARK: - Test Configuration Helper

extension URLSession {
    static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}
