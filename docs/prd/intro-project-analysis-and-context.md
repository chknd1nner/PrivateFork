# Intro Project Analysis and Context

## Existing Project Overview

### Analysis Source

[cite_start]This PRD is based on the comprehensive analysis of the existing MVP codebase documented in the PrivateFork Brownfield Architecture Document[cite: 5].

### Current Project State

[cite_start]PrivateFork is a native macOS application built with Swift and SwiftUI[cite: 7]. [cite_start]It currently functions as a simple utility with a GUI and CLI to fork a public GitHub repository to a user's account and clone it locally[cite: 8]. [cite_start]Authentication is handled via a user-provided Personal Access Token (PAT), which is stored securely in the macOS Keychain[cite: 9]. [cite_start]The application's architecture is service-oriented, but it relies on shelling out to the system's git command for local operations, which is a significant piece of technical debt[cite: 10].

## Documentation Analysis

### Available Documentation

[cite_start]The following documentation is available and has been used as a source for this PRD[cite: 13]:
- [x] [cite_start]Tech Stack Documentation [cite: 14]
- [x] [cite_start]Source Tree/Architecture [cite: 15]
- [x] [cite_start]API Documentation (inferred from code) [cite: 16]
- [x] [cite_start]Technical Debt Documentation [cite: 17]

## Enhancement Scope Definition

### Enhancement Type

- [x] [cite_start]New Feature Addition (OAuth) [cite: 20]
- [x] [cite_start]Major Feature Modification (Replacing shell-based Git with a native library, enhancing CLI) [cite: 21]

### Enhancement Description

This document outlines Phase 2 of PrivateFork development. [cite_start]The primary goals are to replace the PAT-based authentication with a more secure and user-friendly OAuth 2.0 flow, introduce a robust Command-Line Interface (CLI), and integrate native Git library functionality to replace the fragile shell wrapper[cite: 23].

### Impact Assessment

- [x] [cite_start]**Significant Impact**: This enhancement involves substantial changes to core components, including authentication and Git operations, touching almost every part of the existing application[cite: 25].

## Goals and Background Context

### Goals

- [cite_start]Provide a seamless and secure one-click authentication experience using GitHub OAuth 2.0, removing the need for manually managing Personal Access Tokens[cite: 28].
- [cite_start]Enable powerful automation and scripting workflows for developers by introducing a full-featured Command-Line Interface (CLI)[cite: 29].
- [cite_start]Boost the application's reliability and performance by replacing fragile shell commands with a robust, native Swift Git library[cite: 30].

### Background Context

[cite_start]The PrivateFork MVP successfully validated the core concept of a streamlined forking utility[cite: 32]. [cite_start]However, its reliance on PATs and shell commands presents significant security, usability, and reliability limitations[cite: 33]. [cite_start]Phase 2 aims to address this technical debt and evolve PrivateFork from a simple utility into a professional-grade developer tool that integrates seamlessly into daily workflows, whether in the GUI or the command line[cite: 34].

## Change Log

| Change | Date | Version | Description | Author |
| :--- | :--- | :--- | :--- | :--- |
| Refined Epic 2 Stories | 2025-07-24 | 1.5 | Re-sequenced stories in Epic 2 for logical dependency and testability. | Sarah (PO) |
| Hard Cutover to OAuth | 2025-07-24 | 1.4 | Decided on a hard cutover to OAuth, removing all PAT-related code and the Settings view. Locked in CLI scope. | Sarah (PO) |
| Updated UI Auth Method | 2025-07-24 | 1.3 | Specified segmented control for auth modes per user feedback. | Sarah (PO) |
| De-scoped Finder Extension | 2025-07-24 | 1.2 | Removed Finder Extension from Phase 2 to reduce risk and focus on core value. | Sarah (PO) |
| Refined Goals & Impact | 2025-07-24 | 1.1 | Refined goals to be user-centric and added detail to impact assessment. | Sarah (PO) |
| Initial Draft | 2025-07-24 | 1.0 | First draft of the Phase 2 Brownfield PRD. | Sarah (PO) |
