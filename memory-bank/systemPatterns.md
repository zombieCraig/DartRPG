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
│  │Location │  │  Move   │  │ Oracle  │  │  Quest  │    │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   Utility Layer                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ DiceRoller  │  │DataswornParser│ │LoggingService│    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│  ┌─────────────────┐  ┌───────────────────────────┐    │
│  │DataswornLinkParser│ │OracleReferenceProcessor  │    │
│  └─────────────────┘  └───────────────────────────┘    │
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
- CRUD operations for game entities (characters, locations, quests, etc.)
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

### State Pattern
Used in the Quest model to manage different quest states:
- Quests can be in Ongoing, Completed, or Forsaken states
- State transitions are managed through specific methods
- UI representation changes based on the current state

## Component Relationships

### Providers and Their Responsibilities

1. **GameProvider**
   - Manages the list of games
   - Handles the current game and session state
   - Provides CRUD operations for game entities
   - Manages data persistence (save/load/import/export)
   - Handles quest creation, updates, and status changes
   - Manages progress rolls for quests

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
├── Quest[]
└── Session[]
    └── JournalEntry[]
        ├── MoveRoll?
        └── OracleRoll?
```

- A `Game` contains multiple `Character`s, `Location`s, `Quest`s, and `Session`s
- Each `Session` contains multiple `JournalEntry` objects
- `JournalEntry` objects can be linked to `Character`s and `Location`s
- `JournalEntry` objects can contain `MoveRoll` and `OracleRoll` data
- `Quest` objects are associated with specific `Character`s
- `Quest` objects have a status (Ongoing, Completed, Forsaken) that determines their tab placement

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
        ├─────► QuestsScreen    │
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

### Quest System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   QuestsScreen                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   TabBar                         │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐    │   │
│  │  │  Ongoing  │  │ Completed │  │ Forsaken  │    │   │
│  │  └───────────┘  └───────────┘  └───────────┘    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   TabBarView                     │   │
│  │  ┌───────────────────────────────────────────┐  │   │
│  │  │              QuestListView                 │  │   │
│  │  │  ┌───────────────────────────────────┐    │  │   │
│  │  │  │           QuestCard               │    │  │   │
│  │  │  │  ┌─────────────────────────────┐  │    │  │   │
│  │  │  │  │        Quest Title          │  │    │  │   │
│  │  │  │  │        Quest Rank           │  │    │  │   │
│  │  │  │  │        Progress Bar         │  │    │  │   │
│  │  │  │  │        Action Buttons       │  │    │  │   │
│  │  │  │  └─────────────────────────────┘  │    │  │   │
│  │  │  └───────────────────────────────────┘    │  │   │
│  │  └───────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              FloatingActionButton               │   │
│  │                 (Create Quest)                   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

The Quest system follows these key architectural patterns:

1. **Tab-based Organization**: Quests are organized into tabs based on their status (Ongoing, Completed, Forsaken)
2. **Card-based UI**: Each quest is displayed as a card with title, rank, progress bar, and action buttons
3. **Progress Tracking**: Uses a 10-segment progress bar with manual adjustment and progress roll functionality
4. **State Management**: Quest status changes are managed through the GameProvider
5. **Character Association**: Quests are associated with specific characters
6. **Journal Integration**: Quest status changes create journal entries to document progress

## Technical Decisions

### Local Storage Strategy
- Uses `shared_preferences` for storing game data and settings
- JSON serialization for complex objects
- Structured storage keys for organizing data
- Quest data is serialized as part of the Game object

### Error Handling and Logging Approach
- Comprehensive logging system with different log levels (debug, info, warning, error)
- Always use the custom LoggingService instead of dart:developer or print statements
- In-app log viewer for debugging with filterable log levels
- Try-catch blocks around critical operations with proper error logging
- User-friendly error messages for end users
- Detailed logging in DataswornParser for better debugging of oracle parsing issues

### UI Architecture
- Screen-based navigation using Flutter's `Navigator`
- Bottom navigation for main game screens
- Tab-based organization for related content (e.g., quest statuses)
- Modal dialogs for quick actions and confirmations
- Form-based screens for data entry

### Cross-Platform Considerations
- Platform-agnostic code where possible
- Platform-specific code isolated in conditional blocks
- Responsive layouts that adapt to different screen sizes
- Keyboard shortcuts with platform-specific modifiers

## Future Architectural Considerations

### Potential Refactorings
- Consider moving to a more structured state management solution like Bloc or Redux for complex state
- Extract repository logic from providers into dedicated repository classes
- Implement a more robust offline-first data synchronization strategy
- Enhance the Quest model with support for dependencies and prerequisites

### Scalability Improvements
- Database solution (SQLite) for larger datasets
- Pagination for lists of games, characters, quests, etc.
- More efficient serialization/deserialization
- Optimized quest filtering and sorting for large datasets

### Oracle Reference Processing System

The Oracle Reference Processing system is designed to handle nested oracle references in oracle results. This system follows these key architectural patterns:

```
┌─────────────────────────────────────────────────────────┐
│                OracleResultText Widget                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              processReferences=true              │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              OracleReferenceProcessor                   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         processOracleReferences()               │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│               DataswornLinkParser                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │             parseLinks()                         │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 DataswornProvider                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │             getOracleTable()                     │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   OracleRoll Model                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │             nestedRolls[]                        │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Component Responsibilities**:
   - `OracleResultText`: A StatefulWidget that displays oracle results and processes references
   - `OracleReferenceProcessor`: A utility class that processes oracle references in text
   - `DataswornLinkParser`: A utility class that parses Datasworn links in text
   - `DataswornProvider`: Provides access to oracle tables
   - `OracleRoll`: A model class that represents an oracle roll, including nested rolls

2. **Process Flow**:
   - When an oracle is rolled, the result is displayed using the `OracleResultText` widget
   - If `processReferences=true`, the widget uses `OracleReferenceProcessor` to process references
   - `OracleReferenceProcessor` uses `DataswornLinkParser` to find and parse oracle references
   - For each reference, it rolls on the referenced oracle using `DataswornProvider`
   - The results are stored in the `OracleRoll` object's `nestedRolls` array
   - The processed text with references replaced by actual results is displayed

3. **Recursive Processing**:
   - The system supports recursive processing of nested references
   - If a referenced oracle result contains further references, those are processed as well
   - Each level of nesting is tracked and stored in the `OracleRoll` hierarchy

4. **Error Handling**:
   - Comprehensive error handling for invalid references
   - Logging of reference processing errors
   - Graceful fallback to original text if processing fails

This architecture ensures a clean separation of concerns while providing a seamless user experience for oracle consultation.

### Technical Debt Areas
- Improve test coverage
- Enhance error handling with more specific error types
- Refine the logging system with more structured log entries
- Optimize quest data persistence for better performance
