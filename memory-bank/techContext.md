# Technical Context: DartRPG

## Technology Stack

### Core Framework
- **Flutter**: Cross-platform UI toolkit for building natively compiled applications
- **Dart**: Programming language optimized for building mobile, desktop, server, and web applications

### State Management
- **Provider**: Lightweight state management solution that uses the InheritedWidget mechanism
- **ChangeNotifier**: Base class for observable objects that notify listeners of changes

### Data Persistence
- **SharedPreferences**: Simple key-value storage for app preferences and small data sets
- **JSON Serialization**: Custom serialization/deserialization for model classes
- **File Picker**: For importing/exporting game data files

### UI Components
- **Material Design**: UI design language and component library
- **Custom Widgets**: Specialized widgets for game-specific functionality
- **TabBar/TabBarView**: Used for organizing content into tabs (e.g., quest statuses)
- **ProgressTrackWidget**: Custom widget for displaying progress bars with segments

### Utilities
- **Logging Service**: Custom logging implementation for debugging and error tracking
  - Provides debug, info, warning, and error log levels
  - Stores logs in memory for viewing in the LogViewerScreen
  - Should always be used instead of dart:developer or print statements
  - Formats logs with timestamps, levels, and optional tags
- **Dice Roller**: Utility for simulating dice rolls for game mechanics
- **Datasworn Parser**: Utility for parsing Ironsworn game data
  - Handles both "contents" and "collections" structures in JSON
  - Parses nested oracle collections with subcategories
  - Supports complex data structures like node types with multiple tables
  - Includes detailed logging for debugging parsing issues

## Development Environment

### Required Tools
- **Flutter SDK**: Version 3.5.0 or higher
- **Dart SDK**: Version 3.5.0 or higher
- **Android Studio** or **VS Code** with Flutter/Dart plugins
- **Git**: For version control

### Setup Instructions
1. Install Flutter SDK and Dart SDK
2. Set up an IDE (Android Studio or VS Code) with Flutter/Dart plugins
3. Clone the repository
4. Run `flutter pub get` to install dependencies
5. Run `flutter run` to launch the application in debug mode

### Build Process
- **Debug Build**: `flutter run`
- **Release Build**: `flutter build apk` (Android) or `flutter build ios` (iOS)
- **Web Build**: `flutter build web`

## Technical Constraints

### Platform Limitations
- **Mobile-First Design**: Optimized for mobile devices, may require adjustments for desktop/web
- **Offline-First**: Designed to work without internet connectivity
- **Storage Limits**: SharedPreferences has size limitations for storing large datasets

### Performance Considerations
- **Memory Usage**: Large game datasets may impact memory usage
- **Serialization Overhead**: JSON serialization/deserialization can be CPU-intensive
- **UI Responsiveness**: Complex UI updates may affect frame rate
- **Quest Filtering**: Performance may degrade with large numbers of quests

### Security Considerations
- **Local Storage Security**: Data stored locally is not encrypted
- **Export/Import Security**: Exported game files are not encrypted or authenticated

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  shared_preferences: ^2.5.2
  path_provider: ^2.1.2
  http: ^1.2.1
  uuid: ^4.3.3
  localstorage: ^5.0.0
  flutter_markdown: ^0.7.6+2
  file_picker: ^9.2.1
  image_picker: ^1.0.7
```

### Development Dependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

## Project Structure

```
dart_rpg/
├── lib/
│   ├── main.dart             # Application entry point
│   ├── models/               # Data models
│   │   ├── character.dart
│   │   ├── game.dart
│   │   ├── journal_entry.dart
│   │   ├── location.dart
│   │   ├── move.dart
│   │   ├── oracle.dart
│   │   ├── quest.dart        # Quest model
│   │   └── session.dart
│   ├── providers/            # State management
│   │   ├── datasworn_provider.dart
│   │   ├── game_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/              # UI screens
│   │   ├── assets_screen.dart
│   │   ├── character_screen.dart
│   │   ├── game_screen.dart
│   │   ├── game_selection_screen.dart
│   │   ├── home_screen.dart
│   │   ├── journal_entry_screen.dart
│   │   ├── journal_screen.dart
│   │   ├── location_screen.dart
│   │   ├── log_viewer_screen.dart
│   │   ├── moves_screen.dart
│   │   ├── new_game_screen.dart
│   │   ├── oracles_screen.dart
│   │   ├── quests_screen.dart # Quest management screen
│   │   └── settings_screen.dart
│   ├── utils/                # Utility functions
│   │   ├── datasworn_parser.dart
│   │   ├── dice_roller.dart
│   │   └── logging_service.dart
│   └── widgets/              # Reusable UI components
│       ├── asset_card_widget.dart
│       ├── character_stats_card.dart
│       ├── gradient_edge_painter.dart
│       ├── hacker_grid_painter.dart
│       ├── impact_toggle_widget.dart
│       ├── location_edge_painter.dart
│       ├── location_graph_widget.dart
│       ├── progress_track_widget.dart # Used for quest progress
│       ├── stat_adjuster_widget.dart
│       └── journal/
├── assets/                   # Static assets
│   ├── data/                 # Game data files
│   └── images/               # Image assets
├── test/                     # Test files
└── pubspec.yaml              # Project configuration
```

## Quest System Implementation

### Quest Model
The `Quest` model is implemented in `lib/models/quest.dart` and includes:

```dart
class Quest {
  final String id;
  final String characterId;
  String title;
  QuestRank rank;
  int progress;
  QuestStatus status;
  String notes;
  DateTime createdAt;
  DateTime updatedAt;
  
