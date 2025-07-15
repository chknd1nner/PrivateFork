# **Requirements**

## **Functional**

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

## **Non-Functional**

1. The application should be lightweight and feel responsive to user input.  
2. The GitHub Personal Access Token (PAT) must be stored securely in the native macOS Keychain.  
3. The core automation process should have a success rate higher than 99%.  
4. The core automation process should, on average, complete in under 30 seconds for a typical repository.  
5. The application must gracefully handle and clearly communicate errors to the user, including but not limited to: invalid PAT, network failures, and git command failures.  
6. For the MVP, the application will rely on the user having git installed and available in their system's PATH.
