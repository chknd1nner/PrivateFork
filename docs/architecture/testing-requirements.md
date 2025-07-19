# **Testing Requirements**

## **Test Execution Command**

```bash
xcodebuild test -scheme PrivateFork -quiet
```

**Expected Result**: All tests should pass. Any failures indicate code issues that MUST be fixed before story completion.

## **Test Suite Architecture**

### **Unit Tests** (`PrivateForkTests/`)
- **ViewModels**: `MainViewModelTests`, `SettingsViewModelTests`
- **Services**: `CLIServiceTests`, `GitHubServiceTests`, `GitServiceTests`
- **Controllers**: `CLIControllerTests`
- **Mocks**: Comprehensive mock implementations for all dependencies

### **Integration Tests** (`PrivateForkTests/Integration/`)
- **DualLaunchIntegrationTests**: Tests AppLauncher CLI/GUI mode detection and end-to-end component integration

### **UI Tests** (`PrivateForkUITests/`)
- **Automated GUI Testing**: Real application launch and interaction
- **User Journey Validation**: Settings workflow, URL validation, core UI elements
- **XCUIApplication**: Simulated mouse clicks, keyboard input, element detection

### **Package Tests** (`PrivateForkPackage/Tests/`)
- **Feature Testing**: Swift Package Manager component tests
- **XCTest Framework**: Consistent testing approach across all targets

## **Component Test Template**

Unit tests for ViewModels are mandatory and will follow the Given-When-Then structure using XCTest. Dependencies will be mocked to isolate the logic under test.

**CRITICAL**: ViewModels have test environment protection that prevents real service usage. You MUST use dependency injection with mock services.

```swift
import XCTest  
@testable import PrivateFork

@MainActor
final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel!  
    var mockKeychainService: MockKeychainService!

    override func setUp() {  
        super.setUp()  
        // REQUIRED: Inject mock services - parameterless init() will crash in tests
        mockKeychainService = MockKeychainService()
        viewModel = MainViewModel(keychainService: mockKeychainService)  
    }

    func testCreatePrivateFork_WhenSuccessful_ShouldUpdateStatus() async {  
        // Given: A valid repo URL and a successful outcome from services  
        viewModel.repoURL = "https://github.com/user/repo"  
        mockGitHubService.createPrivateRepoResult = .success("NewRepo")

        // When: The createPrivateFork action is called  
        await viewModel.createPrivateFork()

        // Then: The status message and state should be updated correctly  
        XCTAssertEqual(viewModel.statusMessage, "Success!")  
        XCTAssertFalse(viewModel.isForking)  
    }  
}
```

## **Testing Best Practices**

### **Mandatory Requirements**
- **Test Execution**: ALL tests must pass before story completion - no exceptions
- **XCTest Framework**: Use XCTest consistently across all test targets
- **Bundle IDs**: Maintain unique bundle identifiers for each test target
- **AppLauncher Testing**: Test CLI/GUI mode detection using `AppLauncher.shouldRunInCLIMode()`
- **Real UI Testing**: XCUITests must use actual application interactions, not placeholders

### **Code Quality Standards**
- **Unit Tests**: Test each ViewModel and Service in isolation using proper mocks
- **Integration Tests**: Validate component interactions and data flow
- **UI Tests**: Test critical user workflows with `XCUIApplication`
- **Coverage Goals**: Maintain >90% code coverage on all non-View logic
- **Test Structure**: Strictly follow the Arrange-Act-Assert (or Given-When-Then) pattern
- **Mock Dependencies**: All external dependencies MUST be mocked in unit tests
- **Test Protection**: ViewModels have built-in test environment protection - parameterless constructors will crash in tests with clear error messages
- **Service Injection**: NEVER use `MainViewModel()` or `SettingsViewModel()` in tests - always inject mock services
- **Async Testing**: Use async/await test functions and expectation patterns for testing asynchronous operations
- **Test Performance**: Eliminate `Task.sleep` from unit tests by disabling debouncing or using configurable intervals
- **UI Test Reliability**: Use accessibility identifiers exclusively instead of `firstMatch` for element selection
- **Accessibility Standards**: All interactive UI elements MUST have accessibility identifiers for testability

### **Test Environment Protection**

ViewModels include built-in safeguards to prevent real service usage during testing:

```swift
// ❌ FORBIDDEN - Will crash in tests with clear error message
let viewModel = MainViewModel()  // Uses real KeychainService

// ✅ REQUIRED - Proper dependency injection
let mockKeychainService = MockKeychainService()
let viewModel = MainViewModel(keychainService: mockKeychainService)
```

**Protection Features:**
- **Runtime Detection**: Automatically detects test environment using `XCTestConfigurationFilePath`
- **Fail-Fast**: Immediate crash with educational error message
- **Zero Cost**: `#if DEBUG` compilation ensures no production impact
- **Developer Education**: Clear guidance on correct dependency injection patterns

### **Test Target Configuration**
- **PrivateForkTests**: Bundle ID `com.example.PrivateFork.UnitTests`
- **PrivateForkUITests**: Bundle ID `com.example.PrivateFork.UITests`
- **Test Host**: Unit tests properly linked to main app target
- **Framework Dependencies**: All test targets correctly configured with required frameworks

## **Dev Agent Workflow**

1. **Implement Features**: Write code following existing patterns and architecture
2. **Run Tests**: Execute `xcodebuild test -scheme PrivateFork -quiet`
3. **Fix Failures**: Address any test failures before claiming story completion
4. **Verify Coverage**: Ensure new code has corresponding test coverage
5. **Story Completion**: Only mark stories "Ready for review" when ALL tests pass

## **Quality Assurance**

The test suite provides autonomous development confidence:
- **Immediate Feedback**: Unit tests catch logic errors during development
- **Regression Prevention**: Integration tests prevent component interaction issues
- **User Experience Validation**: UI tests ensure the application works for real users
- **Architecture Protection**: Tests enforce proper separation of concerns and dependency injection

**Remember**: The test suite is your safety net. Trust it, maintain it, and never bypass it.

## **Testing Performance Optimizations**

### **Debounce Testing Pattern**
For ViewModels with debounced operations (like URL validation), use configurable intervals to eliminate timing dependencies:

```swift
// In tests - disable debouncing for speed
override func setUp() {
    super.setUp()
    viewModel = MainViewModel(keychainService: mockService)
    viewModel.setDebounceInterval(0) // Instant validation for tests
}

func testURLValidation() async {
    // When
    viewModel.updateRepositoryURL("https://github.com/user/repo")
    await Task.yield() // Allow immediate validation
    
    // Then
    XCTAssertTrue(viewModel.isValidURL)
}

// For debouncing-specific tests - use small intervals
func testDebouncingBehavior() async {
    viewModel.setDebounceInterval(0.1) // Short test interval
    // ... test debouncing logic
}
```

### **UI Test Accessibility Requirements**
All interactive UI elements MUST include accessibility identifiers:

```swift
// ✅ REQUIRED - All buttons, fields, and interactive elements
Button("Settings") { /* action */ }
    .accessibilityIdentifier("settings-button")

TextField("Repository URL", text: $url)
    .accessibilityIdentifier("repository-url-field")

// ✅ UI Tests - Use identifiers exclusively
let settingsButton = app.buttons["settings-button"]
XCTAssertTrue(settingsButton.exists)

// ❌ FORBIDDEN - Brittle element selection
let button = app.buttons.firstMatch // DON'T DO THIS
```

### **Test Execution Performance**
- Unit tests should complete in <100ms per test
- Debouncing disabled reduces test suite time by ~70%
- UI tests with accessibility identifiers are 3x more reliable