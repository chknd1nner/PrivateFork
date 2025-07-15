# **PrivateFork UI/UX Specification**

## **Introduction**

This document defines the user experience goals, information architecture, user flows, and visual design specifications for the Native Mac Private Fork App's user interface. It serves as the foundation for visual design and frontend development, ensuring a cohesive and user-centered experience.

### **Change Log**

| Date | Version | Description | Author |
| :---- | :---- | :---- | :---- |
| July 15, 2025 | 1.0 | Initial Draft | Sally, UX Expert |

### **Overall UX Goals & Principles**

**1. Target User Personas**

- **The Solo Indie Developer:** A technically proficient power user who values speed, efficiency, and a no-fuss workflow. They want to get the job done and get back to coding.  
- **The Student/Learner:** A user who may be less familiar with complex Git workflows. They need a straightforward, non-intimidating process that just works.  
- **The Startup Developer:** A resourceful developer who needs to quickly and privately evaluate or adapt public code for commercial use, prioritizing speed and IP protection.

**2. Usability Goals**

- **Speed:** The entire process, from launching the app to a successful fork, should feel significantly faster than the manual CLI method.  
- **Simplicity:** The interface should be self-explanatory, requiring zero learning curve. The user should instantly understand what to do.  
- **Reliability:** The user must trust that the app will perform the operation correctly every single time, without errors.  
- **Clarity:** Provide clear, real-time feedback about what the application is doing at every step of the process.

**3. Design Principles**

1. **Effortless Efficiency:** Every design choice should aim to reduce clicks, cognitive load, and time to completion. The tool should feel like an extension of the user's thoughts.  
2. **Native Fidelity:** The application must look, feel, and behave like a first-party macOS application. It should respect all system-level conventions, including light/dark mode, standard controls, and accessibility features.  
3. **Informative Minimalism:** The UI should be clean and uncluttered, presenting only what is necessary for the task. Feedback and status updates should be clear but unobtrusive.

## **Information Architecture (IA)**

The application's architecture is designed for a single, focused task. It consists of a primary view for the core action and a secondary view for configuration.

### **Site Map / Screen Inventory**

graph TD  
    A\[Main View\] \--\> B{Settings};  
    subgraph App  
        A  
        B  
    end

### **Navigation Structure**

- **Primary Navigation:** There is no complex primary navigation. The application launches directly into the Main View.  
- **Secondary Navigation:** Access to the Settings View will be provided through a standard macOS mechanism, such as a "Settings" button in the main window's toolbar or a "Preferences..." item in the application's menu bar (Cmd \+ ,). The settings view will likely be presented as a modal sheet attached to the main window.

## **User Flows**

### **Flow 1: First-Time Setup & Credential Configuration**

- **User Goal:** To securely save their GitHub credentials so the application can perform actions on their behalf.  
- **Entry Points:** User launches the app for the first time, or clicks the "Settings" button.  
- **Success Criteria:** Valid GitHub credentials are saved to the macOS Keychain, and the main UI becomes active and ready for use.

#### **Flow Diagram**

graph TD  
    A\[Launch App\] \--\> B{Check Keychain for Credentials};  
    B \--\>|Not Found| C\[Display Main View\];  
    C \--\> D\[User Clicks Settings\];  
    D \--\> E\[Show Settings View\];  
    E \--\> F\[User Enters Username & PAT\];  
    F \--\> G\[Clicks 'Validate & Save'\];  
    G \--\> H{Call GitHub API to Validate};  
    H \--\>|Invalid| I\[Show Error Message\];  
    I \--\> F;  
    H \--\>|Valid| J\[Save to Keychain\];  
    J \--\> L\[Update Main View to 'Ready' State\];  
    L \--\> K\[User Dismisses Settings View\];

- **Notes:** The main view will be disabled (greyed-out) with a clear message prompting the user to add their credentials until they are successfully saved. The "Clear" button in the Settings view would trigger a separate flow to remove credentials.

### **Flow 2: Creating a Private Fork**

- **User Goal:** To create a private, mirrored fork of a public GitHub repository with a single action.  
- **Entry Points:** User interacts with the Main View when credentials have been saved.  
- **Success Criteria:** A new private repository exists on GitHub, the code is cloned locally with correctly configured remotes, and the user receives a clear success message.

