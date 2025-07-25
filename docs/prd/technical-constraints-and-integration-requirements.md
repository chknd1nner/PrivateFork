# Technical Constraints and Integration Requirements

## Existing Technology Stack

[cite_start]This enhancement must be implemented within the constraints of the existing technology stack, which includes[cite: 73]:
-   [cite_start]**Language**: Swift 5.x [cite: 74]
-   [cite_start]**UI Framework**: SwiftUI [cite: 75]
-   [cite_start]**Credential Storage**: macOS Keychain via the existing `KeychainService`[cite: 76].
-   [cite_start]**API Communication**: `URLSession` for all network requests[cite: 77].

## Integration Approach

-   [cite_start]**Database Integration Strategy**: N/A (The application is stateless and does not use a local database)[cite: 79].
-   [cite_start]**API Integration Strategy**: The new OAuth flow will require adding new methods to the `GitHubService` to handle the device flow and token exchange, but it will still consume the standard GitHub REST API[cite: 80].
-   [cite_start]**Frontend Integration Strategy**: The `MainViewModel` will be expanded to manage the application's authentication state (e.g., showing/hiding the login button, handling the device flow, updating the UI upon successful login)[cite: 81]. [cite_start]The `SettingsViewModel` will be removed[cite: 82].
-   [cite_start]**Testing Integration Strategy**: New unit tests must be added for the updated authentication logic in `MainViewModel`, the new OAuth logic within `GitHubService`, and the new native `GitService`[cite: 83]. [cite_start]Existing tests must continue to pass, and tests for the removed `SettingsView` and `SettingsViewModel` must be deleted[cite: 84].

## Code Organization and Standards

-   [cite_start]**File Structure Approach**: New services and protocols must follow the existing `Services/Implementations` and `Services/Protocols` structure[cite: 86]. [cite_start]The `SettingsView.swift` and `SettingsViewModel.swift` files will be deleted[cite: 87].
-   [cite_start]**Coding Standards**: All new code must adhere to the implicit Swift conventions and patterns observed in the existing codebase (e.g., protocol-oriented design, dependency injection via the orchestrator)[cite: 88].

## Deployment and Operations

-   [cite_start]**Build Process Integration**: The project will continue to be built using the standard Xcode build process[cite: 90]. [cite_start]Any new dependencies (e.g., a Swift Git library) must be managed via the Swift Package Manager[cite: 91].
-   **Deployment Strategy**: Remains a manual process of distributing the `.app` bundle. [cite_start]No changes to the deployment strategy are required[cite: 92].

## Risk Assessment and Mitigation

-   [cite_start]**Technical Risks**: The primary technical risk is the selection and integration of a native Swift Git library[cite: 94]. [cite_start]The MVP's reliance on a shell wrapper is a known point of failure[cite: 95].
-   [cite_start]**Mitigation**: A proof-of-concept and library evaluation will be one of the final implementation stories to validate the chosen library's capabilities and performance before fully replacing the existing GitService[cite: 96].
-   [cite_start]**Integration Risks**: The OAuth 2.0 Device Flow is a well-defined standard, but incorrect implementation can lead to security vulnerabilities[cite: 97].
-   [cite_start]**Mitigation**: The implementation must strictly follow GitHub's official documentation and security best practices for the device flow[cite: 98].
-   [cite_start]**Deployment Risks**: N/A[cite: 99].
