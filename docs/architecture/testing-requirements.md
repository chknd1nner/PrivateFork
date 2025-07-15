# **Testing Requirements**

## **Component Test Template**

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

## **Testing Best Practices**

- **Unit Tests**: Test each ViewModel and Service in isolation.  
- **Integration Tests**: Test the interaction between services (e.g., ensuring the GitHubService and GitService are called in the correct order).  
- **Coverage Goals**: Aim for \>80% code coverage on all non-View logic.  
- **Test Structure**: Strictly follow the Arrange-Act-Assert (or Given-When-Then) pattern.  
- **Mock Dependencies**: All external dependencies MUST be mocked in unit tests.  
- **Async Testing**: Use async/await test functions and expectation patterns for testing asynchronous ViewModel operations.
