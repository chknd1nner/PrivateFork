# **Project Brief: PrivateFork**

Document Version: 1.0  
Date: July 15, 2025  
Author: Mary, Business Analyst

## **1 Executive Summary**

- **Product Concept**: A native macOS utility that automates the creation of a private, mirrored fork of any public GitHub repository.  
- **Primary Problem**: For solo indie developers, the standard GitHub fork is public. Creating a truly private mirror requires a series of manual, repetitive, and error-prone command-line steps for each repository, wasting valuable development time.  
- **Target Market**: Solo indie developers and other power users who frequently need to create private copies of public repositories for experimentation, modification, or private use.  
- **Key Value Proposition**: To transform a multi-step, manual command-line process into a simple, reliable, one-click action within an intuitive native Mac interface, saving developers time and reducing friction.

## **2 Problem Statement**

The core problem lies in the disjointed and manual workflow required to create a private mirror of a public GitHub repository. While GitHub's standard "fork" feature is simple, it is insufficient for developers needing privacy, as it creates a public fork by default.

For a solo indie developer, the current workaround involves a multi-step process that breaks their development flow:

1. **Manual Cloning**: The developer must use a specific git clone command to fetch the repository.  
2. **UI Context Switch**: They must then leave the command line, navigate to the GitHub website, and manually create a new, empty private repository.  
3. **Complex Configuration**: Back in the command line, they need to correctly configure the local clone's remotes, setting upstream to the original public repository and origin to their new private one. This step is prone to typos and configuration errors.  
4. **Final Push**: Finally, they must execute the correct git push command to send the code to their new private origin.

This process is not only tedious and repetitive but also introduces unnecessary cognitive load. A single mistake can lead to frustrating troubleshooting, turning a simple goal into a multi-minute chore that disrupts concentration.

## **3 Proposed Solution**

The proposed solution is a native macOS application that acts as a streamlined "private fork" utility for GitHub. The application will provide a simple, single-window interface where a developer can:

1. Paste the URL of the public GitHub repository they wish to clone.  
2. Select a destination folder on their local machine.  
3. Click a single button, such as "Create Private Fork".

Upon clicking the button, the application will seamlessly perform all the necessary actions in the background:

- Authenticate with the user's GitHub account.  
- Create a new private repository on their GitHub account.  
- Clone the public repository to the specified local folder.  
- Correctly configure the origin and upstream remotes.  
- Perform the initial push to the new private repository.

The core of the solution is to abstract away the complexity and potential for error, transforming a tedious manual workflow into an effortless, single-action task. By providing a native macOS experience, the app will feel like a natural extension of the developer's toolkit, integrating smoothly into their existing environment.

## **4 Target Users**

### **Primary User Segment: The Solo Indie Developer**

- **Profile**: A technically proficient developer working on personal or small-scale commercial projects. They are self-reliant, manage their own infrastructure, and are highly motivated to find tools that increase their productivity.  
- **Behaviors**: Spends the majority of their time in a code editor and on the command line. Frequently explores public, open-source repositories for code, inspiration, or libraries to integrate into their own work.  
- **Needs & Pain Points**: Needs to quickly and privately experiment with or modify public code without the overhead of maintaining a public fork. The current manual process is a frequent, low-level annoyance that interrupts their creative and development flow.  
- **Goals**: To minimize time spent on administrative "yak shaving" and maximize time spent on the core work of building their applications.

### **Secondary User Segment: Students & Learners**

- **Profile**: Individuals learning software development in academic or self-taught settings. They are often new to advanced git workflows.  
- **Behaviors**: Frequently clones public example projects and tutorials to study the code or use as a starting point for assignments.  
- **Needs & Pain Points**: Needs to maintain a private version of their work for academic integrity or to avoid public scrutiny of their learning process. The manual forking process can be intimidating and adds a layer of complexity when they are focused on learning core programming concepts.  
- **Goals**: To easily create a private workspace for their projects without getting sidetracked by complex git commands, allowing them to focus on their coursework and coding skills.

### **Secondary User Segment: Developer at a Small Startup**

- **Profile**: A developer working in a small, fast-paced team. They are resourceful and often leverage open-source solutions to accelerate development.  
- **Behaviors**: Explores public repositories to find tools or libraries that can be adapted for internal, proprietary use. Needs to bring public code into the company's private ecosystem for evaluation or modification.  
- **Needs & Pain Points**: Requires a method to "internalize" a public repository while keeping all modifications and usage private to protect company IP. The manual process is an inefficient use of time in a resource-constrained startup environment.  
- **Goals**: To rapidly evaluate and adapt public code for private commercial use without exposing the company's technical strategy or creating administrative overhead.

