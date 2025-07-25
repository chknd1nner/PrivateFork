# Source Tree Integration

## Existing Project Structure

PrivateFork/
├── Application/
├── Assets.xcassets/
├── Controllers/
├── Models/
├── Services/
│   ├── Implementations/
│   └── Protocols/
├── Utilities/
├── ViewModels/
└── Views/

## New File Organization

PrivateFork/
├── Application/
├── Assets.xcassets/
├── Controllers/
├── Models/
├── Services/
│   ├── Implementations/
│   │   ├── AuthService.swift
│   │   └── NativeGitService.swift
│   └── Protocols/
│       ├── AuthServiceProtocol.swift
│       └── NativeGitServiceProtocol.swift
├── Utilities/
├── ViewModels/
└── Views/

## Integration Guidelines

-   [cite_start]**File Naming:** New files will follow the existing naming conventions. [cite: 260]
-   [cite_start]**Folder Organization:** New services will be placed in the `Services/Implementations` and `Services/Protocols` directories. [cite: 261]
-   [cite_start]**Import/Export Patterns:** New services will be integrated using the existing dependency injection pattern. [cite: 262]
