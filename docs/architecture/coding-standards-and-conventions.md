# Coding Standards and Conventions

## Existing Standards Compliance

-   [cite_start]**Code Style:** New code will follow the existing code style. [cite: 278]
-   [cite_start]**Linting Rules:** New code will adhere to the existing linting rules. [cite: 279]
-   [cite_start]**Testing Patterns:** New tests will follow the existing testing patterns. [cite: 280]
-   [cite_start]**Documentation Style:** New documentation will follow the existing documentation style. [cite: 281]

## Enhancement-Specific Standards

-   [cite_start]**SwiftGitX:** The `SwiftGitX` library will be used for all native Git operations. [cite: 283]
-   [cite_start]**OAuthSwift:** The `OAuthSwift` library will be used for the OAuth 2.0 flow. [cite: 284]
-   [cite_start]**ArgumentParser:** The `ArgumentParser` library will be used for the modernized CLI. [cite: 285]

## Critical Integration Rules

-   [cite_start]**Existing API Compatibility:** The `GitHubService` will be updated to use OAuth tokens without breaking the existing API. [cite: 287]
-   [cite_start]**Database Integration:** The `KeychainService` will be updated to store OAuth tokens, and a migration path for existing PATs will be provided. [cite: 288]
-   [cite_start]**Error Handling:** The new services will follow the existing error handling patterns. [cite: 289]
-   [cite_start]**Logging Consistency:** The new services will follow the existing logging patterns. [cite: 290]
