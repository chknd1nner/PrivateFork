# **Technical Assumptions**

## **Repository Structure: Single Repository**

The entire application, including all its code and resources, will be contained within a single Git repository.

## **Service Architecture: Self-contained Native Application**

The application is a standalone macOS utility. It will communicate directly with the GitHub API for its operations. There is no separate backend service to build or maintain.

## **Testing Requirements: Unit \+ Integration**

The project will require both unit tests for individual components and logic, as well as integration tests to verify the end-to-end automation flow, including interactions with the command-line git and the GitHub API. **The entire test suite must be fully automated and executable with a single command (e.g., swift test) to support an agentic development loop (code \-\> build \-\> test \-\> debug).**

## **Additional Technical Assumptions and Requests**

- **Language/Framework:** The application will be built natively for macOS using Swift and SwiftUI.  
- **Core Logic (MVP):** The initial version will wrap and execute standard command-line git operations. It will not use a native Git library.  
- **Authentication (MVP):** GitHub API access will be handled via a user-provided Personal Access Token (PAT). OAuth is out of scope for the MVP.  
- **Secure Storage:** The GitHub PAT must be stored securely in the native macOS Keychain.  
- **Development Model:** The application will be implemented by an LLM coding assistant, under the direction of a user with no prior Swift coding experience. This implies that code must be clear, conventional, and well-documented.  
- **Scope Limitation:** The utility is intended exclusively for creating private forks of **public** GitHub repositories.
