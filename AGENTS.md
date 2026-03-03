# AGENTS.md - Developer Guide for flycode

This document provides essential guidelines for AI agents working on the flycode Flutter project.

## Project Overview

- **Framework**: Flutter 3.x with Dart SDK ^3.11.0
- **State Management**: Riverpod (flutter_riverpod, riverpod_annotation)
- **Code Generation**: build_runner (riverpod_generator, json_serializable)
- **Local Storage**: shared_preferences, sqflite
- **Routing**: go_router

## Build, Lint, and Test Commands

### Basic Commands
```bash
flutter pub get             # Get dependencies
flutter run                 # Run the app in debug mode
flutter analyze             # Run static analysis
dart format .               # Format all files
```

### Running Tests
```bash
flutter test                # Run all tests
flutter test test/path.dart # Run a single test file (Requested)
flutter test --name="name"  # Run a specific test by name
```

### Code Generation (CRITICAL)
Always run after modifying providers, models, or any files with `.g.dart` parts.
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Code Style Guidelines

### Naming Conventions
- **snake_case**: Files (`api_client.dart`), directories.
- **PascalCase**: Classes, Enums, Typedefs.
- **camelCase**: Variables, functions, methods, constants.
- **.g.dart**: Suffix for generated files.
- **_test.dart**: Suffix for test files.

### Imports
- Use **package imports** for external and cross-module files: `import 'package:flycode/models/server_config.dart';`
- Use **relative imports** for local files in the same or sub-directory.
- Use `part 'filename.g.dart';` for code generation.

### Formatting & Types
- Strictly follow `dart format .` (80 chars max).
- Use **trailing commas** in multi-line lists/parameters for better formatting.
- Always specify **return types** for functions.
- Use `final` for immutable variables; `var` for mutable locals with clear types.
- Prefer **single quotes** for strings.

### Error Handling
- Use custom `Exception` classes for domain errors.
- Wrap risky operations in `try-catch` with specific exception types.
- Use `AsyncValue` in Riverpod to handle async data states.

## Riverpod Best Practices
- Use **code generation** with `@riverpod` annotation for all providers.
- Use `ref.watch(provider)` for reactivity; `ref.read(provider.notifier)` for actions.
- Prefer `AsyncNotifier` for complex asynchronous state logic.
- Keep providers small and focused.

## JSON and Data Models
- Use `json_serializable` for API models (`lib/service/api/models`).
- Manually implement `fromJson`/`toJson` for simple local models if preferred.
- Always provide `copyWith` for immutable state updates.

## Project Structure
```
lib/
  app.dart            # Main app widget & Theme
  router.dart         # GoRouter configuration
  database/           # SQLite (database_helper.dart, DAOs)
  models/             # Business logic models
  pages/              # Screen widgets
  providers/          # Riverpod providers
  service/api/        # API clients and JSON models
  widgets/            # Reusable UI components
test/                 # Unit and widget tests
```

## Safety Checklist
- [ ] Run `flutter analyze` before committing.
- [ ] Run `dart run build_runner build` if any generated code changed.
- [ ] Use `const` constructors for widgets whenever possible.
- [ ] Ensure all new functions have explicit return types.
- [ ] Follow existing patterns in `lib/service/api` for new endpoints.