  // Constructor, factory methods, and serialization methods
  // Methods for quest status management and progress tracking
}

enum QuestRank {
  troublesome,
  dangerous,
  formidable,
  extreme,
  epic
}

enum QuestStatus {
  ongoing,
  completed,
  forsaken
}
```

### Quest Screen
The `QuestsScreen` is implemented in `lib/screens/quests_screen.dart` and includes:

- TabBar with three tabs: Ongoing, Completed, and Forsaken
- TabBarView with filtered lists of quests based on status
- FloatingActionButton for creating new quests
- Quest cards with title, rank, progress bar, and action buttons

### GameProvider Extensions
The `GameProvider` class has been extended with methods for quest management:

```dart
// In game_provider.dart
class GameProvider extends ChangeNotifier {
  // Existing methods...
  
  // Quest management methods
  Quest createQuest(String characterId, String title, QuestRank rank, {String notes = ''});
  void updateQuest(Quest quest);
  void deleteQuest(String questId);
  void completeQuest(String questId);
  void forsakeQuest(String questId);
  void increaseQuestProgress(String questId, [int amount = 1]);
  void decreaseQuestProgress(String questId, [int amount = 1]);
  MoveRoll makeQuestProgressRoll(String questId);
  
  // Quest retrieval methods
  List<Quest> getQuestsForCharacter(String characterId, {QuestStatus? status});
  Quest? getQuestById(String questId);
}
```

### Progress Tracking Widget
The `ProgressTrackWidget` is used for displaying and interacting with quest progress:

```dart
// In progress_track_widget.dart
class ProgressTrackWidget extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Function(int)? onChanged;
  final bool isEditable;
  
  // Constructor and build method
}
```

### Keyboard Shortcuts
Keyboard shortcuts are implemented in the `JournalEntryScreen` for quick navigation:

```dart
// In journal_entry_screen.dart
// Inside build method
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): 
        const OpenQuestsIntent(),
    // Other shortcuts...
  },
  child: Actions(
    actions: {
      OpenQuestsIntent: CallbackAction<OpenQuestsIntent>(
        onInvoke: (intent) => _navigateToQuests(context),
      ),
      // Other actions...
    },
    child: // Rest of the UI
  ),
)
```

## API Integrations

The application is primarily offline and does not integrate with external APIs. However, it does include:

- **File System Access**: For importing/exporting game data
- **Clipboard Access**: For copying log data

## Technical Debt and Limitations

### Current Limitations
- **Data Size**: SharedPreferences has limitations for storing large amounts of data
- **Error Handling**: Some areas have basic error handling that could be improved
- **Test Coverage**: Limited automated tests
- **Quest Filtering**: Performance may degrade with large numbers of quests

### Known Technical Debt
- **Model Serialization**: Manual JSON serialization could be replaced with code generation
- **Provider Usage**: Some providers have multiple responsibilities that could be separated
- **UI Responsiveness**: Some screens may need optimization for better performance
- **Quest Dependencies**: No support for quest dependencies or prerequisites

### Improvement Opportunities
- **Database Integration**: Replace SharedPreferences with SQLite for better data handling
- **Code Generation**: Use build_runner and json_serializable for model serialization
- **State Management**: Refine provider implementation or consider alternatives like Bloc
- **Testing**: Increase unit and widget test coverage
- **Error Handling**: Implement more robust error handling and recovery mechanisms
- **Quest System Enhancements**: Add support for quest categories, tags, and dependencies

## Development Workflow

### Version Control
- **Git**: Used for version control
- **Feature Branches**: New features developed in separate branches
- **Pull Requests**: Code review process for merging changes

### Testing Strategy
- **Manual Testing**: Primary testing method
- **Unit Tests**: For core business logic
- **Widget Tests**: For UI components

### Deployment Process
- **Local Builds**: For development and testing
- **App Store Submission**: Manual process for releasing to app stores

## Documentation

### Code Documentation
- **Dartdoc Comments**: Used for documenting classes and methods
- **README**: Project overview and setup instructions

### User Documentation
- **In-App Help**: Contextual help within the application
- **User Guide**: Planned but not yet implemented