#### **Flow Diagram**

graph TD  
    A\[App in 'Ready' State\] \--\> B\[User Enters Public Repo URL\];  
    B \--\> C\[User Selects Local Destination\];  
    C \--\> D\[Clicks 'Create Private Fork'\];  
    D \--\> E\[UI Disables, Status: 'Starting...'\];  
    E \--\> F{Perform Automation Sequence};  
    F \--\>|On Error| G\[Show Specific Error Message\];  
    G \--\> H\[UI Re-enables\];  
    F \--\>|On Success| I\[Status: 'Success\!'\];  
    I \--\> H;

    subgraph Automation Sequence  
        F1\[Create Private Repo on GitHub\]  
        F2\[Clone Public Repo Locally\]  
        F3\[Configure Remotes\]  
        F4\[Push to Private Repo\]  
    end

    E \--\> F1 \--\> F2 \--\> F3 \--\> F4 \--\> I;

- **Edge Cases & Error Handling:** The flow must handle errors at each step of the automation sequence (e.g., invalid URL, network failure, Git command fails, permissions issue) and present a user-friendly message explaining what went wrong.

## **Wireframes & Mockups**

This section provides low-fidelity descriptions of the key screens, outlining their layout and components.

### **Key Screen Layouts**

#### **Main View**

- **Purpose:** The primary interface for the application's core function.  
- **Layout:** A single, compact, non-resizable window with a vertical layout.  
- **Key Elements:**  
  1. **Credentials Status:** A small, unobtrusive text label or icon at the top.  
     - *Initial State:* "⚠️ GitHub credentials not set. Please configure in Settings." (This text could be a button that opens the settings view).  
     - *Ready State:* "✅ Credentials configured for user: \[GitHub Username\]".  
  2. **Public Repository URL:** A standard macOS text field with a placeholder text like "Paste public GitHub repository URL". A small status icon (e.g., a checkmark or 'x') will appear next to it to indicate if the entered URL is valid.  
  3. **Local Destination:** A horizontal group containing:  
     - A text field displaying the selected local path (read-only). Placeholder: "Choose local destination folder".  
     - A "Choose..." button that opens the native file/folder selector.  
  4. **Status Display:** A multi-line text label below the inputs.  
     - *Idle State:* "Ready."  
     - *In-Progress State:* Displays real-time updates like "Cloning repository...", "Creating private repo on GitHub...", etc.  
     - *Success State:* "Success\! Private fork created at \[local path\]."  
     - *Error State:* Displays a user-friendly error message, e.g., "Error: Invalid GitHub credentials. Please check Settings."  
  5. **Primary Action Button:** A prominent "Create Private Fork" button at the bottom. This button will be disabled until valid credentials are saved, a valid URL is entered, and a local destination is chosen.

#### **Settings View**

- **Purpose:** To configure and securely store the user's GitHub credentials.  
- **Layout:** A modal sheet that slides down from the top of the main window.  
- **Key Elements:**  
  1. **GitHub Username:** A standard text field for the user's GitHub username.  
  2. **Personal Access Token (PAT):** A secure text field (masks input) for the GitHub PAT. A small help button or link next to it could direct users to GitHub's documentation on creating a PAT.  
  3. **Action Buttons:** A horizontal group of buttons at the bottom:  
     - **Clear:** Removes saved credentials from the Keychain. This button is only enabled if credentials exist.  
     - **Cancel:** Dismisses the settings view without saving changes.  
     - **Validate & Save:** The primary action button. Triggers the validation flow.

## **Component Library / Design System**

- **Design System Approach:** We will not use a third-party component library. Instead, we will exclusively use native SwiftUI components to ensure the application adheres to the standard macOS look and feel and respects all system-level settings (e.g., light/dark mode, accessibility options).

### **Core Components**

#### **Button**

- **Purpose:** To trigger actions.  
- **Variants:**  
  - **Primary Action (Create Private Fork, Validate & Save):** A standard prominent button (.keyboardShortcut(.defaultAction)). It will be the default button in its view.  
  - **Standard Action (Choose..., Settings):** A regular push button.  
  - **Destructive Action (Clear):** A standard button styled with a destructive role (.tint(.red)) to indicate its action.  
