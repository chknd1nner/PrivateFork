# PrivateFork Brownfield Enhancement PRD

## Intro Project Analysis and Context

### Existing Project Overview

#### Analysis Source

[cite_start]This PRD is based on the comprehensive analysis of the existing MVP codebase documented in the PrivateFork Brownfield Architecture Document[cite: 5].

#### Current Project State

[cite_start]PrivateFork is a native macOS application built with Swift and SwiftUI[cite: 7]. [cite_start]It currently functions as a simple utility with a GUI and CLI to fork a public GitHub repository to a user's account and clone it locally[cite: 8]. [cite_start]Authentication is handled via a user-provided Personal Access Token (PAT), which is stored securely in the macOS Keychain[cite: 9]. [cite_start]The application's architecture is service-oriented, but it relies on shelling out to the system's git command for local operations, which is a significant piece of technical debt[cite: 10].

### Documentation Analysis

#### Available Documentation

[cite_start]The following documentation is available and has been used as a source for this PRD[cite: 13]:
- [x] [cite_start]Tech Stack Documentation [cite: 14]
- [x] [cite_start]Source Tree/Architecture [cite: 15]
- [x] [cite_start]API Documentation (inferred from code) [cite: 16]
- [x] [cite_start]Technical Debt Documentation [cite: 17]

### Enhancement Scope Definition

#### Enhancement Type

- [x] [cite_start]New Feature Addition (OAuth) [cite: 20]
- [x] [cite_start]Major Feature Modification (Replacing shell-based Git with a native library, enhancing CLI) [cite: 21]

#### Enhancement Description

This document outlines Phase 2 of PrivateFork development. [cite_start]The primary goals are to replace the PAT-based authentication with a more secure and user-friendly OAuth 2.0 flow, introduce a robust Command-Line Interface (CLI), and integrate native Git library functionality to replace the fragile shell wrapper[cite: 23].

#### Impact Assessment

- [x] [cite_start]**Significant Impact**: This enhancement involves substantial changes to core components, including authentication and Git operations, touching almost every part of the existing application[cite: 25].

### Goals and Background Context

#### Goals

- [cite_start]Provide a seamless and secure one-click authentication experience using GitHub OAuth 2.0, removing the need for manually managing Personal Access Tokens[cite: 28].
- [cite_start]Enable powerful automation and scripting workflows for developers by introducing a full-featured Command-Line Interface (CLI)[cite: 29].
- [cite_start]Boost the application's reliability and performance by replacing fragile shell commands with a robust, native Swift Git library[cite: 30].

#### Background Context

[cite_start]The PrivateFork MVP successfully validated the core concept of a streamlined forking utility[cite: 32]. [cite_start]However, its reliance on PATs and shell commands presents significant security, usability, and reliability limitations[cite: 33]. [cite_start]Phase 2 aims to address this technical debt and evolve PrivateFork from a simple utility into a professional-grade developer tool that integrates seamlessly into daily workflows, whether in the GUI or the command line[cite: 34].

### Change Log

| Change | Date | Version | Description | Author |
| :--- | :--- | :--- | :--- | :--- |
| Refined Epic 2 Stories | 2025-07-24 | 1.5 | Re-sequenced stories in Epic 2 for logical dependency and testability. | Sarah (PO) |
| Hard Cutover to OAuth | 2025-07-24 | 1.4 | Decided on a hard cutover to OAuth, removing all PAT-related code and the Settings view. Locked in CLI scope. | Sarah (PO) |
| Updated UI Auth Method | 2025-07-24 | 1.3 | Specified segmented control for auth modes per user feedback. | Sarah (PO) |
| De-scoped Finder Extension | 2025-07-24 | 1.2 | Removed Finder Extension from Phase 2 to reduce risk and focus on core value. | Sarah (PO) |
| Refined Goals & Impact | 2025-07-24 | 1.1 | Refined goals to be user-centric and added detail to impact assessment. | Sarah (PO) |
| Initial Draft | 2025-07-24 | 1.0 | First draft of the Phase 2 Brownfield PRD. | Sarah (PO) |

