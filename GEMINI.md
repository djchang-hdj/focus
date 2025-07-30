# GEMINI.MD: AI Collaboration Guide

This document provides essential context for AI models interacting with this project. Adhering to these guidelines will ensure consistency and maintain code quality.

## 1. Project Overview & Purpose

* **Primary Goal:** This is a Flutter application designed to help users focus by combining a to-do list with a Pomodoro timer.
* **Business Domain:** Productivity, Time Management, Personal Development.

## 2. Core Technologies & Stack

* **Languages:** Dart
* **Frameworks & Runtimes:** Flutter
* **Databases:** The project uses `shared_preferences` for persistent, local key-value storage. No external database is configured.
* **Key Libraries/Dependencies:**
    * `provider`: For state management.
    * `shared_preferences`: For data persistence.
    * `intl`: For internationalization and date formatting.
    * `uuid`: For generating unique identifiers.
* **Package Manager(s):** Flutter's default package manager (pub).

## 3. Architectural Patterns

* **Overall Architecture:** The application follows a reactive, state management-driven architecture, which is standard for Flutter applications. It uses the Provider pattern for managing application state.
* **Directory Structure Philosophy:**
    * `/lib`: Contains all primary Dart source code.
    * `/lib/main.dart`: The main entry point of the application.
    * `/lib/models`: Contains the data model classes (e.g., `task.dart`).
    * `/lib/providers`: Holds the state management logic using the Provider package (e.g., `task_provider.dart`, `theme_provider.dart`).
    * `/lib/theme`: Contains theme and styling information (`app_theme.dart`).
    * `/lib/widgets`: Contains reusable UI components (e.g., `task_list.dart`, `focus_timer.dart`).
    * `/assets`: Contains static assets such as fonts and icons.
    * `/test`: Contains all unit and widget tests.

## 4. Coding Conventions & Style Guide

* **Formatting:** The project follows the standard Dart and Flutter style guides, enforced by the `flutter_lints` package as defined in `analysis_options.yaml`.
* **Naming Conventions:**
    * `variables`, `functions`: camelCase (`myVariable`)
    * `classes`, `components`: PascalCase (`MyClass`)
    * `files`: snake_case (`my_widget.dart`)
* **API Design:** Not applicable, as this is a client-side application.
* **Error Handling:** Asynchronous operations primarily use `try...catch` blocks for error handling, particularly within the provider classes when performing data operations.

## 5. Key Files & Entrypoints

* **Main Entrypoint(s):** `lib/main.dart`
* **Configuration:**
    * `pubspec.yaml`: Manages project dependencies, assets, and metadata.
    * `analysis_options.yaml`: Configures static analysis and linting rules.
* **CI/CD Pipeline:** No CI/CD pipeline is configured for this project.

## 6. Development & Testing Workflow

* **Local Development Environment:** To run the project locally, use the standard Flutter command: `flutter run`.
* **Testing:** Tests are run using the `flutter test` command. The project includes a basic widget test in `test/widget_test.dart`. New features should be accompanied by corresponding tests.
* **CI/CD Process:** Not applicable.

## 7. Specific Instructions for AI Collaboration

* **Contribution Guidelines:** No formal `CONTRIBUTING.md` file was found. Follow existing patterns and conventions.
* **Infrastructure (IaC):** Not applicable.
* **Security:** Be mindful of security best practices. Do not hardcode any sensitive information. Since the app uses local storage, be cautious with any sensitive user data.
* **Dependencies:** To add a new dependency, use the `flutter pub add <package_name>` command.
* **Commit Messages:** Based on the existing git history, commit messages are short, simple, and written in a lowercase imperative style (e.g., `add icon`, `redesign`).

## 8. AI Coding Principles

This project adheres to the "Simple-First AI Coding Principles". The core philosophy is to build simple, clear, and composable systems.

*   **Start Small:** Begin with the smallest possible working unit (e.g., a core data structure or a pure function) and build incrementally.
*   **Separate Concerns:** Strictly separate data definitions, pure data transformations, side effects (I/O, state), and presentation (UI). Each part should have a single responsibility and be testable in isolation.
*   **Build in Layers:** Follow a sequential development process:
    1.  **Make it exist:** Define data models.
    2.  **Make it work:** Implement core logic.
    3.  **Make it safe:** Add validation.
    4.  **Make it convenient:** Add helper functions.
    5.  **Make it fast:** Optimize only when necessary.
*   **Compose Functions:** Create complex behaviors by combining small, pure functions.
*   **Be Explicit:** Make data flow visible and easy to trace. Avoid implicit operations and hidden state.
*   **Prefer Values:** Use immutable data structures and pure functions that create new values rather than modifying existing ones.
*   **Local Reasoning:** Write code that can be understood from its immediate context without needing global knowledge.