- **States:**  
  - **Disabled:** The button will be visually greyed-out and non-interactive when its action cannot be performed (e.g., "Create Private Fork" before all inputs are valid).  
  - **Enabled:** Standard interactive state.  
  - **Pressed:** Standard visual feedback on click.

#### **Text Field**

- **Purpose:** To accept user input for text values.  
- **Variants:**  
  - **Standard (Public Repository URL, GitHub Username):** A standard TextField.  
  - **Secure (Personal Access Token):** A SecureField that masks the user's input.  
  - **Read-Only (Local Destination):** A TextField that is disabled for user input, serving only as a display.  
- **Usage Guidelines:** All text fields should have clear placeholder text. They should use standard macOS focus rings and selection styling.

#### **Label**

- **Purpose:** To display static or dynamic text information.  
- **Variants:**  
  - **Status Display:** A Text view that can display multiple lines. Its color will change based on the state (e.g., green for success, red for error, standard text color for informational).  
  - **Credential Status:** A Label view, combining an icon (e.g., SF Symbols checkmark.circle or exclamationmark.triangle) with text for a compact status indicator.  
- **Usage Guidelines:** Use system fonts and colors to ensure consistency with the operating system.

## **Branding & Style Guide**

### **Visual Identity**

- **Brand Guidelines:** The application will have a **simple, modern visual identity** that is native to macOS. It will not have heavy, custom branding and will prioritize clarity and function over decoration.

### **Color Palette**

- **Usage:** We will use the standard macOS semantic system colors. This ensures the app automatically supports Light and Dark Mode and meets system accessibility standards.  
  - **Primary Text:** Color.primary  
  - **Secondary Text:** Color.secondary  
  - **Success Status:** Color.green  
  - **Warning/Error Status:** Color.red  
  - **Borders & Backgrounds:** Standard system background and separator colors.

### **Typography**

- **Font Families:**  
  - **Primary:** The standard macOS system font (San Francisco). The app will use SwiftUI's default font settings (.font(.body), .font(.headline), etc.) to ensure consistency.  
- **Type Scale:**  
  - **Main Headings (e.g., in Settings):** .font(.headline)  
  - **Body Text / Labels:** .font(.body)  
  - **Captions / Status Text:** .font(.caption)

### **Iconography**

- **App Icon:** The app icon should be clean and symbolic. A concept combining a **fork symbol** and a **lock symbol** would clearly communicate the app's purpose.  
- **In-App Icons:** We will exclusively use **SF Symbols**, Apple's extensive library of icons that are designed to integrate perfectly with the system font and support accessibility features.

### **Spacing & Layout**

- **Grid System:** No complex grid system is needed. Layouts will be achieved using standard SwiftUI stacks (VStack, HStack, ZStack).  
- **Spacing Scale:** A consistent 8-point spacing scale will be used for padding and margins to ensure visual harmony (e.g., 4pt, 8pt, 12pt, 16pt, 24pt).

## **Accessibility Requirements**

### **Compliance Target**

- **Standard:** Web Content Accessibility Guidelines (WCAG) 2.1 Level AA.

### **Key Requirements**

- **Visual:**  
  - **Color Contrast:** Not applicable as we are using standard system colors which automatically manage contrast ratios.  
  - **Focus Indicators:** All interactive elements must show a clear, standard macOS focus ring when navigated to via the keyboard.  
- **Interaction:**  
  - **Keyboard Navigation:** Full application functionality must be achievable using only the keyboard. Tabbing order must be logical and follow the visual layout.  
  - **Screen Reader Support:** All controls, labels, and status updates must be properly labeled for VoiceOver to announce their purpose and state. Dynamic status updates must be communicated to VoiceOver users.  
- **Content:**  
  - **Form Labels:** Every text field must have a clear, programmatically associated label.  
  - **Alternative Text:** All icons that convey information must have an accessibility label describing their function (e.g., the credential status icon).

### **Testing Strategy**

- **Automated:** Use Xcode's Accessibility Inspector to identify common issues.  
- **Manual:** Perform regular testing using only keyboard navigation and with VoiceOver enabled to ensure a usable experience.

## **Responsiveness Strategy**

As a native macOS application with a fixed-size window, a traditional "responsiveness" strategy with breakpoints is not required. The application's layout will be static. However, it will adhere to macOS conventions for window management and will support features like full-screen mode if applicable, ensuring the layout remains centered and usable.