# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DartRPG (Fe-Runners Journal) is a Flutter-based digital companion app for the Fe-Runners tabletop RPG system, a hacking-themed game based on Ironsworn mechanics. The Flutter project lives in `dart_rpg/` — all Flutter commands must be run from that directory.

## Common Commands

All commands below should be run from `dart_rpg/`:

```bash
# Install dependencies
flutter pub get

# Run the app (web)
flutter run -d chrome

# Run the app (desktop/mobile)
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/unit/dice_roller_test.dart

# Run tests matching a name pattern
flutter test --name "pattern"

# Static analysis
flutter analyze

# Build for web (deployed to GitHub Pages)
flutter build web --base-href "/DartRPG/"

# Build for desktop
flutter build linux
flutter build macos
flutter build windows
```

## Architecture

### State Management: Provider Pattern

The app uses `provider` with `ChangeNotifier`. Five providers are registered in `main.dart` via `MultiProvider`:

- **GameProvider** (`providers/game_provider.dart`) — Central provider managing all game state: games, characters, locations, quests, journal entries, sessions, clocks. Handles persistence via SharedPreferences/LocalStorage.
- **DataswornProvider** (`providers/datasworn_provider.dart`) — Loads and provides access to Fe-Runners game data (moves, oracles, assets, truths) parsed from `assets/data/fe_runners.json`.
- **SettingsProvider** (`providers/settings_provider.dart`) — Theme and app settings.
- **ImageManagerProvider** (`providers/image_manager_provider.dart`) — Manages game images.
- **AiImageProvider** (`providers/ai_image_provider.dart`) — AI image generation.

### Data Flow

Game data is defined in Datasworn JSON format (`assets/data/fe_runners.json`). The `DataswornProvider` parses this using utilities in `utils/datasworn_link_parser.dart` and `utils/oracle_reference_processor.dart`. Player game state is persisted as JSON via SharedPreferences (web) or LocalStorage.

### Layer Organization (under `dart_rpg/lib/`)

- `models/` — Data classes with JSON serialization (`fromJson`/`toJson`). Key models: `game.dart`, `character.dart`, `location.dart`, `quest.dart`, `journal_entry.dart`, `session.dart`, `clock.dart`, `move.dart`, `oracle.dart`
- `providers/` — ChangeNotifier-based state management
- `screens/` — Top-level page widgets (each screen is a route)
- `widgets/` — Reusable UI components, organized by feature subdirectory (`character/`, `journal/`, `locations/`, `clocks/`, `moves/`, `oracles/`, `quests/`)
- `services/` — Business logic services: `oracle_service.dart`, `roll_service.dart`, `autosave_service.dart`, `tutorial_service.dart`, `changelog_service.dart`
- `utils/` — Pure utility functions: `dice_roller.dart`, `logging_service.dart`, `datasworn_link_parser.dart`, etc.
- `transitions/` — Navigation and screen transition logic

### Key Patterns

- **Logging**: Use `LoggingService` singleton instead of `print()` or `dart:developer`. Logs are viewable in-app via `LogViewerScreen`.
- **Safe list lookups**: Use `firstWhereOrNull` from `package:collection` instead of bare `firstWhere` to avoid `StateError` crashes. Import `package:collection/collection.dart`.
- **Widget feature directories**: Complex features (character, journal, locations, clocks, moves, oracles, quests) have their own subdirectories under `widgets/` containing related widgets, dialogs, panels, and service classes.
- **Game data format**: The app uses the Datasworn format for game content. The main data file is `assets/data/fe_runners.json`, with `custom_oracles.json` for custom oracle tables.

### Tests

Tests are in `dart_rpg/test/` organized as:
- `unit/` — Model and utility tests
- `widget/` — Widget/screen tests
- `mocks/` — Shared mock objects: `mock_game_provider.dart`, `mock_datasworn_provider.dart`, `shared_preferences_mock.dart`. Use these instead of redefining mocks per test file.

### Deployment

- **Web**: GitHub Pages at `zombiecraig.github.io/DartRPG/`. Auto-deployed on push to main.
- **Multi-platform releases**: GitHub Actions workflow (`.github/workflows/multi-platform-release.yml`) builds Linux, macOS, and Windows when a GitHub Release is created. Version in `pubspec.yaml` is updated to match the release tag.
- **PWA/Offline**: Service worker caches assets for offline use.
