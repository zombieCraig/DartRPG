# System Patterns: DartRPG

## Architecture Overview

DartRPG follows a Provider-based architecture pattern, which is a state management approach commonly used in Flutter applications. This architecture separates the application into distinct layers:

1. **UI Layer (Screens & Widgets)**: Responsible for rendering the user interface and handling user interactions
2. **State Management Layer (Providers)**: Manages application state and business logic
3. **Data Layer (Models)**: Represents the core data structures of the application
4. **Utility Layer (Utils)**: Provides helper functions and services

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │ Screens │  │ Dialogs │  │ Widgets │  │  Views  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│               State Management Layer                    │
│  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  GameProvider   │  │     SettingsProvider        │  │
│  └─────────────────┘  └─────────────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │DataswornProvider│  │     Other Providers         │  │
│  └─────────────────┘  └─────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │  Game   │  │Character│  │ Session │  │ Journal │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │Location │  │  Move   │  │ Oracle  │  │  Other  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   Utility Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ DiceRoller  │  │DataswornParser│ │LoggingService│    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
```

## Key Design Patterns

### Provider Pattern
The application uses the Provider pattern for state management, which is implemented using the `provider` package. This pattern allows for:
- Separation of UI and business logic
- Efficient rebuilding of only the widgets that depend on changed state
- Easy access to state from anywhere in the widget tree

### Singleton Pattern
Used for services that should have only one instance throughout the application:
- `LoggingService`: Ensures a single point for logging throughout the app
- Providers are effectively singletons within the context of the app

### Repository Pattern
The `GameProvider` acts as a repository for game data, handling:
- Loading and saving games from/to persistent storage
- CRUD operations for game entities (characters, locations, etc.)
- Managing the current game state

### Observer Pattern
Implemented through the `ChangeNotifier` class from Flutter:
- Providers extend `ChangeNotifier` to broadcast state changes
- UI components listen to these changes using `Consumer` widgets
- When state changes, only the affected UI components rebuild

### Factory Pattern
Used in model classes to create objects from JSON and vice versa:
- `fromJson` factory constructors for deserialization
- `toJson` methods for serialization

## Component Relationships

### Providers and Their Responsibilities

1. **GameProvider**
   - Manages the list of games
   - Handles the current game and session state
   - Provides CRUD operations for game entities
   - Manages data persistence (save/load/import/export)

2. **SettingsProvider**
   - Manages application settings (theme, font size, etc.)
   - Handles persistence of settings
   - Provides theme data to the application

3. **DataswornProvider**
   - Manages Ironsworn game data (moves, oracles, etc.)
   - Loads and parses Datasworn JSON files
   - Provides access to game mechanics data

### Model Hierarchy

```
Game
├── Character[]
│   ├── Stats[]
│   └── Assets[]
├── Location[]
└── Session[]
    └── JournalEntry[]
        ├── MoveRoll?
        └── OracleRoll?
```

- A `Game` contains multiple `Character`s, `Location`s, and `Session`s
- Each `Session` contains multiple `JournalEntry` objects
- `JournalEntry` objects can be linked to `Character`s and `Location`s
- `JournalEntry` objects can contain `MoveRoll` and `OracleRoll` data

### Screen Navigation Flow

```
GameSelectionScreen
        │
        ▼
    NewGameScreen
        │
        ▼
    GameScreen ◄────────────────┐
        │                       │
        ├─────► JournalScreen   │
        │           │           │
        │           ▼           │
        │     JournalEntryScreen│
        │                       │
        ├─────► CharacterScreen │
        │                       │
        ├─────► LocationScreen  │
        │                       │
        ├─────► MovesScreen     │
        │                       │
        ├─────► OraclesScreen   │
        │                       │
        └─────► AssetsScreen    │
                                │
    SettingsScreen ◄────────────┘
        │
        ▼
   LogViewerScreen
```

## Technical Decisions

### Local Storage Strategy
- Uses `shared_preferences` for storing game data and settings
- JSON serialization for complex objects
- Structured storage keys for organizing data

### Error Handling Approach
- Comprehensive logging system with different log levels
- In-app log viewer for debugging
- Try-catch blocks around critical operations
- User-friendly error messages

### UI Architecture
- Screen-based navigation using Flutter's `Navigator`
- Bottom navigation for main game screens
- Modal dialogs for quick actions and confirmations
- Form-based screens for data entry

### Cross-Platform Considerations
- Platform-agnostic code where possible
- Platform-specific code isolated in conditional blocks
- Responsive layouts that adapt to different screen sizes

## Future Architectural Considerations

### Potential Refactorings
- Consider moving to a more structured state management solution like Bloc or Redux for complex state
- Extract repository logic from providers into dedicated repository classes
- Implement a more robust offline-first data synchronization strategy

### Scalability Improvements
- Database solution (SQLite) for larger datasets
- Pagination for lists of games, characters, etc.
- More efficient serialization/deserialization

### Technical Debt Areas
- Improve test coverage
- Enhance error handling with more specific error types
- Refine the logging system with more structured log entries