## **5 Goals & Success Metrics**

### **Business Objectives**

- **Solve a Personal Pain Point**: Create a high-quality, reliable tool that the creator personally uses regularly to streamline their own development workflow.

### **User Success Metrics**

- **Time Saved**: The user perceives a significant reduction in the time and effort required to create a private fork compared to the manual method.  
- **Reduced Cognitive Load**: The user no longer needs to remember the specific sequence of git commands and can complete the task without breaking their focus.  
- **Increased Confidence**: The user trusts the app to perform the operation correctly every time, eliminating the worry of making a mistake.  
- **Workflow Integration**: The app feels like a natural and indispensable part of the user's development toolkit.

### **Key Performance Indicators (KPIs)**

- **Successful Operations Rate**: \>99% of "private fork" attempts complete without any errors.  
- **Average Operation Time**: The time from button click to success is consistently fast (e.g., under 30 seconds).  
- **Adoption & Retention**: The creator consistently chooses to use the app instead of reverting to the manual method.

## **6 MVP Scope**

### **Core Features (Must-Haves)**

1. **Repository URL Input**: A single text field to paste the public GitHub repository URL.  
2. **Local Folder Selector**: A button that opens a native macOS file dialog to choose the local destination folder.  
3. **Settings Screen**: A dedicated view with:  
   - Fields for GitHub Username and Personal Access Token (PAT).  
   - A "Validate & Save" button that confirms the credentials are valid and securely stores them using the macOS Keychain.  
   - A "Clear" button to remove the saved credentials.  
4. **"Create Private Fork" Button**: The main action button that uses the saved credentials to trigger the automation.  
5. **Status Display**: A simple, clear indicator to show real-time progress (e.g., "Cloning...", "Creating private repo...", "Success\!").

### **Out of Scope for MVP**

- OAuth-based authentication for GitHub.  
- Native library implementation for Git operations (will use CLI git).  
- Finder integration for right-click context menus.  
- Support for multiple GitHub accounts.  
- Integration with other Git providers (e.g., GitLab, Bitbucket).  
- A history log of previously forked repositories.  
- Advanced git options (e.g., choosing a specific branch, shallow cloning).

## **7 Post-MVP Vision**

This section outlines the potential future direction for the application beyond the initial release.

- **Phase 2 Features**: The immediate next step after a successful MVP would be to enhance the app's integration with the macOS environment.  
  - Develop a Finder Extension to allow users to right-click on a cloned repository folder and access app functions directly from the context menu, pre-populating the target folder path.  
- **Long-term Vision & Expansion Opportunities**: Further mature the application's core technology by replacing the initial implementation's dependencies.  
  - Implement native Git library operations (e.g., using a Swift package) to remove the dependency on the user's installed command-line Git, potentially communicating with the main app via XPC.  
  - Implement a more secure and user-friendly OAuth 2.0 flow for GitHub authentication, replacing the PAT method.

## **8 Technical Considerations**

This section documents initial technical thoughts and preferences to guide the architecture phase.

- **Platform Requirements**:  
  - **Target Platform:** macOS (specific version TBD, likely latest major version).  
  - **Performance Requirements:** The application should be lightweight and respond instantly.  
- **Technology Preferences**:  
  - **Frontend/App Framework:** Swift with SwiftUI.  
  - **Core Logic (MVP):** The initial version will wrap and execute standard command-line git operations.  
  - **Authentication (MVP):** GitHub API access will be handled via a user-provided Personal Access Token (PAT).  
- **Architecture Considerations**:  
  - **Repository Structure:** Single repository for the macOS application.  
  - **Service Architecture:** The app will be self-contained and communicate directly with the GitHub API.  
  - **Security/Compliance:** The PAT must be stored securely in the native macOS Keychain.

## **9 Constraints & Assumptions**

### **Constraints**

- **Cost**: Project costs are limited to LLM token consumption and AI-powered IDE subscriptions.  
- **Time**: Development is constrained by the personal time availability of the project director.

### **Key Assumptions**

- **Development Model**: The application will be entirely implemented by an LLM coding assistant, directed by a user with no prior Swift coding experience.  
- **Repository Scope**: The utility is intended exclusively for creating private forks of **public** GitHub repositories.

## **10 Risks & Open Questions**

- **LLM Implementation Risk**: There is a risk of the LLM generating non-functional or inefficient Swift/SwiftUI code. Debugging without direct language experience could be challenging.  
- **Dependency Risk**: The MVP's reliance on the command-line git tool means the app could fail if git is not installed or not in the system's PATH.  
- **Open Question - Error Handling**: How should the application gracefully handle and clearly communicate errors to the user (e.g., invalid PAT, network failures, git failures)?