# **PrivateFork Frontend Architecture**

## **Introduction**

This document outlines the technical architecture for the **PrivateFork native macOS application**. It translates the requirements from the Product Requirements Document (PRD) and the design goals from the UI/UX Specification into a concrete technical plan for development.

The primary goal of this architecture is to create a robust, maintainable, and high-performance application that feels completely at home on macOS, built using modern, native technologies. This document will serve as the essential guide for the developer agents implementing the application.

### **Template and Framework Selection**

Based on the explicit requirements in the PRD and UI/UX Specification, the project will be a **native macOS application built from scratch**.

- **Primary Framework**: **SwiftUI** will be used for the user interface, ensuring a modern, declarative, and native experience.  
- **Language**: **Swift** will be the sole programming language.  
- **Project Foundation**: The project will be initialized using the standard macOS App template provided by Xcode. No third-party starter templates or cross-platform frameworks will be used.

This approach guarantees the best possible performance, system integration (e.g., Keychain, Dark Mode, Accessibility), and adherence to macOS design conventions.

### **Change Log**

| Date | Version | Description | Author |
| :---- | :---- | :---- | :---- |
| July 15, 2025 | 1.2 | Restructured document to align with BMad front-end-architecture-tmpl. | Winston, Architect |
| July 15, 2025 | 1.1 | Added MVVM, shared logic, build tools, and coding conventions. | Winston, Architect |
| July 15, 2025 | 1.0 | Initial draft of the architecture document. | Winston, Architect |

## **Tech Stack**

This table defines the specific technologies and libraries that will be used to build the application. These choices are definitive and must be adhered to during development to ensure consistency.

| Category | Technology | Version | Purpose | Rationale |
| :---- | :---- | :---- | :---- | :---- |
| **Framework** | SwiftUI | 5.0+ | UI, State Management | Native, modern, declarative framework for macOS. Ensures optimal performance and system integration. |
| **Language** | Swift | 5.10+ | Core Application Logic | The standard, safe, and high-performance language for Apple platforms. |
| **Build Tool** | Xcode | 16+ | Compilation, Building | The standard IDE and build system for macOS development. |
| **Testing** | XCTest | Included | Unit & Integration Testing | The native testing framework, ensuring tight integration with Xcode and the build process. |
| **Linting** | SwiftLint | Latest | Code Style & Quality | Enforces consistent code style and best practices, crucial for maintainability with agent-based development. |
| **Automation** | XcodeBuildMCP | Latest | Build/Test Automation | Provides a robust set of command-line tools for building, testing, and interacting with Xcode projects, enabling an automated dev loop. |
| **Dependencies** | None (for MVP) | N/A | N/A | To maintain a lightweight footprint and avoid external reliance, the MVP will use native Apple frameworks exclusively. |

## **Source Tree**

To ensure testability, maintainability, and a clear separation of concerns, the project will strictly adhere to the **Model-View-ViewModel (MVVM)** pattern. The core logic will be shared between the GUI and CLI targets by encapsulating it in a common set of injectable services.

The project will be organized as follows to support this architecture:

PrivateFork/  
├── PrivateFork.xcodeproj  
├── PrivateFork/  
│   ├── Application/  
│   │   ├── PrivateForkApp.swift      # Main App entry point  
│   │   └── AppState.swift            # Global app state (if needed)  
│   │  
│   ├── Models/  
│   │   └── AppModels.swift           # Core data structures (e.g., ForkRequest)  
│   │  
│   ├── Views/  
│   │   ├── MainView.swift            # The main UI view  
│   │   └── SettingsView.swift        # The settings sheet view  
│   │  
│   ├── ViewModels/  
│   │   ├── MainViewModel.swift       # ViewModel for MainView  
│   │   └── SettingsViewModel.swift   # ViewModel for SettingsView  
│   │  
│   ├── Services/  
│   │   ├── Protocols/                # Service protocols for dependency injection  
│   │   │   ├── KeychainServiceProtocol.swift  
│   │   │   ├── GitServiceProtocol.swift  
│   │   │   └── GitHubServiceProtocol.swift  
│   │   │  
│   │   ├── Implementations/  
│   │   │   ├── KeychainService.swift   # Concrete implementation for Keychain  
│   │   │   ├── GitService.swift        # Concrete implementation for shell commands  
│   │   │   └── GitHubService.swift   # Concrete implementation for GitHub API  
│   │  
│   └── Utilities/  
│       ├── ViewModifiers.swift       # Custom SwiftUI View Modifiers  
│       └── Shell.swift               # A utility for running shell commands  
│  
└── PrivateForkTests/  
    ├── ViewModels/  
    │   ├── MainViewModelTests.swift  
    │   └── SettingsViewModelTests.swift  
    │  
    └── Mocks/  
        ├── MockKeychainService.swift  
        ├── MockGitService.swift  
        └── MockGitHubService.swift