## Requirements

### Functional

1.  [cite_start]**FR1**: The application's GUI must implement the full GitHub OAuth 2.0 device flow to authorize the user[cite: 39].
2.  [cite_start]**FR2**: Upon successful authorization, the application must securely store the OAuth token and a refresh token in the macOS Keychain[cite: 40].
3.  [cite_start]**FR3**: The CLI must be able to perform a fork and clone operation non-interactively, using the stored OAuth token for authentication[cite: 41].
4.  [cite_start]**FR4**: The existing GitService that shells out to the git command must be replaced with a new service that utilizes a native Swift Git library[cite: 42].
5.  [cite_start]**FR5**: All cloning operations, whether initiated from the GUI or CLI, must use the new native Git library service[cite: 43].
6.  [cite_start]**FR6**: The CLI must accept a source repository URL and a target local directory path as arguments[cite: 44].
7.  [cite_start]**FR7**: The application's main interface must provide a mechanism for the user to log out, which revokes and removes all stored OAuth credentials from the Keychain[cite: 45].
8.  [cite_start]**FR8**: The CLI invocation for Phase 2 will be strictly limited to the following command structure: `privatefork fork <repository-url> --path <local-directory-path>`[cite: 46]. [cite_start]No other commands or flags will be developed in this phase[cite: 47].

### Non Functional

1.  [cite_start]**NFR1**: The integration of a new native Git library should not increase the final application bundle size by more than 25%[cite: 49].
2.  [cite_start]**NFR2**: The user-facing OAuth authorization flow should feel responsive, with UI feedback provided for all network operations[cite: 50].
3.  [cite_start]**NFR3**: The performance of cloning a repository using the new native Git library must be comparable to or better than the existing shell-based implementation[cite: 51].
4.  [cite_start]**NFR4**: All sensitive credentials (OAuth tokens, refresh tokens) MUST be stored using the KeychainService and never in plain text files or user defaults[cite: 52].

### Compatibility Requirements

1.  [cite_start]**CR1**: The application's internal data models for repositories (Repository, Owner, etc.) must remain compatible with the GitHub API v3[cite: 54].
2.  [cite_start]**CR2**: The introduction of the native Git library must not break any existing unit or integration tests for other services[cite: 55].

## User Interface Enhancement Goals

### Integration with Existing UI

[cite_start]With the removal of PAT-based authentication, the **SettingsView will be completely removed** from the application[cite: 58]. [cite_start]All authentication functionality will be integrated directly into the MainView[cite: 59]. [cite_start]If a user is not authenticated, the main content area will be disabled, and a prominent "Sign in with GitHub" button will be displayed[cite: 60].

### Modified/New Screens and Views

-   [cite_start]**MainView (Modified)**: The view will be updated to handle two states[cite: 62]:
    -   [cite_start]**Authenticated State**: The existing UI for forking will be visible[cite: 63]. [cite_start]A "Log Out" button and the authenticated user's GitHub username will be displayed in a non-intrusive location (e.g., the bottom corner)[cite: 64].
    -   [cite_start]**Unauthenticated State**: The input fields and "Fork" button will be disabled[cite: 65]. [cite_start]A large, centered "Sign in with GitHub" button will be the primary call to action[cite: 66].
-   [cite_start]**SettingsView (Removed)**: This view, its associated ViewModel (SettingsViewModel), and all related tests will be deleted from the codebase[cite: 67].
-   [cite_start]**OAuth Device Flow View (New)**: A simple, non-interactive view or modal will be required to display the user code and the `github.com/login/device` URL during the device flow process[cite: 68].

### UI Consistency Requirements

[cite_start]All new UI elements (e.g., the login/logout buttons) must adhere to the existing minimalist design language of the application to ensure a cohesive user experience[cite: 70].

## Technical Constraints and Integration Requirements

### Existing Technology Stack

