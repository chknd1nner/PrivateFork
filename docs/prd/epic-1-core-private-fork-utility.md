# **Epic 1 Core Private Fork Utility**

The goal of this epic is to deliver the complete MVP. This includes the foundational project setup, the user interface for both the main action and settings, secure credential handling, and the core automation logic accessible from the GUI. CLI operation will be implemented in a future epic alongside OAuth integration.

## **Story 1.1 Project Foundation and Setup**

As a developer, I want a new, properly structured Swift application in a Git repository, so that I have a clean foundation to start building the app.

### **Acceptance Criteria**

1. A new Swift application is created, targeting macOS.  
2. The project is initialized as a Git repository with a .gitignore file suitable for Swift/macOS development.  
3. The project includes a basic, empty SwiftUI view as the main application entry point.  
4. The project can be built and run successfully, displaying the empty main view.  
5. An automated test suite is set up and can be executed via a single command.

## **Story 1.2 Secure Credential Management**

As a user, I want to securely save my GitHub credentials in the app, so that I don't have to enter them every time I use the utility.

### **Acceptance Criteria**

1. A Settings view is created with fields for "GitHub Username" and "Personal Access Token".  
2. A "Validate & Save" button exists on the Settings view.  
3. Clicking "Validate & Save" with valid credentials successfully saves the username and PAT to the macOS Keychain.  
4. Clicking "Validate & Save" with invalid credentials displays a clear error message to the user and does not save the credentials.  
5. A "Clear" button on the Settings view removes any saved credentials from the Keychain.  
6. The Settings view is accessible from the main application view (e.g., via a settings button or menu item).

## **Story 1.3 Main User Interface**

As a user, I want a simple and intuitive interface, so that I can perform the private fork operation quickly and without confusion.

### **Acceptance Criteria**

1. The main application view contains a text input field for the public repository URL.  
2. The main view contains a button that, when clicked, opens a native file-chooser dialog to select a local directory.  
3. The selected local directory path is displayed in the UI.  
4. The main view contains a "Create Private Fork" button.  
5. The main view contains a text area or label to display real-time status updates.  
6. All UI elements adhere to standard macOS design conventions and support both light and dark modes.  
7. A status message appears near the URL field in real-time, indicating if the entered text is a valid GitHub URL.  
8. An indicator is present on the main view to show whether GitHub credentials have been saved. If not saved, a message invites the user to configure them in settings. This indicator updates immediately when credentials are saved or cleared.  
9. The repository URL input, folder selector button, and "Create Private Fork" button are disabled/greyed-out until valid GitHub credentials have been saved.

## **Story 1.4 Core Automation Logic via CLI** *(DEFERRED - Future OAuth Epic)*

**Status**: Deferred to future epic for implementation alongside OAuth integration.
**Reason**: CLI operation requires non-interactive credential access to maintain automation value.

As a power user, I want to be able to run the private fork operation from the command line, so that I can integrate it into scripts and automated workflows.

### **Acceptance Criteria**

1. The application can be launched from the terminal.  
2. The application accepts command-line arguments for the public repository URL and the local destination path.  
3. When launched with the required arguments, the app performs the entire private fork automation process without showing a GUI.  
4. The core logic successfully creates a private repo, clones the public repo, configures remotes, and pushes to the new private origin.  
5. The process prints status updates to the standard output (e.g., "Cloning...", "Success\!").  
6. The process exits with a non-zero status code if any step in the automation fails.  
7. If the CLI is launched without credentials having been configured in the Keychain, it prints a clear error message and instructs the user to launch the GUI to configure them.

## **Story 1.5 GUI and Core Logic Integration**

As a user, I want to click the "Create Private Fork" button in the app and have it perform the complete operation, so that I can use the graphical interface to manage the process.

### **Acceptance Criteria**

1. Clicking the "Create Private Fork" button triggers the core automation logic.  
2. The application uses the URL from the input field and the selected local path as parameters for the logic.  
3. The application retrieves the saved GitHub credentials from the Keychain to authenticate.  
4. During the operation, real-time status updates from the core logic are displayed in the main view's status label.  
5. Upon successful completion, a "Success\!" message is displayed.  
6. The "Create Private Fork" button is disabled while an operation is in progress.

~~## **Story 1.6 Comprehensive Error Handling**~~ Complete - Implemented Organically

~~As a user, I want the application to provide clear and helpful feedback when something goes wrong, so that I can understand the problem and how to fix it.~~

~~### **Acceptance Criteria**~~

~~1. If the user attempts to initiate a fork operation without having first configured credentials (e.g., if the UI lock in Story 1.3 were to fail), a clear error message is displayed.~~  
~~2. If the GitHub API returns an error during the operation (e.g., invalid PAT, repo not found), a user-friendly error message is displayed.~~  
~~3. If any of the command-line git operations fail, a user-friendly error message is displayed.~~  
~~4. If there is a network failure during the operation, a corresponding error message is shown.~~  
~~5. All error messages are displayed clearly in the main UI and do not crash the application.~~