## **Component Standards**

### **Component Template**

All SwiftUI Views must be lightweight and delegate logic to their ViewModel. They should be structured as follows:

import SwiftUI

struct MainView: View {  
    // Use @StateObject to create and own the ViewModel instance.  
    @StateObject private var viewModel \= MainViewModel()

    var body: some View {  
        VStack {  
            // UI elements bind directly to @Published properties in the ViewModel.  
            TextField("Public Repo URL", text: $viewModel.repoURL)

            // Actions call methods on the ViewModel.  
            Button("Create Private Fork") {  
                viewModel.createPrivateFork()  
            }  
            .disabled(viewModel.isForking) // UI state is driven by the ViewModel.

            Text(viewModel.statusMessage)  
        }  
        .padding()  
        // Example of presenting a sheet for settings.  
        .sheet(isPresented: $viewModel.isShowingSettings) {  
            SettingsView()  
        }  
    }  
}

### **Naming Conventions**

- **Views**: PascalCase, suffixed with View (e.g., MainView.swift).  
- **ViewModels**: PascalCase, suffixed with ViewModel (e.g., MainViewModel.swift).  
- **Services (Protocols)**: PascalCase, suffixed with ServiceProtocol (e.g., GitServiceProtocol.swift).  
- **Services (Implementations)**: PascalCase, suffixed with Service (e.g., GitService.swift).  
- **Models**: PascalCase, descriptive name (e.g., ForkRequest.swift).

## **State Management**

### **Store Structure**

Global state is not anticipated for the MVP. All state will be managed within the scope of the ViewModels. The MainViewModel will be the primary source of truth for the application's operational state.

### **State Management Template**

ViewModels will manage state using @Published properties, making them available to the View for reactive updates.

import Foundation  
import Combine

@MainActor  
class MainViewModel: ObservableObject {  
    // MARK: \- Published Properties (for UI)  
    @Published var repoURL: String \= ""  
    @Published var localPath: String \= ""  
    @Published var statusMessage: String \= "Ready."  
    @Published var isForking: Bool \= false  
    @Published var isShowingSettings: Bool \= false

    // MARK: \- Dependencies  
    private let gitService: GitServiceProtocol  
    private let githubService: GitHubServiceProtocol

    // MARK: \- Initialization  
    init(gitService: GitServiceProtocol \= GitService(),  
         githubService: GitHubServiceProtocol \= GitHubService()) {  
        self.gitService \= gitService  
        self.githubService \= githubService  
    }

    // MARK: \- Public Methods (called by View)  
    func createPrivateFork() {  
        // Implementation uses async/await and updates @Published properties.  
    }  
}

## **API Integration**

### **Service Template**

All external interactions (shell commands, network calls) will be wrapped in services that conform to a protocol.

import Foundation

// Protocol defines the contract for the service.  
protocol GitServiceProtocol {  
    func clone(repoURL: URL, to localPath: URL) async \-\> Result\<String, Error\>  
}

// Concrete implementation handles the actual logic.  
struct GitService: GitServiceProtocol {  
    func clone(repoURL: URL, to localPath: URL) async \-\> Result\<String, Error\> {  
        // Use async/await to run shell command.  
        // Return a Result type to handle success or failure.  
        return .success("Cloned successfully.")  
    }  
}