[cite_start]This enhancement must be implemented within the constraints of the existing technology stack, which includes[cite: 73]:
-   [cite_start]**Language**: Swift 5.x [cite: 74]
-   [cite_start]**UI Framework**: SwiftUI [cite: 75]
-   [cite_start]**Credential Storage**: macOS Keychain via the existing `KeychainService`[cite: 76].
-   [cite_start]**API Communication**: `URLSession` for all network requests[cite: 77].

### Integration Approach

-   [cite_start]**Database Integration Strategy**: N/A (The application is stateless and does not use a local database)[cite: 79].
-   [cite_start]**API Integration Strategy**: The new OAuth flow will require adding new methods to the `GitHubService` to handle the device flow and token exchange, but it will still consume the standard GitHub REST API[cite: 80].
-   [cite_start]**Frontend Integration Strategy**: The `MainViewModel` will be expanded to manage the application's authentication state (e.g., showing/hiding the login button, handling the device flow, updating the UI upon successful login)[cite: 81]. [cite_start]The `SettingsViewModel` will be removed[cite: 82].
-   [cite_start]**Testing Integration Strategy**: New unit tests must be added for the updated authentication logic in `MainViewModel`, the new OAuth logic within `GitHubService`, and the new native `GitService`[cite: 83]. [cite_start]Existing tests must continue to pass, and tests for the removed `SettingsView` and `SettingsViewModel` must be deleted[cite: 84].

### Code Organization and Standards

-   [cite_start]**File Structure Approach**: New services and protocols must follow the existing `Services/Implementations` and `Services/Protocols` structure[cite: 86]. [cite_start]The `SettingsView.swift` and `SettingsViewModel.swift` files will be deleted[cite: 87].
-   [cite_start]**Coding Standards**: All new code must adhere to the implicit Swift conventions and patterns observed in the existing codebase (e.g., protocol-oriented design, dependency injection via the orchestrator)[cite: 88].

### Deployment and Operations

-   [cite_start]**Build Process Integration**: The project will continue to be built using the standard Xcode build process[cite: 90]. [cite_start]Any new dependencies (e.g., a Swift Git library) must be managed via the Swift Package Manager[cite: 91].
-   **Deployment Strategy**: Remains a manual process of distributing the `.app` bundle. [cite_start]No changes to the deployment strategy are required[cite: 92].

### Risk Assessment and Mitigation

-   [cite_start]**Technical Risks**: The primary technical risk is the selection and integration of a native Swift Git library[cite: 94]. [cite_start]The MVP's reliance on a shell wrapper is a known point of failure[cite: 95].
-   [cite_start]**Mitigation**: A proof-of-concept and library evaluation will be one of the final implementation stories to validate the chosen library's capabilities and performance before fully replacing the existing GitService[cite: 96].
-   [cite_start]**Integration Risks**: The OAuth 2.0 Device Flow is a well-defined standard, but incorrect implementation can lead to security vulnerabilities[cite: 97].
-   [cite_start]**Mitigation**: The implementation must strictly follow GitHub's official documentation and security best practices for the device flow[cite: 98].
-   [cite_start]**Deployment Risks**: N/A[cite: 99].

## Epic and Story Structure

### Epic Approach

Phase 2 will be structured into three sequential epics. [cite_start]This allows us to focus on delivering value incrementally, starting with the most foundational changes and deferring the highest-risk item (the native Git library) until last[cite: 102].
-   [cite_start]Epic 2: Foundational OAuth 2.0 Integration [cite: 103]
-   [cite_start]Epic 3: CLI Modernization [cite: 104]
-   [cite_start]Epic 4: Native Git Reliability [cite: 105]

## Epic 2: Foundational OAuth 2.0 Integration

[cite_start]**Epic Goal**: To completely replace the existing PAT-based authentication with the secure and user-friendly GitHub OAuth 2.0 device flow, and to remove all legacy authentication code, providing a seamless one-time login experience for the user[cite: 107].

