# **Tech Stack**

This table defines the specific technologies and libraries that will be used to build the application. These choices are definitive and must be adhered to during development to ensure consistency.

| Category | Technology | Version | Purpose | Rationale |
| :---- | :---- | :---- | :---- | :---- |
| **Framework** | SwiftUI | 5.0+ | UI, State Management | Native, modern, declarative framework for macOS. Ensures optimal performance and system integration. |
| **Language** | Swift | 5.10+ | Core Application Logic | The standard, safe, and high-performance language for Apple platforms. |
| **Build Tool** | Xcode | 16+ | Compilation, Building | The standard IDE and build system for macOS development. |
| **Testing** | XCTest | Included | Unit & Integration Testing | The native testing framework, ensuring tight integration with Xcode and the build process. |
| **Linting** | SwiftLint | Latest | Code Style & Quality | Enforces consistent code style and best practices, crucial for maintainability with agent-based development. |
| **Automation** | XcodeBuildMCP | Latest | Build/Test Automation | Provides a robust set of command-line tools for building, testing, and interacting with Xcode projects, enabling an automated dev loop. |
| **Dependencies** | None (for MVP) | N/A | N/A | To maintain a lightweight footprint and avoid external reliance, the MVP will use native Apple frameworks exclusively. |