## **Testing Requirements**

### **Component Test Template**

Unit tests for ViewModels are mandatory and will follow the Given-When-Then structure using XCTest. Dependencies will be mocked to isolate the logic under test.

import XCTest  
@testable import PrivateFork

final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel\!  
    var mockGitService: MockGitService\!  
    var mockGitHubService: MockGitHubService\!

    override func setUp() {  
        super.setUp()  
        // Given: A ViewModel with mocked dependencies  
        mockGitService \= MockGitService()  
        mockGitHubService \= MockGitHubService()  
        viewModel \= MainViewModel(gitService: mockGitService, githubService: mockGitHubService)  
    }

    func testCreatePrivateFork\_WhenSuccessful\_ShouldUpdateStatus() async {  
        // Given: A valid repo URL and a successful outcome from services  
        viewModel.repoURL \= "https://github.com/user/repo"  
        mockGitHubService.createPrivateRepoResult \= .success("NewRepo")

        // When: The createPrivateFork action is called  
        await viewModel.createPrivateFork()

        // Then: The status message and state should be updated correctly  
        XCTAssertEqual(viewModel.statusMessage, "Success\!")  
        XCTAssertFalse(viewModel.isForking)  
    }  
}

### **Testing Best Practices**

- **Unit Tests**: Test each ViewModel and Service in isolation.  
- **Integration Tests**: Test the interaction between services (e.g., ensuring the GitHubService and GitService are called in the correct order).  
- **Coverage Goals**: Aim for \>80% code coverage on all non-View logic.  
- **Test Structure**: Strictly follow the Arrange-Act-Assert (or Given-When-Then) pattern.  
- **Mock Dependencies**: All external dependencies MUST be mocked in unit tests.  
- **Async Testing**: Use async/await test functions and expectation patterns for testing asynchronous ViewModel operations.

## **Coding Standards**

### **Critical Coding Rules**

All code generated by developer agents MUST adhere to the following standards:

1. **MVVM Pattern**: Strictly separate concerns. Views are for display only. ViewModels contain all logic and state. Models are for data representation.  
2. **Protocol-Oriented Programming (POP)**: All services (e.g., GitService, GitHubService) must be abstracted behind protocols (GitServiceProtocol). ViewModels will depend on the protocols, not concrete implementations.  
3. **Dependency Injection**: Services will be injected into ViewModels during initialization. This is crucial for testability, allowing mock services to be injected during unit tests.  
4. **State Management**: Use @StateObject to create and own ViewModel instances in the View. Use @Published within ViewModels to expose properties to the View, allowing the UI to reactively update.  
5. **Asynchronous Operations**: All potentially long-running operations (shell commands, network requests) **must** be performed asynchronously using async/await. This prevents blocking the main thread and keeps the UI responsive.  
6. **Single Responsibility Principle**: Each file and class should have a single, clear purpose. For example, Keychain logic belongs in KeychainService.swift, not in a ViewModel.  
7. **Result Type for Outcomes**: All service operations that can fail must return a Result\<Success, Error\> type. This forces explicit and safe error handling in the ViewModels.  
8. **Comprehensive Unit Tests**: Every public function in a ViewModel or Service must have corresponding unit tests. Tests will follow a **Given-When-Then** structure for clarity. Mocks will be used for all external dependencies.  
9. **Custom View Modifiers**: For any repeated UI styling (e.g., a specific button style, text formatting), create a custom ViewModifier to ensure consistency and a single source of truth.  
10. **@MainActor**: All ViewModels must be marked with @MainActor to ensure UI updates happen on the main thread.

### **Quick Reference**

- **Build Project**: Use XcodeBuildMCP tool: build_mac_proj  
- **Run Tests**: Use XcodeBuildMCP tool: test_macos_proj  
- **Lint Code**: Run swiftlint from the command line in the project root.  
- **File Naming**: Follow conventions outlined in Component Standards.  
- **Project-specific Patterns**: Use dependency injection for all services as shown in the templates.