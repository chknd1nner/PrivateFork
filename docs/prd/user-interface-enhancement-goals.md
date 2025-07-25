# User Interface Enhancement Goals

## Integration with Existing UI

[cite_start]With the removal of PAT-based authentication, the **SettingsView will be completely removed** from the application[cite: 58]. [cite_start]All authentication functionality will be integrated directly into the MainView[cite: 59]. [cite_start]If a user is not authenticated, the main content area will be disabled, and a prominent "Sign in with GitHub" button will be displayed[cite: 60].

## Modified/New Screens and Views

-   [cite_start]**MainView (Modified)**: The view will be updated to handle two states[cite: 62]:
    -   [cite_start]**Authenticated State**: The existing UI for forking will be visible[cite: 63]. [cite_start]A "Log Out" button and the authenticated user's GitHub username will be displayed in a non-intrusive location (e.g., the bottom corner)[cite: 64].
    -   [cite_start]**Unauthenticated State**: The input fields and "Fork" button will be disabled[cite: 65]. [cite_start]A large, centered "Sign in with GitHub" button will be the primary call to action[cite: 66].
-   [cite_start]**SettingsView (Removed)**: This view, its associated ViewModel (SettingsViewModel), and all related tests will be deleted from the codebase[cite: 67].
-   [cite_start]**OAuth Device Flow View (New)**: A simple, non-interactive view or modal will be required to display the user code and the `github.com/login/device` URL during the device flow process[cite: 68].

## UI Consistency Requirements

[cite_start]All new UI elements (e.g., the login/logout buttons) must adhere to the existing minimalist design language of the application to ensure a cohesive user experience[cite: 70].
