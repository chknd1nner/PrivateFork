# Introduction

[cite_start]This document outlines the architectural approach for enhancing the PrivateFork macOS application with Phase 2 features, including OAuth 2.0 authentication, a modernized CLI, and the replacement of the shell-based Git service with a native Swift library[cite: 148]. [cite_start]Its primary goal is to serve as the guiding architectural blueprint for AI-driven development of new features while ensuring seamless integration with the existing system[cite: 149].

[cite_start]**Relationship to Existing Architecture:** This document supplements the existing PrivateFork Brownfield Architecture Document by defining how new components will integrate with the current system[cite: 151]. [cite_start]Where conflicts arise between new and existing patterns, this document provides guidance on maintaining consistency while implementing enhancements[cite: 152].

## Existing Project Analysis

### Current Project State

-   [cite_start]**Primary Purpose:** PrivateFork is a native macOS application built with Swift and SwiftUI[cite: 155]. [cite_start]It currently functions as a simple utility with a GUI and CLI to fork a public GitHub repository to a user's account and clone it locally[cite: 156].
-   [cite_start]**Current Tech Stack:** Swift, SwiftUI, and shell commands for Git operations[cite: 157].
-   [cite_start]**Architecture Style:** The application's architecture is service-oriented, with a `PrivateForkOrchestrator` acting as a central coordinator for various services[cite: 158].
-   [cite_start]**Deployment Method:** The application is built and archived using standard Xcode processes, and deployment is likely manual[cite: 159].

### Available Documentation

-   [cite_start]PrivateFork Brownfield Architecture Document [cite: 161]
-   [cite_start]PrivateFork Brownfield Enhancement PRD [cite: 162]

### Identified Constraints

-   [cite_start]The application must continue to support both GUI and CLI modes[cite: 164].
-   [cite_start]The existing service-oriented architecture should be maintained and extended[cite: 165].
-   [cite_start]The new OAuth flow must be secure and user-friendly[cite: 166].
-   [cite_start]The replacement of the shell-based Git service should not introduce breaking changes to the existing user-facing functionality[cite: 167].

## Change Log

| Change | Date | Version | Description | Author |
| :--- | :--- | :--- | :--- | :--- |
| Library Update | 2025-07-25 | 1.1 | Updated technology choices for OAuth and Git libraries based on new research. | Winston (Architect) |
| Initial Draft | 2025-07-25 | 1.0 | Initial draft of the Phase 2 Brownfield Enhancement Architecture. | Winston (Architect) |
