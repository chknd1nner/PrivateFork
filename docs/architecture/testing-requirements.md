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
- **DualLaunchIntegrationTests**: Tests AppLauncher CLI/GUI mode detection
- **MainViewIntegrationTests**: End-to-end ViewModel integration

### **UI Tests** (`PrivateForkUITests/`)
- **Automated GUI Testing**: Real application launch and interaction
- **User Journey Validation**: Settings workflow, URL validation, core UI elements
- **XCUIApplication**: Simulated mouse clicks, keyboard input, element detection

### **Package Tests** (`PrivateForkPackage/Tests/`)
- **Feature Testing**: Swift Package Manager component tests
- **XCTest Framework**: Consistent testing approach across all targets

## **Component Test Template**

Unit tests for ViewModels are mandatory and will follow the Given-When-Then structure using XCTest. Dependencies will be mocked to isolate the logic under test.

```swift
import XCTest  
@testable import PrivateFork

final class MainViewModelTests: XCTestCase {

    var viewModel: MainViewModel!  
    var mockGitService: MockGitService!  
    var mockGitHubService: MockGitHubService!

    override func setUp() {  
        super.setUp()  
        // Given: A ViewModel with mocked dependencies  
        mockGitService = MockGitService()  
        mockGitHubService = MockGitHubService()  
        viewModel = MainViewModel(gitService: mockGitService, githubService: mockGitHubService)  
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
- **Async Testing**: Use async/await test functions and expectation patterns for testing asynchronous operations

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