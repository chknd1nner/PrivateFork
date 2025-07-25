# Epic 2: Foundational OAuth 2.0 Integration

[cite_start]**Epic Goal**: To completely replace the existing PAT-based authentication with the secure and user-friendly GitHub OAuth 2.0 device flow, and to remove all legacy authentication code, providing a seamless one-time login experience for the user[cite: 107].

## Story 2.1: PAT Authentication Removal

[cite_start]**As a** developer, **I want** to remove the SettingsView, SettingsViewModel, and all related PAT authentication logic, **so that** the codebase is prepared for the new OAuth implementation without any legacy code[cite: 109].

### Acceptance Criteria

1.  [cite_start]The `SettingsView.swift` and `SettingsViewModel.swift` files are deleted from the project[cite: 111].
2.  [cite_start]All tests related to the `SettingsView` and `SettingsViewModel` are removed[cite: 112].
3.  [cite_start]The application compiles successfully after the removal of these components[cite: 113].
4.  [cite_start]The button on the `MainView` that previously opened the settings sheet is removed[cite: 114].

## Story 2.2: OAuth Credential Storage

[cite_start]**As a** developer, **I want** to update the `KeychainService` to securely store and retrieve the new OAuth access and refresh tokens, **so that** the application has a secure place to manage credentials[cite: 116].

### Acceptance Criteria

1.  [cite_start]The `KeychainService` is updated with new methods to save, load, and delete the OAuth access token and refresh token[cite: 118].
2.  [cite_start]The existing PAT-related methods in `KeychainService` are removed[cite: 119].
3.  [cite_start]The new methods are covered by unit tests to ensure correct interaction with the Keychain[cite: 120].
4.  [cite_start]All sensitive token data is handled securely and is never exposed in logs[cite: 121].

## Story 2.3: OAuth Service Implementation

[cite_start]**As a** developer, **I want** to implement the backend logic for the GitHub OAuth 2.0 device flow, **so that** the application can obtain an access token and refresh token from GitHub[cite: 123].

### Acceptance Criteria

1.  [cite_start]A new method is added to `GitHubService` to initiate the device flow and retrieve a user code and verification URI[cite: 125].
2.  [cite_start]A new method is added to `GitHubService` to poll GitHub and exchange the device code for an access token and refresh token[cite: 126].
3.  [cite_start]The new methods correctly handle all potential error states from the GitHub API (e.g., authorization pending, access denied, token expired)[cite: 127].
4.  [cite_start]The retrieved access and refresh tokens are securely passed to the updated `KeychainService` for storage[cite: 128].
5.  [cite_start]All new logic is covered by unit tests using mock network requests[cite: 129].

## Story 2.4: Main View UI for Authentication

[cite_start]**As a** user, **I want** a clear user interface on the main screen to sign in and out, **so that** I can easily manage my authentication state[cite: 131].

### Acceptance Criteria

1.  [cite_start]When not authenticated, the `MainView` displays a prominent "Sign in with GitHub" button[cite: 133].
2.  [cite_start]The repository URL and local path input fields are disabled when not authenticated[cite: 134].
3.  [cite_start]When authenticated, the `MainView` displays my GitHub username and a "Log Out" button[cite: 135].
4.  [cite_start]The `MainViewModel` is updated to manage the different UI states (unauthenticated, authenticating, authenticated)[cite: 136].
5.  [cite_start]Clicking the "Sign in with GitHub" button triggers the OAuth device flow process[cite: 137].
6.  [cite_start]Clicking the "Log Out" button clears all credentials from the Keychain and returns the UI to the unauthenticated state[cite: 138].

## Story 2.5: Application-level Integration

[cite_start]**As a** user, **I want** the application to remember my login status between launches, **so that** I only have to authenticate once[cite: 140].

### Acceptance Criteria

1.  [cite_start]The `PrivateForkOrchestrator` is updated to retrieve and use the OAuth token from the `KeychainService` for all GitHub API requests[cite: 142].
2.  [cite_start]On application launch, the app correctly checks the `KeychainService` for valid OAuth credentials[cite: 143].
3.  [cite_start]If valid credentials exist, the UI is initialized in the "Authenticated State"[cite: 144].
4.  [cite_start]If no valid credentials exist, the UI is initialized in the "Unauthenticated State"[cite: 145].