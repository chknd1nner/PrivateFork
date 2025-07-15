# **Source Tree**

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
