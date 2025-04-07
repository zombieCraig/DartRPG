# DartRPG - Fe-Runners RPG Journal

A digital companion app for the Fe-Runners tabletop role-playing game system, built with Flutter.

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live%20Demo-blue)](https://zombiecraig.github.io/DartRPG/)

## About

DartRPG is a comprehensive digital companion for players of the Fe-Runners RPG system, a hacking-themed game based on Ironsworn mechanics. This app helps you manage your game sessions, characters, locations, quests, and journal entries in a structured and intuitive way.

[Fe-Runners Homepage](https://zombiecraig.itch.io/fe-runners)

> **Note:** This software is currently in early alpha stage. Expect bugs and incomplete features as it is a work in progress.

## Features

- **Game Management**: Create, edit, and delete games; import and export game data
- **Character Management**: Create and edit characters with stats, assets, and notes
- **Location Tracking**: Create and manage game world locations with a visual network graph
- **Quest System**: Track character quests with progress bars and different statuses
- **Journal System**: Record game events with rich text formatting and entity linking
- **Moves and Oracles**: Access Fe-Runners moves and oracle tables with integrated dice rolling

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK (3.29.2 or higher)
- Dart SDK (3.5.4 or higher)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/zombieCraig/DartRPG.git
   cd DartRPG/dart_rpg
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

### Web Version

You can also run the web version locally:

```bash
flutter run -d chrome
```

## Deployment

The app is automatically deployed to GitHub Pages when changes are pushed to the main branch. You can access the live version at:

[https://zombiecraig.github.io/DartRPG/](https://zombiecraig.github.io/DartRPG/)

For more information about the web deployment process, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Releases

Multi-platform releases (Linux, macOS, and Windows) are automatically built when a new GitHub Release is created. The workflow:

1. Builds the application for all three platforms
2. Updates the version in `pubspec.yaml` to match the release tag
3. Packages the builds appropriately for each platform
4. Uploads the packages as assets to the GitHub release

For detailed instructions on creating releases, see [MULTI_PLATFORM_RELEASE.md](MULTI_PLATFORM_RELEASE.md).

## Documentation

For detailed information about the project, check out the memory-bank files:

- [Project Brief](memory-bank/projectbrief.md) - Overview and core objectives
- [Product Context](memory-bank/productContext.md) - Purpose, problems solved, and user experience goals
- [System Patterns](memory-bank/systemPatterns.md) - System architecture and design patterns
- [Technical Context](memory-bank/techContext.md) - Technology stack and implementation details
- [Active Context](memory-bank/activeContext.md) - Current work focus and recent changes
- [Progress](memory-bank/progress.md) - Current status and known issues

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.
