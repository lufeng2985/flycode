# FlyCode

[English](./README.md) | [简体中文](./README.zh-CN.md)

FlyCode is a Flutter-based mobile client for `opencode`, built to connect to `opencode server` and bring project navigation, session management, and AI coding workflows to Android and iOS.

> Prerequisite: FlyCode requires a running `opencode server` before the app can be used.
> Official docs: https://opencode.ai/docs/server/

## Tech Stack

- Flutter / Dart `^3.11.0`
- Riverpod + `riverpod_annotation`
- `go_router`
- `http`
- `shared_preferences`
- `sqflite`
- `json_serializable`

## Supported Platforms

This project is primarily focused on mobile:

- Android
- iOS

## Features

- Connect to `opencode server` with a configurable server address and optional authentication
- Browse projects and jump into new or existing coding sessions quickly
- Chat with the coding agent through a mobile-oriented message and input experience
- Review permission requests, questions, todos, diffs, and session context in-app
- Customize model settings, theme mode, language, and completion notifications
- Persist local app state with built-in storage and mobile notification support

## Project Structure

```text
lib/
  app.dart                    # App entry: routing, theme, localization, global events
  main.dart                   # Flutter bootstrap
  router.dart                 # go_router route definitions
  theme/                      # ThemeData and AppThemeTokens
  l10n/                       # Localization resources and generated code
  pages/                      # Page layer
  widgets/                    # Shared and feature widgets
  providers/                  # Riverpod providers and state logic
  service/api/                # API client, endpoints, and API models
  database/                   # Local database and DAOs
  models/                     # App-local models
test/                         # Unit and widget tests
assets/                       # Fonts, app icon, and static assets
```

## Local Development

### Requirements

- Flutter SDK
- Dart SDK `^3.11.0`
- Platform-specific build environment for your target device
- A running `opencode server`

### Quick Start

1. Start `opencode server` first:

```bash
opencode serve
```

By default, the server listens on `http://127.0.0.1:4096`.

Server docs:

- https://opencode.ai/docs/server/
- OpenAPI spec after startup: `http://127.0.0.1:4096/doc`

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
flutter run
```

To run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Development Commands

### Format Code

```bash
dart format .
```

### Static Analysis

```bash
flutter analyze
```

### Run Tests

```bash
flutter test
```

Run a single test file:

```bash
flutter test test/session_status_provider_test.dart
```

Run a named test:

```bash
flutter test test/session_status_provider_test.dart --name="returns loading state"
```

### Generate Code

Run code generation after updating:

- `@riverpod` providers
- `json_serializable` models

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Recommended Workflow

Before committing, run:

```bash
dart format .
flutter analyze
flutter test
```

Repository conventions:

- Do not edit `*.g.dart` files manually
- Prefer `@riverpod` for new providers
- Keep pages focused on composition and UI assembly
- Move business logic into providers where possible
- Avoid hardcoded colors, typography, and spacing; prefer theme tokens

## Theme and Design

The project uses `ThemeData` with `ThemeExtension(AppThemeTokens)` for design tokens.

Key files:

- `lib/app.dart`
- `lib/theme/app_theme.dart`
- `lib/theme/app_tokens.dart`
- `lib/theme/theme_mode_provider.dart`

Design guidance:

- Prioritize information hierarchy over decoration
- Reuse components instead of introducing one-off styles
- Keep colors, typography, radius, and spacing token-driven
- Consider both light and dark mode

Current visual baseline:

- Body font: Inter
- Display font: PlusJakartaSans
- Primary color: `#8B5CF6`

## Configuration

### Server Configuration

The app depends on a reachable `opencode server`, and the server must be started before FlyCode can connect. The connection test currently calls:

```text
/global/health
```

Quick reference:

- Docs: https://opencode.ai/docs/server/
- Start command: `opencode serve`
- Default address: `http://127.0.0.1:4096`
- OpenAPI spec: `http://127.0.0.1:4096/doc`

Configurable fields:

- `baseUrl`
- `username` (optional)
- `password` (optional)

### Local Persistence

The project currently uses:

- `shared_preferences` for lightweight local settings and onboarding state
- `sqflite` for local structured storage

## License and Assets

- Font assets are stored in `assets/fonts/`
- The font license file is stored at `assets/fonts/OFL.txt`
