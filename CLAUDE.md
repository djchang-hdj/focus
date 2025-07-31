# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter productivity application called "focus" that combines a todo list with a Pomodoro timer. The app helps users manage tasks and maintain focus through time-boxed work sessions.

## Common Commands

### Development
```bash
# Run the application
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d windows
flutter run -d chrome
```

### Build
```bash
# Build for release
flutter build macos
flutter build windows
flutter build web
```

### Testing
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .
```

### Dependencies
```bash
# Add a new dependency
flutter pub add <package_name>

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade
```

## Architecture Overview

### State Management
The app uses Provider for state management with the following key providers:
- **TaskProvider** (`lib/providers/task_provider.dart`): Manages todo tasks with persistence via SharedPreferences
- **TimerProvider** (`lib/providers/timer_provider.dart`): Handles Pomodoro timer functionality with notification support
- **ThemeProvider** (`lib/providers/theme_provider.dart`): Controls app theme (light/dark mode)
- **SettingsProvider** (`lib/providers/settings_provider.dart`): Manages user preferences

### Data Flow
1. **Models** define data structures (`lib/models/`)
2. **Providers** handle business logic and state management (`lib/providers/`)
3. **Widgets** present UI and consume provider state (`lib/widgets/`)
4. **Pages** compose widgets into screens (`lib/pages/`)

### Key Features
- **Task Management**: Create, edit, complete, reorder, and move tasks between dates
- **Pomodoro Timer**: Customizable focus timer with visual progress (rainbow theme)
- **Notifications**: Local notifications for timer completion
- **Data Persistence**: Tasks and timer records saved locally using SharedPreferences
- **Theme Support**: Light and dark mode with Material 3 design

### Development Principles
The project follows "Simple-First AI Coding Principles" as outlined in `coding_rules.md`:
- Start with the smallest working unit
- Separate concerns (data, logic, effects, UI)
- Build in layers (exist → work → safe → convenient → fast)
- Compose functions rather than features
- Make everything explicit and traceable

### Platform-Specific Notes
- **macOS**: Notification permissions required for timer alerts
- **Windows**: Accessibility error logs disabled to prevent console spam
- **Web**: Progressive web app support with custom icons

### Testing Approach
- Widget tests are located in `test/`
- The default test template needs updating for actual app functionality
- New features should include corresponding tests