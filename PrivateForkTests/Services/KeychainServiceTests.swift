import XCTest
@testable import PrivateFork

final class KeychainServiceTests: XCTestCase {

    var keychainService: KeychainService!
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainService()
    }
    
    override func tearDown() {
        keychainService = nil
        super.tearDown()
    }
    
    private func cleanupTokens() async {
        _ = await keychainService.deleteOAuthTokens()
    }
    
    // MARK: - Save OAuth Tokens Tests
    
    func testSaveOAuthTokens_ValidTokens_ShouldSucceed() async {
        // Setup: Clean any existing tokens
        await cleanupTokens()
        
        // Given: Valid OAuth token data
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiresIn = Date().addingTimeInterval(3600) // 1 hour from now
        
        // When: Saving OAuth tokens
        let result = await keychainService.saveOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        
        // Then: Should succeed
        switch result {
        case .success:
            XCTAssertTrue(true, "Save operation should succeed")
        case .failure(let error):
            XCTFail("Save operation should not fail: \(error)")
        }
    }
    
    func testSaveOAuthTokens_OverwriteExisting_ShouldSucceed() async {
        // Given: Existing OAuth tokens
        let firstAccessToken = "first_access_token"
        let firstRefreshToken = "first_refresh_token"
        let firstExpiresIn = Date().addingTimeInterval(3600)
        
        _ = await keychainService.saveOAuthTokens(
            accessToken: firstAccessToken,
            refreshToken: firstRefreshToken,
            expiresIn: firstExpiresIn
        )
        
        // When: Saving new OAuth tokens (should overwrite)
        let secondAccessToken = "second_access_token"
        let secondRefreshToken = "second_refresh_token"
        let secondExpiresIn = Date().addingTimeInterval(7200)
        
        let result = await keychainService.saveOAuthTokens(
            accessToken: secondAccessToken,
            refreshToken: secondRefreshToken,
            expiresIn: secondExpiresIn
        )
        
        // Then: Should succeed and retrieve the new tokens
        switch result {
        case .success:
            let retrieveResult = await keychainService.retrieveOAuthTokens()
            switch retrieveResult {
            case .success(let authToken):
                XCTAssertEqual(authToken.accessToken, secondAccessToken)
                XCTAssertEqual(authToken.refreshToken, secondRefreshToken)
                XCTAssertEqual(authToken.expiresIn.timeIntervalSince1970, secondExpiresIn.timeIntervalSince1970, accuracy: 1.0)
            case .failure(let error):
                XCTFail("Retrieve after overwrite should succeed: \(error)")
            }
        case .failure(let error):
            XCTFail("Overwrite save operation should not fail: \(error)")
        }
    }
    
    // MARK: - Retrieve OAuth Tokens Tests
    
    func testRetrieveOAuthTokens_ExistingTokens_ShouldReturnTokens() async {
        // Given: Saved OAuth tokens
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiresIn = Date().addingTimeInterval(3600)
        
        _ = await keychainService.saveOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        
        // When: Retrieving OAuth tokens
        let result = await keychainService.retrieveOAuthTokens()
        
        // Then: Should return the correct tokens
        switch result {
        case .success(let authToken):
            XCTAssertEqual(authToken.accessToken, accessToken)
            XCTAssertEqual(authToken.refreshToken, refreshToken)
            XCTAssertEqual(authToken.expiresIn.timeIntervalSince1970, expiresIn.timeIntervalSince1970, accuracy: 1.0)
        case .failure(let error):
            XCTFail("Retrieve operation should not fail: \(error)")
        }
    }
    
    func testRetrieveOAuthTokens_NoTokens_ShouldReturnItemNotFound() async {
        // Setup: Clean any existing tokens
        await cleanupTokens()
        
        // Given: No saved OAuth tokens (clean state)
        
        // When: Retrieving OAuth tokens
        let result = await keychainService.retrieveOAuthTokens()
        
        // Then: Should return itemNotFound error
        switch result {
        case .success:
            XCTFail("Retrieve operation should fail when no tokens exist")
        case .failure(let error):
            XCTAssertEqual(error, KeychainError.itemNotFound)
        }
    }
    
    // MARK: - Delete OAuth Tokens Tests
    
    func testDeleteOAuthTokens_ExistingTokens_ShouldSucceed() async {
        // Given: Saved OAuth tokens
        let accessToken = "test_access_token"
        let refreshToken = "test_refresh_token"
        let expiresIn = Date().addingTimeInterval(3600)
        
        _ = await keychainService.saveOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        
        // When: Deleting OAuth tokens
        let result = await keychainService.deleteOAuthTokens()
        
        // Then: Should succeed and tokens should no longer be retrievable
        switch result {
        case .success:
            let retrieveResult = await keychainService.retrieveOAuthTokens()
            switch retrieveResult {
            case .success:
                XCTFail("Retrieve after delete should fail")
            case .failure(let error):
                XCTAssertEqual(error, KeychainError.itemNotFound)
            }
        case .failure(let error):
            XCTFail("Delete operation should not fail: \(error)")
        }
    }
    
    func testDeleteOAuthTokens_NoTokens_ShouldSucceed() async {
        // Setup: Clean any existing tokens
        await cleanupTokens()
        
        // Given: No saved OAuth tokens (clean state)
        
        // When: Deleting OAuth tokens
        let result = await keychainService.deleteOAuthTokens()
        
        // Then: Should succeed (no-op deletion)
        switch result {
        case .success:
            XCTAssertTrue(true, "Delete operation should succeed even when no tokens exist")
        case .failure(let error):
            XCTFail("Delete operation should not fail when no tokens exist: \(error)")
        }
    }
    
    // MARK: - Token Expiration Handling Tests
    
    func testSaveAndRetrieveOAuthTokens_ExpiredToken_ShouldReturnCorrectDate() async {
        // Given: OAuth tokens with past expiration date
        let accessToken = "expired_access_token"
        let refreshToken = "expired_refresh_token"
        let expiresIn = Date().addingTimeInterval(-3600) // 1 hour ago (expired)
        
        _ = await keychainService.saveOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn
        )
        
        // When: Retrieving OAuth tokens
        let result = await keychainService.retrieveOAuthTokens()
        
        // Then: Should return the tokens with correct expiration date
        switch result {
        case .success(let authToken):
            XCTAssertEqual(authToken.accessToken, accessToken)
            XCTAssertEqual(authToken.refreshToken, refreshToken)
            XCTAssertEqual(authToken.expiresIn.timeIntervalSince1970, expiresIn.timeIntervalSince1970, accuracy: 1.0)
            XCTAssertTrue(authToken.expiresIn < Date(), "Token should be expired")
        case .failure(let error):
            XCTFail("Retrieve operation should not fail: \(error)")
        }
    }
    
    // MARK: - Secure Data Handling Tests
    
    func testAuthToken_ShouldNotExposeTokensInDescription() {
        // Given: AuthToken with sensitive data
        let accessToken = "secret_access_token"
        let refreshToken = "secret_refresh_token"
        let expiresIn = Date()
        
        let authToken = AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
        
        // When: Converting to string descriptions
        let description = authToken.description
        let debugDescription = authToken.debugDescription
        
        // Then: Should not contain sensitive token data
        XCTAssertFalse(description.contains(accessToken), "Description should not expose access token")
        XCTAssertFalse(description.contains(refreshToken), "Description should not expose refresh token")
        XCTAssertTrue(description.contains("[REDACTED]"), "Description should contain redacted placeholders")
        
        XCTAssertFalse(debugDescription.contains(accessToken), "Debug description should not expose access token")
        XCTAssertFalse(debugDescription.contains(refreshToken), "Debug description should not expose refresh token")
        XCTAssertTrue(debugDescription.contains("[REDACTED]"), "Debug description should contain redacted placeholders")
    }
    
    // MARK: - Error Handling Tests
    
    func testKeychainError_LocalizedDescriptions() {
        // Test that all KeychainError cases have proper localized descriptions
        let errors: [KeychainError] = [
            .itemNotFound,
            .duplicateItem,
            .invalidData,
            .unexpectedData,
            .unhandledError(status: -25291)
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "KeychainError should have localized description: \(error)")
            XCTAssertFalse(error.errorDescription!.isEmpty, "KeychainError description should not be empty: \(error)")
        }
    }
}