### Story 2.1: PAT Authentication Removal

[cite_start]**As a** developer, **I want** to remove the SettingsView, SettingsViewModel, and all related PAT authentication logic, **so that** the codebase is prepared for the new OAuth implementation without any legacy code[cite: 109].

#### Acceptance Criteria

1.  [cite_start]The `SettingsView.swift` and `SettingsViewModel.swift` files are deleted from the project[cite: 111].
2.  [cite_start]All tests related to the `SettingsView` and `SettingsViewModel` are removed[cite: 112].
3.  [cite_start]The application compiles successfully after the removal of these components[cite: 113].
4.  [cite_start]The button on the `MainView` that previously opened the settings sheet is removed[cite: 114].

### Story 2.2: OAuth Credential Storage

[cite_start]**As a** developer, **I want** to update the `KeychainService` to securely store and retrieve the new OAuth access and refresh tokens, **so that** the application has a secure place to manage credentials[cite: 116].

#### Acceptance Criteria

1.  [cite_start]The `KeychainService` is updated with new methods to save, load, and delete the OAuth access token and refresh token[cite: 118].
2.  [cite_start]The existing PAT-related methods in `KeychainService` are removed[cite: 119].
3.  [cite_start]The new methods are covered by unit tests to ensure correct interaction with the Keychain[cite: 120].
4.  [cite_start]All sensitive token data is handled securely and is never exposed in logs[cite: 121].

### Story 2.3: OAuth Service Implementation

[cite_start]**As a** developer, **I want** to implement the backend logic for the GitHub OAuth 2.0 device flow, **so that** the application can obtain an access token and refresh token from GitHub[cite: 123].

#### Acceptance Criteria

1.  [cite_start]A new method is added to `GitHubService` to initiate the device flow and retrieve a user code and verification URI[cite: 125].
2.  [cite_start]A new method is added to `GitHubService` to poll GitHub and exchange the device code for an access token and refresh token[cite: 126].
3.  [cite_start]The new methods correctly handle all potential error states from the GitHub API (e.g., authorization pending, access denied, token expired)[cite: 127].
4.  [cite_start]The retrieved access and refresh tokens are securely passed to the updated `KeychainService` for storage[cite: 128].
5.  [cite_start]All new logic is covered by unit tests using mock network requests[cite: 129].

### Story 2.4: Main View UI for Authentication

[cite_start]**As a** user, **I want** a clear user interface on the main screen to sign in and out, **so that** I can easily manage my authentication state[cite: 131].

#### Acceptance Criteria

1.  [cite_start]When not authenticated, the `MainView` displays a prominent "Sign in with GitHub" button[cite: 133].
2.  [cite_start]The repository URL and local path input fields are disabled when not authenticated[cite: 134].
3.  [cite_start]When authenticated, the `MainView` displays my GitHub username and a "Log Out" button[cite: 135].
4.  [cite_start]The `MainViewModel` is updated to manage the different UI states (unauthenticated, authenticating, authenticated)[cite: 136].
5.  [cite_start]Clicking the "Sign in with GitHub" button triggers the OAuth device flow process[cite: 137].
6.  [cite_start]Clicking the "Log Out" button clears all credentials from the Keychain and returns the UI to the unauthenticated state[cite: 138].

### Story 2.5: Application-level Integration

[cite_start]**As a** user, **I want** the application to remember my login status between launches, **so that** I only have to authenticate once[cite: 140].

#### Acceptance Criteria

1.  [cite_start]The `PrivateForkOrchestrator` is updated to retrieve and use the OAuth token from the `KeychainService` for all GitHub API requests[cite: 142].
2.  [cite_start]On application launch, the app correctly checks the `KeychainService` for valid OAuth credentials[cite: 143].
3.  [cite_start]If valid credentials exist, the UI is initialized in the "Authenticated State"[cite: 144].
4.  [cite_start]If no valid credentials exist, the UI is initialized in the "Unauthenticated State"[cite: 145].