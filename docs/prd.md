# **PrivateFork (PRD)**

## **Goals and Background Context**

### **Goals**

- Solve the personal pain point of the tedious, manual process of creating a private mirror of a public GitHub repository.  
- Reduce the cognitive load for developers, eliminating the need to remember a specific sequence of git commands.  
- Increase developer confidence by providing a reliable tool that performs the operation correctly every time.  
- Create a tool that feels like a natural and indispensable part of a developer's workflow.  
- Achieve a high successful operation rate (\>99%) with a fast average operation time (under 30 seconds).

### **Background Context**

The core problem this application solves is the cumbersome and error-prone manual workflow required to create a private mirror of a public GitHub repository. The standard GitHub "fork" is public by default, which is insufficient for developers needing privacy for experimentation or modification.

Currently, a developer must manually clone the public repo, switch to the GitHub UI to create a new empty private repo, return to the command line to reconfigure remotes, and finally push to the new private origin. This multi-step process is a frequent annoyance for solo developers and other power users, interrupting their focus and wasting valuable time. This native macOS utility aims to transform this multi-step chore into a simple, reliable, one-click action.

### **Change Log**

| Date | Version | Description | Author |
| :---- | :---- | :---- | :---- |
| July 15, 2025 | 1.1 | Added more detailed ACs for UI state and CLI errors. | John, PM |
| July 15, 2025 | 1.0 | Initial PRD draft | John, PM |

## **Requirements**

### **Functional**

1. The application must provide a text field for the user to input the URL of a public GitHub repository.  
2. The application must provide a button that opens a native macOS file dialog for the user to select a local destination folder.  
3. The application must have a dedicated settings screen with input fields for a GitHub Username and a Personal Access Token (PAT).  
4. The settings screen must have a "Validate & Save" button that confirms the credentials are valid with the GitHub API and securely stores them.  
5. The settings screen must have a button to clear the stored credentials.  
6. The main screen must have a "Create Private Fork" button that initiates the automation process.  
7. The application must display real-time status updates to the user during the automation process (e.g., "Cloning...", "Creating private repo...", "Success\!").  
8. The core automation process, triggered by the "Create Private Fork" button, must perform the following sequence of actions:  
   - Authenticate with the user's GitHub account using the saved credentials.  
   - Create a new private repository on the user's GitHub account.  
   - Clone the public repository to the user-specified local folder.  
   - Configure the local clone's git remotes, setting upstream to the original public repository and origin to the new private repository.  
   - Perform the initial push of the code to the new private repository.  
9. The application must support being launched from the command line, allowing all necessary parameters (public repository URL, local destination folder) to be passed as arguments to trigger the core automation process directly, without launching the GUI.

### **Non-Functional**

1. The application should be lightweight and feel responsive to user input.  
2. The GitHub Personal Access Token (PAT) must be stored securely in the native macOS Keychain.  
3. The core automation process should have a success rate higher than 99%.  
4. The core automation process should, on average, complete in under 30 seconds for a typical repository.  
5. The application must gracefully handle and clearly communicate errors to the user, including but not limited to: invalid PAT, network failures, and git command failures.  
6. For the MVP, the application will rely on the user having git installed and available in their system's PATH.

## **User Interface Design Goals**

### **Overall UX Vision**

The user experience should be focused on speed and simplicity. It's a utility, not a destination. The user should be able to open the app, perform the single core action, and close it with minimal friction. The entire interaction should feel like a native macOS experience, adhering to the platform's established design conventions. The application must fully support and respect the system's light and dark mode settings.

### **Key Interaction Paradigms**

* **Single-Purpose Window**: The main interface will be a single, non-resizable window focused exclusively on the "private fork" task.  
* **Modal Settings**: Settings will be accessed via a standard macOS modal sheet or a separate settings window, keeping the main interface clean.  
* **Clear Status Feedback**: The user must always know what the app is doing. A simple text label or a subtle progress indicator will provide real-time feedback during the operation.

### **Core Screens and Views**

* **Main View**: Contains the repository URL input, local folder selector, the main action button, and the status display.  
* **Settings View**: Contains fields for GitHub credentials, the validate/save button, and the clear button.

### **Accessibility: WCAG AA**

The application should meet WCAG AA standards, ensuring it is usable by people with disabilities. This includes support for keyboard navigation, VoiceOver, and sufficient color contrast.

### **Branding**

The application will have a clean, minimalist design that aligns with the standard macOS aesthetic. It will not have heavy branding. The app icon should be simple and clearly represent its function (e.g., a combination of a fork and a lock symbol).

### **Target Device and Platforms: Desktop Only**

This is a native macOS application. It does not need to be responsive for other platforms.

## **Technical Assumptions**

### **Repository Structure: Single Repository**

The entire application, including all its code and resources, will be contained within a single Git repository.

### **Service Architecture: Self-contained Native Application**

The application is a standalone macOS utility. It will communicate directly with the GitHub API for its operations. There is no separate backend service to build or maintain.

### **Testing Requirements: Unit \+ Integration**

The project will require both unit tests for individual components and logic, as well as integration tests to verify the end-to-end automation flow, including interactions with the command-line git and the GitHub API. **The entire test suite must be fully automated and executable with a single command (e.g., swift test) to support an agentic development loop (code \-\> build \-\> test \-\> debug).**

### **Additional Technical Assumptions and Requests**

