# **State Management**

## **Store Structure**

Global state is not anticipated for the MVP. All state will be managed within the scope of the ViewModels. The MainViewModel will be the primary source of truth for the application's operational state.

## **State Management Template**

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
