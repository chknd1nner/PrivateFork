# Tech Stack Alignment

## Existing Technology Stack

| Category | Current Technology | Version | Usage in Enhancement | Notes |
| :--- | :--- | :--- | :--- | :--- |
| Language | Swift | 5.x | Continue to use for all new development. | |
| UI | SwiftUI | | The existing UI will be updated to support the new authentication flow. | |
| Git Operations | Shell commands | | Will be replaced with a native Swift library. | This is a major source of technical debt that will be addressed in this phase. |

## New Technology Additions

| Technology | Version | Purpose | Rationale | Integration Method |
| :--- | :--- | :--- | :--- | :--- |
| SwiftGitX | Latest | Native Git operations | "A pure Swift, modern library that avoids the dependency and Apple Silicon compatibility issues associated with older C-based wrappers like SwiftGit2." | A new `GitService` implementation will be created to wrap the SwiftGitX library. |
| OAuthSwift | Latest | OAuth 2.0 authentication | "A robust, well-maintained library that simplifies OAuth flows, reducing implementation complexity and improving security over native solutions." | A new `AuthService` will be created to handle the OAuth flow using this library. |
| ArgumentParser | Latest | Modern CLI | To provide a more robust and user-friendly CLI experience. | The existing `main.swift` will be updated to use `ArgumentParser`. |

## Development Tooling Enhancements

| Tool | Version | Purpose | Rationale | Integration Method |
| :--- | :--- | :--- | :--- | :--- |
| XCodeMCP | Latest | Xcode project discovery, build automation, and testing | "Provides comprehensive Xcode toolchain integration including project discovery, build automation, simulator management, and test execution. Enables consistent build/test workflows across development environments." | Integrated via MCP (Model Context Protocol) for automated build, test, and deployment workflows. |
| SwiftLint | Homebrew | Code style enforcement and quality checks | "Industry-standard Swift linting tool that enforces consistent code style, identifies potential issues, and maintains code quality standards across the codebase." | Installed via Homebrew and integrated into build pipeline for automated code quality validation. |
| Zen | Latest | External LLM consultation for architectural decisions | "Provides access to external AI models for code review, architectural consensus building, and technical decision validation. Enhances development workflow with AI-powered insights." | Integrated via MCP for on-demand code review, architectural planning, and consensus building on technical decisions. |
