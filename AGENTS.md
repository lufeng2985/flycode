# AGENTS.md - Developer Guide for flycode

This document provides guidelines for agents working on the flycode Flutter project.

## Project Overview

- **Framework**: Flutter 3.x with Dart SDK ^3.11.0
- **State Management**: Riverpod (flutter_riverpod, riverpod_annotation)
- **Code Generation**: build_runner with riverpod_generator and json_serializable
- **HTTP Client**: http package
- **Local Storage**: shared_preferences
- **Routing**: go_router

## Build, Lint, and Test Commands

### Running the Application

```bash
# Run the app in debug mode
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build for release
flutter build apk          # Android
flutter build ipa          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build linux        # Linux
flutter build windows      # Windows
```

### Linting and Analysis

```bash
# Run static analysis (Flutter lints via analysis_options.yaml)
flutter analyze

# Run with specific rules
flutter analyze --no-fatal-infos
flutter analyze --no-fatal-warnings
```

### Running Tests

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run a specific test by name
flutter test --name="Counter increments"

# Run tests with coverage
flutter test --coverage

# Run tests in debug mode with verbose output
flutter test -v
```

### Code Generation

```bash
# Generate .g.dart files for Riverpod and JSON serialization
dart run build_runner build

# Watch for changes and regenerate
dart run build_runner watch

# Delete generated files and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### Other Useful Commands

```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Format code
dart format .

# List available devices
flutter devices
```

## Code Style Guidelines

### File Naming

- Use **snake_case** for all Dart files: `server_config.dart`, `api_client.dart`
- Generated files end with `.g.dart`: `server_config_provider.g.dart`
- Test files end with `_test.dart`: `widget_test.dart`

### Class and Type Naming

- Use **PascalCase** for classes, enums, and typedefs:
  ```dart
  class ServerConfig { }
  enum ApiStatus { success, error }
  typedef ConfigCallback = void Function(Config);
  ```
- Use **camelCase** for variables, functions, and methods:
  ```dart
  final serverConfig = ServerConfig();
  void saveConfig(Config config) { }
  ```

### Constants and Enums

- Use **lowerCamelCase** for constant values:
  ```dart
  const String serverConfigKey = 'server_config';
  const defaultBaseUrl = 'http://localhost:4096';
  ```
- Use **PascalCase** for enum values:
  ```dart
  enum ApiStatus { success, failure, loading }
  ```

### Imports

- Use **package imports** for external packages:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:http/http.dart' as http;
  ```
- Use **relative imports** for local project files:
  ```dart
  import '../models/server_config.dart';
  import '../providers/server_config_provider.dart';
  ```
- Use `part` and `part of` for generated files:
  ```dart
  part 'server_config_provider.g.dart';
  ```

### Formatting

- Follow Dart's standard formatting (use `dart format .`)
- Maximum line length: 80 characters (recommended)
- Use trailing commas for better formatting in collections
- Use const constructors whenever possible
- Prefer single quotes for strings

### Type Annotations

- Always specify return types for functions and methods:
  ```dart
  Future<ServerConfig> loadConfig() async { }
  void saveConfig(ServerConfig config) { }
  ```
- Use type inference for local variables when clear:
  ```dart
  final prefs = await SharedPreferences.getInstance();
  final config = ServerConfig.defaultValue();
  ```
- Use `var` instead of explicit types for mutable locals:
  ```dart
  var config = ServerConfig.defaultValue();
  config = config.copyWith(baseUrl: 'http://new.url');
  ```

### Null Safety

- Use nullable types (`?`) sparingly and intentionally
- Use null-aware operators:
  ```dart
  final url = json['url'] as String? ?? 'default';
  final name = user?.name ?? 'Anonymous';
  ```
- Prefer late initialization over nullable when appropriate:
  ```dart
  late final ApiClient client;
  ```

### Error Handling

- Use custom exceptions for domain-specific errors:
  ```dart
  class ApiException implements Exception {
    final int statusCode;
    final String message;
    
    ApiException({required this.statusCode, required this.message});
    
    @override
    String toString() => 'ApiException: $statusCode - $message';
  }
  ```
- Use try-catch with specific exception types:
  ```dart
  try {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return ServerConfig.fromJson(json);
  } catch (e) {
    // Handle error appropriately
    return ServerConfig.defaultValue();
  }
  ```
- Use `rethrow` when needed:
  ```dart
  try {
    await _saveToDisk(data);
  } catch (e) {
    await _logError(e);
    rethrow;
  }
  ```

### Riverpod Providers

- Use code generation with `@riverpod` annotation:
  ```dart
  @riverpod
  class ServerConfigNotifier extends _$ServerConfigNotifier {
    @override
    Future<ServerConfig> build() async { ... }
  }
  ```
- Use `ref.watch` for reactive state, `ref.read` for one-time reads
- Prefer `AsyncValue` for async providers:
  ```dart
  final asyncConfig = ref.watch(serverConfigProvider);
  final config = asyncConfig.value ?? ServerConfig.defaultValue();
  ```

### JSON Models

- Implement `fromJson` and `toJson` manually or use json_serializable:
  ```dart
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      baseUrl: json['baseUrl'] as String,
      username: json['username'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      if (username != null) 'username': username,
    };
  }
  ```
- Use `copyWith` for immutable updates:
  ```dart
  ServerConfig copyWith({String? baseUrl}) {
    return ServerConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username,
      password: password,
    );
  }
  ```

### Widgets

- Use `const` constructors whenever possible
- Prefer composition over inheritance
- Extract widgets for reusable components
- Use meaningful names for callback parameters:
  ```dart
  void onConfigChanged(ServerConfig config) { }
  void onSavePressed() { }
  ```

### Testing

- Name test files with `_test.dart` suffix
- Use `testWidgets` for widget tests
- Use descriptive test names:
  ```dart
  testWidgets('displays loading indicator while fetching', ...);
  test('returns default config when storage is empty', ...);
  ```
- Use `expect` from flutter_test for assertions

### Project Structure

```
lib/
  main.dart           # App entry point
  app.dart            # MyApp widget
  router.dart         # GoRouter configuration
  models/             # Data models
  providers/          # Riverpod providers
  pages/              # Page widgets
  widgets/            # Reusable widgets
  service/
    api/              # API clients and models
test/
  widget_test.dart    # Widget tests
```

### Lint Rules

The project uses flutter_lints (see analysis_options.yaml). Key rules:
- Avoid print statements in production (use debugging tools)
- Use prefer_single_quotes for strings
- Enable strict typing where possible

Run `flutter analyze` before committing to catch issues.