- **Language/Framework:** The application will be built natively for macOS using Swift and SwiftUI.  
- **Core Logic (MVP):** The initial version will wrap and execute standard command-line git operations. It will not use a native Git library.  
- **Authentication (MVP):** GitHub API access will be handled via a user-provided Personal Access Token (PAT). OAuth is out of scope for the MVP.  
- **Secure Storage:** The GitHub PAT must be stored securely in the native macOS Keychain.  
- **Development Model:** The application will be implemented by an LLM coding assistant, under the direction of a user with no prior Swift coding experience. This implies that code must be clear, conventional, and well-documented.  
- **Scope Limitation:** The utility is intended exclusively for creating private forks of **public** GitHub repositories.

## **Epic List**

* **Epic 1: Core Private Fork Utility:** Deliver a fully functional macOS application that reliably performs the private fork operation via both a GUI and a CLI, including secure credential storage and clear user feedback.

## **Epic 1 Core Private Fork Utility**

The goal of this epic is to deliver the complete MVP. This includes the foundational project setup, the user interface for both the main action and settings, secure credential handling, and the core automation logic accessible from both the GUI and a command-line interface.

### **Story 1.1 Project Foundation and Setup**

As a developer, I want a new, properly structured Swift application in a Git repository, so that I have a clean foundation to start building the app.

#### **Acceptance Criteria**

1. A new Swift application is created, targeting macOS.  
2. The project is initialized as a Git repository with a .gitignore file suitable for Swift/macOS development.  
3. The project includes a basic, empty SwiftUI view as the main application entry point.  
4. The project can be built and run successfully, displaying the empty main view.  
5. An automated test suite is set up and can be executed via a single command.

### **Story 1.2 Secure Credential Management**

As a user, I want to securely save my GitHub credentials in the app, so that I don't have to enter them every time I use the utility.

#### **Acceptance Criteria**

1. A Settings view is created with fields for "GitHub Username" and "Personal Access Token".  
2. A "Validate & Save" button exists on the Settings view.  
3. Clicking "Validate & Save" with valid credentials successfully saves the username and PAT to the macOS Keychain.  
4. Clicking "Validate & Save" with invalid credentials displays a clear error message to the user and does not save the credentials.  
5. A "Clear" button on the Settings view removes any saved credentials from the Keychain.  
6. The Settings view is accessible from the main application view (e.g., via a settings button or menu item).

### **Story 1.3 Main User Interface**

As a user, I want a simple and intuitive interface, so that I can perform the private fork operation quickly and without confusion.

#### **Acceptance Criteria**

1. The main application view contains a text input field for the public repository URL.  
2. The main view contains a button that, when clicked, opens a native file-chooser dialog to select a local directory.  
3. The selected local directory path is displayed in the UI.  
4. The main view contains a "Create Private Fork" button.  
5. The main view contains a text area or label to display real-time status updates.  
6. All UI elements adhere to standard macOS design conventions and support both light and dark modes.  
7. A status message appears near the URL field in real-time, indicating if the entered text is a valid GitHub URL.  
8. An indicator is present on the main view to show whether GitHub credentials have been saved. If not saved, a message invites the user to configure them in settings. This indicator updates immediately when credentials are saved or cleared.  
9. The repository URL input, folder selector button, and "Create Private Fork" button are disabled/greyed-out until valid GitHub credentials have been saved.

### **Story 1.4 Core Automation Logic via CLI**

As a power user, I want to be able to run the private fork operation from the command line, so that I can integrate it into scripts and automated workflows.

#### **Acceptance Criteria**

1. The application can be launched from the terminal.  
2. The application accepts command-line arguments for the public repository URL and the local destination path.  
3. When launched with the required arguments, the app performs the entire private fork automation process without showing a GUI.  
4. The core logic successfully creates a private repo, clones the public repo, configures remotes, and pushes to the new private origin.  
5. The process prints status updates to the standard output (e.g., "Cloning...", "Success\!").  
6. The process exits with a non-zero status code if any step in the automation fails.  
7. If the CLI is launched without credentials having been configured in the Keychain, it prints a clear error message and instructs the user to launch the GUI to configure them.

### **Story 1.5 GUI and Core Logic Integration**

As a user, I want to click the "Create Private Fork" button in the app and have it perform the complete operation, so that I can use the graphical interface to manage the process.

#### **Acceptance Criteria**

1. Clicking the "Create Private Fork" button triggers the core automation logic.  
2. The application uses the URL from the input field and the selected local path as parameters for the logic.  
3. The application retrieves the saved GitHub credentials from the Keychain to authenticate.  
4. During the operation, real-time status updates from the core logic are displayed in the main view's status label.  
5. Upon successful completion, a "Success\!" message is displayed.  
6. The "Create Private Fork" button is disabled while an operation is in progress.

### **Story 1.6 Comprehensive Error Handling**

As a user, I want the application to provide clear and helpful feedback when something goes wrong, so that I can understand the problem and how to fix it.

#### **Acceptance Criteria**

1. If the user attempts to initiate a fork operation without having first configured credentials (e.g., if the UI lock in Story 1.3 were to fail), a clear error message is displayed.  
2. If the GitHub API returns an error during the operation (e.g., invalid PAT, repo not found), a user-friendly error message is displayed.  
3. If any of the command-line git operations fail, a user-friendly error message is displayed.  
4. If there is a network failure during the operation, a corresponding error message is shown.  
5. All error messages are displayed clearly in the main UI and do not crash the application.