# Requirements

## Functional

1.  [cite_start]**FR1**: The application's GUI must implement the full GitHub OAuth 2.0 device flow to authorize the user[cite: 39].
2.  [cite_start]**FR2**: Upon successful authorization, the application must securely store the OAuth token and a refresh token in the macOS Keychain[cite: 40].
3.  [cite_start]**FR3**: The CLI must be able to perform a fork and clone operation non-interactively, using the stored OAuth token for authentication[cite: 41].
4.  [cite_start]**FR4**: The existing GitService that shells out to the git command must be replaced with a new service that utilizes a native Swift Git library[cite: 42].
5.  [cite_start]**FR5**: All cloning operations, whether initiated from the GUI or CLI, must use the new native Git library service[cite: 43].
6.  [cite_start]**FR6**: The CLI must accept a source repository URL and a target local directory path as arguments[cite: 44].
7.  [cite_start]**FR7**: The application's main interface must provide a mechanism for the user to log out, which revokes and removes all stored OAuth credentials from the Keychain[cite: 45].
8.  [cite_start]**FR8**: The CLI invocation for Phase 2 will be strictly limited to the following command structure: `privatefork fork <repository-url> --path <local-directory-path>`[cite: 46]. [cite_start]No other commands or flags will be developed in this phase[cite: 47].

## Non Functional

1.  [cite_start]**NFR1**: The integration of a new native Git library should not increase the final application bundle size by more than 25%[cite: 49].
2.  [cite_start]**NFR2**: The user-facing OAuth authorization flow should feel responsive, with UI feedback provided for all network operations[cite: 50].
3.  [cite_start]**NFR3**: The performance of cloning a repository using the new native Git library must be comparable to or better than the existing shell-based implementation[cite: 51].
4.  [cite_start]**NFR4**: All sensitive credentials (OAuth tokens, refresh tokens) MUST be stored using the KeychainService and never in plain text files or user defaults[cite: 52].

## Compatibility Requirements

1.  [cite_start]**CR1**: The application's internal data models for repositories (Repository, Owner, etc.) must remain compatible with the GitHub API v3[cite: 54].
2.  [cite_start]**CR2**: The introduction of the native Git library must not break any existing unit or integration tests for other services[cite: 55].
