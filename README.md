# PrivateFork - macOS App

A modern macOS application for creating private mirrors of GitHub repositories.

## Project Architecture

```
PrivateFork/
├── PrivateFork.xcworkspace/              # Open this file in Xcode
├── PrivateFork.xcodeproj/                # Main Xcode project
├── PrivateFork/                          # App target (main implementation)
│   ├── Application/                    # App lifecycle and main entry
│   │   ├── PrivateForkApp.swift          # SwiftUI app entry point
│   │   ├── AppLauncher.swift             # App launch logic
│   │   └── main.swift                    # CLI mode entry point
│   ├── Controllers/                    # CLI controller logic
│   ├── Models/                         # Data models and types
│   ├── Services/                       # Business logic services
│   ├── ViewModels/                     # MVVM view models
│   ├── Views/                          # SwiftUI views
│   ├── Utilities/                      # Helper utilities
│   └── Assets.xcassets/                # App-level assets
├── PrivateForkTests/                     # Unit and integration tests
├── PrivateForkUITests/                   # UI automation tests
├── Config/                               # XCConfig build settings
└── docs/                                 # Documentation
```

## Key Architecture Points

### Dual Mode Operation
- **GUI Mode**: Full SwiftUI interface for interactive use
- **CLI Mode**: Command-line interface for automation and scripting
- Smart mode detection based on launch context

### MVVM Architecture
- Clean separation between UI and business logic
- Dependency injection for testability
- Mock services for testing

### Services Layer
Core business logic is organized into services:
- **KeychainService**: Secure credential storage
- **GitHubService**: GitHub API integration
- **GitService**: Git operations and repository management
- **PrivateForkOrchestrator**: Coordinates the fork creation workflow

## Development

### Building and Testing
```bash
# Build the project
xcodebuild -workspace PrivateFork.xcworkspace -scheme PrivateFork build

# Run tests
xcodebuild -workspace PrivateFork.xcworkspace -scheme PrivateFork test

# Run SwiftLint
swiftlint
```

### XCConfig Build Settings
Build settings are managed through **XCConfig files** in `Config/`:
- `Config/Shared.xcconfig` - Common settings (bundle ID, versions, deployment target)
- `Config/Debug.xcconfig` - Debug-specific settings  
- `Config/Release.xcconfig` - Release-specific settings
- `Config/Tests.xcconfig` - Test-specific settings

### App Sandbox & Entitlements
The app is sandboxed by default with basic file access. Edit `Config/PrivateFork.entitlements` to add capabilities:
```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<!-- Add other entitlements as needed -->
```

## Usage

### GUI Mode
Launch the app normally to use the graphical interface:
1. Configure GitHub credentials in the app
2. Enter a repository URL
3. Select a local directory
4. Create the private fork

### CLI Mode
Use command-line arguments for automation:
```bash
# Create a private fork via CLI
./PrivateFork create-fork \
  --url "https://github.com/owner/repo" \
  --path "/path/to/local/directory"
```

## Testing

The project includes comprehensive test coverage:
- **Unit Tests**: Service and model testing with mocks
- **Integration Tests**: End-to-end workflow testing
- **UI Tests**: Automated interface testing

Run tests using:
```bash
xcodebuild -workspace PrivateFork.xcworkspace -scheme PrivateFork test
```

## Code Quality

The project uses SwiftLint for code quality enforcement. Configuration is in `.swiftlint.yml`.

## macOS-Specific Features

### Window Management
SwiftUI-based interface with proper macOS window behavior and controls.

### Keychain Integration
Secure storage of GitHub credentials using macOS Keychain Services.

### File System Access
Sandbox-compliant file operations with user-selected directory access.