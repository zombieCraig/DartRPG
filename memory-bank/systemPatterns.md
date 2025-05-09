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
├── Clock[]
└── Session[]
    └── JournalEntry[]
        ├── MoveRoll?
        └── OracleRoll?
```

- A `Game` contains multiple `Character`s, `Location`s, `Quest`s, `Clock`s, and `Session`s
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

### Quest and Clock System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   QuestsScreen                          │
│  ┌─────────────────────────────────────────────────┐   │
│  │                   TabBar                         │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐    │   │
│  │  │  Ongoing  │  │ Completed │  │ Forsaken  │    │   │
│  │  └───────────┘  └───────────┘  └───────────┘    │   │
│  │  ┌───────────┐                                  │   │
│  │  │  Clocks   │                                  │   │
│  │  └───────────┘                                  │   │
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

The Quest and Clock system follows these key architectural patterns:

1. **Tab-based Organization**: 
   - Quests are organized into tabs based on their status (Ongoing, Completed, Forsaken)
   - Clocks are displayed in a separate tab within the same screen

2. **Card-based UI**: 
   - Each quest is displayed as a card with title, rank, progress bar, and action buttons
   - Each clock is displayed as a card with title, type, segment visualization, and action buttons

3. **Progress Tracking**: 
   - Quests use a 10-segment progress bar with manual adjustment and progress roll functionality
   - Clocks use a circular segment visualization with 4, 6, 8, or 10 segments

4. **State Management**: 
   - Quest status changes are managed through the GameProvider
   - Clock advancement and completion are managed through the GameProvider

5. **Type-based Organization**:
   - Clocks are categorized by type (Campaign, Tension, Trace)
   - Batch operations are available for advancing all clocks of a specific type

6. **Journal Integration**: 
   - Quest status changes create journal entries to document progress
   - Clock completion creates journal entries to document significant events

## Technical Decisions

### Local Storage Strategy
- Uses `shared_preferences` for storing game data and settings
- JSON serialization for complex objects
- Structured storage keys for organizing data
- Quest data is serialized as part of the Game object
- Service worker implementation for web offline support

### Web Offline Support Architecture
The application implements a comprehensive offline support solution for web using a service worker:

```
┌─────────────────────────────────────────────────────────┐
│                   Service Worker                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Install Event Handler               │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Cache Core Assets│  │ Cache Critical Data │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Activate Event Handler              │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Clean Old Caches│  │ Claim Clients       │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Fetch Event Handler                 │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Request Routing │  │ Caching Strategies  │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Offline Fallback│  │ Error Handling      │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Component Responsibilities**:
   - `Install Event Handler`: Caches core assets and critical data files when the service worker is installed
   - `Activate Event Handler`: Cleans up old caches and claims clients when the service worker is activated
   - `Fetch Event Handler`: Intercepts network requests and applies appropriate caching strategies

2. **Caching Strategies**:
   - `Cache-First`: For critical data files, check the cache first and only fetch from network if not found
   - `Network-First`: For regular requests, try the network first and fall back to cache if offline
   - `Offline Fallback`: Serve a custom offline page when network is unavailable and content isn't cached

3. **Key Files**:
   - `service-worker.js`: The main service worker implementation
   - `index.html`: Contains the service worker registration script
   - `manifest.json`: Includes offline_enabled: true for proper PWA support
   - `offline.html`: Custom offline fallback page

4. **Process Flow**:
   - When the app is first loaded online, the service worker is registered and installed
   - During installation, core assets and critical data files are cached
   - When the user goes offline, the service worker intercepts requests and serves cached content
   - If a requested resource isn't cached, the offline fallback page is shown

5. **Benefits**:
   - **Complete Offline Support**: Users can use the app even without internet connection
   - **Improved Performance**: Cached resources load faster than network requests
   - **Better User Experience**: Custom offline page instead of browser's default offline message
   - **Resilience**: App continues to function during intermittent connectivity issues

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

## Move System Architecture

The Move system follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   JournalEntryScreen                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              onMoveRequested()                   │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     MoveDialog                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                 show()                           │   │
│  └───────────────────────┬─────────────────────────┘   │
│                          │                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │           _rollActionMove()                      │   │
│  │           _rollProgressMove()                    │   │
│  │           _performNoRollMove()                   │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 Specialized Components                  │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  MoveList   │  │ MoveDetails │  │RollResultView│    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ActionRollPanel│ │ProgressRollPanel│ │NoRollPanel│    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    RollService                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         performActionRoll()                      │   │
│  │         performProgressRoll()                    │   │
│  │         performNoRollMove()                      │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Component Responsibilities**:
   - `JournalEntryScreen`: Provides the entry point for move rolling via the Move button
   - `MoveDialog`: A utility class that handles move selection and rolling logic
   - `MoveList`: Displays a list of available moves for selection
   - `MoveDetails`: Shows detailed information about a selected move
   - `ActionRollPanel`, `ProgressRollPanel`, `NoRollPanel`: Specialized components for different roll types
   - `RollResultView`: Displays the results of a move roll
   - `RollService`: Handles the actual dice rolling and outcome determination

2. **Process Flow**:
   - When the Move button is clicked in the JournalEntryScreen, it calls `_showRollMoveDialog`
   - This method calls `MoveDialog.show()` with appropriate callbacks
   - The MoveDialog displays a list of moves using the MoveList component
   - When a move is selected, it shows the move details using the MoveDetails component
   - Based on the move type, it displays the appropriate roll panel
   - When a roll is performed, it uses the RollService to determine the outcome
   - The result is displayed using the RollResultView component
   - The roll can be added to the journal entry via the provided callbacks

3. **Benefits of this Architecture**:
   - **Separation of Concerns**: Each component has a specific responsibility
   - **Modularity**: Components can be developed and tested independently
   - **Reusability**: Components can be reused in different contexts
   - **Maintainability**: Changes to one component don't affect others
   - **Testability**: Components can be tested in isolation

This architecture serves as a model for other complex features in the application, demonstrating how to break down functionality into manageable, specialized components.

## Component Extraction Pattern

The project follows a component extraction pattern for complex features to improve maintainability and reduce the risk of data loss or regression:

1. **Identify Complex Features**: Look for features with multiple responsibilities, complex UI, or embedded in large classes
2. **Extract Utility Classes**: Create utility classes for dialog management (e.g., MoveDialog, OracleDialog)
3. **Create Specialized Components**: Break down complex UI into specialized components with clear responsibilities
4. **Move Business Logic to Services**: Extract business logic into dedicated service classes
5. **Use Callback-Based Communication**: Components communicate through callbacks rather than direct dependencies
6. **Add Comprehensive Tests**: Create tests for each component in isolation

This pattern has been applied to:
- **Move System**: MoveDialog, MoveList, MoveDetails, ActionRollPanel, ProgressRollPanel, NoRollPanel, RollResultView, RollService
- **Oracle System**: OracleDialog, OracleCategoryList, OracleTableList, OracleRollPanel, OracleResultView, OracleService
- **Journal Entry Editor System**: JournalEntryEditor, EditorToolbar, AutocompleteSystem, LinkedItemsManager, AutosaveService
- **Quest Management System**: QuestDialog, QuestForm, QuestProgressPanel, QuestTabList, QuestCard, QuestActionsPanel, QuestService
- **Location Graph System**: LocationDialog, LocationForm, ConnectionPanel, LocationNodeWidget, LocationService, LocationListView
- **Clock System**: ClockDialog, ClockForm, ClockProgressPanel, ClockCard, ClockService, ClocksTabView, ClockSegmentPainter

Future candidates for this pattern:
- Character Management System

Benefits of this pattern:
- **Improved Maintainability**: Each component has a clear, focused responsibility
- **Better Testability**: Components can be tested in isolation
- **Reduced Risk of Data Loss**: Changes to one component are less likely to affect others
- **Enhanced User Experience**: More consistent UI and behavior
- **Easier Future Enhancements**: New features can be added to specific components

## Journal Entry Editor System Architecture

The Journal Entry Editor system follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   JournalEntryScreen                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              JournalEntryEditor                  │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │   EditorToolbar │  │  AutocompleteSystem │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │                                                  │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │LinkedItemsManager│  │   AutosaveService  │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              JournalEntryViewer                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              LinkedItemsSummary                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Component Responsibilities**:
   - `JournalEntryScreen`: Container for the editor and viewer components
   - `JournalEntryEditor`: Core component for editing journal entries
   - `EditorToolbar`: Handles formatting actions and quick access buttons
   - `AutocompleteSystem`: Manages character and location autocompletion
   - `LinkedItemsManager`: Tracks and manages linked items (characters, locations, etc.)
   - `AutosaveService`: Handles automatic saving of journal entries
   - `JournalEntryViewer`: Displays journal entries with clickable references
   - `LinkedItemsSummary`: Shows a summary of linked items in the journal entry

2. **Process Flow**:
   - When creating or editing a journal entry, the JournalEntryScreen uses JournalEntryEditor
   - The JournalEntryEditor uses EditorToolbar for formatting actions
   - As the user types, AutocompleteSystem checks for character and location references
   - LinkedItemsManager tracks linked items as they are added
   - AutosaveService periodically saves the entry to prevent data loss
   - When viewing an entry, JournalEntryViewer displays the content with clickable references
   - LinkedItemsSummary shows a summary of all linked items

3. **Benefits of this Architecture**:
   - **Separation of Concerns**: Each component has a specific responsibility
   - **Modularity**: Components can be developed and tested independently
   - **Reusability**: Components can be reused in different contexts
   - **Maintainability**: Changes to one component don't affect others
   - **Testability**: Components can be tested in isolation

This architecture serves as a model for other complex features in the application, demonstrating how to break down functionality into manageable, specialized components.

## Location Graph System Architecture

The Location Graph System follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   LocationScreen                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Search & View Toggle                │   │
│  └───────────────────────┬─────────────────────────┘   │
│                          │                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │              LocationListView/GraphView          │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     LocationDialog                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                 showCreateDialog()               │   │
│  │                 showEditDialog()                 │   │
│  │                 showDeleteConfirmation()         │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 Specialized Components                  │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │ LocationForm│  │ConnectionPanel│ │LocationNodeWidget│ │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              LocationListView                    │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    LocationService                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         createLocation()                         │   │
│  │         updateLocation()                         │   │
│  │         deleteLocation()                         │   │
│  │         connectLocations()                       │   │
│  │         disconnectLocations()                    │   │
│  │         updateLocationPosition()                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Location Graph Implementation Details

The Location Graph system is implemented using a modular approach with several key components:

#### File Structure
```
dart_rpg/lib/widgets/locations/
├── location_service.dart         # Service for location operations
├── location_dialog.dart          # Dialog for creating/editing locations
├── location_list_view.dart       # List view of locations
└── graph/                        # Graph-specific components
    ├── index.dart                # Exports all graph components
    ├── location_graph_widget.dart        # Main graph widget
    ├── location_graph_controller.dart    # Controls graph state and logic
    ├── location_interaction_handler.dart # Handles user interactions
    ├── location_node_renderer.dart       # Renders location nodes
    └── location_edge_renderer.dart       # Renders edges between nodes
```

#### Key Components

1. **LocationGraphWidget**: The main widget that displays the graph
   - Manages the overall layout and rendering of the graph
   - Coordinates between controller, renderers, and interaction handler
   - Handles animations for rig node pulsing and background effects

2. **LocationGraphController**: Controls the graph state and logic
   - Manages the graph data structure and node positions
   - Handles operations like building the graph, arranging nodes, and fitting to screen
   - Maintains the transformation state for zooming and panning

3. **LocationInteractionHandler**: Handles user interactions with the graph
   - Processes zoom, pan, and click events
   - Manages node dragging and position updates
   - Handles the "fit to screen" functionality

4. **LocationNodeRenderer**: Renders individual location nodes
   - Creates visual representations of locations based on their properties
   - Handles highlighting, focusing, and special effects for nodes
   - Manages the visual appearance of different node types

5. **LocationEdgeRenderer**: Renders edges between nodes
   - Creates visual connections between related locations
   - Handles edge styling based on location segments
   - Manages edge visibility and appearance

#### Coordinate System

The Location Graph system uses two different coordinate systems:

1. **Original Coordinate System**:
   - (0,0) is the center of the graph
   - Nodes are positioned at coordinates like (-200, 0) and (200, 0)
   - Used in the `LocationGraphController` for storing node positions
   - Node positions are saved in the database using this coordinate system

2. **Adjusted Coordinate System**:
   - (0,0) is the top-left corner of the graph
   - Used by the `Positioned` widget for rendering nodes
   - Nodes are adjusted by adding `halfSize` (1000.0) to both X and Y coordinates
   - For example, a node at (-200, 0) in the original system is positioned at (800, 1000) in the adjusted system

This dual coordinate system approach allows for intuitive positioning (centered around origin) while working with Flutter's top-left based rendering system. When transforming the graph (e.g., for "fit to screen" functionality), it's essential to convert between these coordinate systems correctly.

#### Fit to Screen Functionality

The "fit to screen" button works by:
1. Arranging all nodes in a circle based on their segment
2. Calculating the bounds of all nodes in the original coordinate system
3. Converting the graph center from the original to the adjusted coordinate system
4. Applying padding to ensure nodes aren't at the edge
5. Creating a transformation matrix that scales and centers the graph
6. Applying the transformation to make all nodes visible

This approach ensures that all nodes are visible and properly arranged when the user clicks the "fit to screen" button or when the location tab is first loaded.

1. **Component Responsibilities**:
   - `LocationScreen`: Container for the location management UI
   - `LocationDialog`: A utility class that handles location creation, editing, and deletion
   - `LocationForm`: Handles location data entry and validation
   - `ConnectionPanel`: Manages connections between locations
   - `LocationNodeWidget`: Renders individual location nodes in the graph
   - `LocationListView`: Displays locations in a list format
   - `LocationService`: Handles location-related business logic

2. **Process Flow**:
   - The LocationScreen provides search functionality and view toggling
   - Users can view locations in either graph or list format
   - When creating or editing a location, the LocationDialog is shown
   - The LocationDialog uses LocationForm for data entry
   - The ConnectionPanel manages connections between locations
   - The LocationService handles all location operations
   - The LocationNodeWidget renders individual nodes in the graph

3. **Benefits of this Architecture**:
   - **Separation of Concerns**: Each component has a specific responsibility
   - **Modularity**: Components can be developed and tested independently
   - **Reusability**: Components can be reused in different contexts
   - **Maintainability**: Changes to one component don't affect others
   - **Testability**: Components can be tested in isolation

This architecture follows the same pattern as other refactored systems in the application, providing a consistent approach to component organization and interaction.

## Countdown Clock System Architecture

The Countdown Clock system follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   QuestsScreen                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ClocksTabView                       │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                     ClockDialog                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                 showCreateDialog()               │   │
│  │                 showEditDialog()                 │   │
│  │                 showDeleteConfirmation()         │   │
│  │                 showResetConfirmation()          │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                 Specialized Components                  │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │  ClockForm  │  │ClockProgressPanel│ │ClockCard │    │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ClockSegmentPainter                 │   │
│  └─────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                    ClockService                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         createClock()                            │   │
│  │         updateClockTitle()                       │   │
│  │         advanceClock()                           │   │
│  │         resetClock()                             │   │
│  │         deleteClock()                            │   │
│  │         advanceAllClocksOfType()                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Component Responsibilities**:
   - `QuestsScreen`: Container for the quest and clock management UI
   - `ClocksTabView`: Displays the clocks tab with list of clocks and batch operation buttons
   - `ClockDialog`: A utility class that handles clock creation, editing, deletion, and reset confirmation
   - `ClockForm`: Handles clock data entry and validation
   - `ClockProgressPanel`: Displays and manages clock progress
   - `ClockCard`: Displays individual clocks in the list
   - `ClockSegmentPainter`: Custom painter for drawing circular segmented clocks
   - `ClockService`: Handles clock-related business logic

2. **Process Flow**:
   - The QuestsScreen provides a tab for Clocks
   - The ClocksTabView displays all clocks and provides batch operation buttons
   - When creating or editing a clock, the ClockDialog is shown
   - The ClockDialog uses ClockForm for data entry
   - The ClockProgressPanel visualizes clock progress and provides advance/reset buttons
   - The ClockSegmentPainter draws the circular clock visualization
   - The ClockService handles all clock operations

3. **Clock Model**:
   - `title`: The name of the clock
   - `segments`: The total number of segments (4, 6, 8, or 10)
   - `type`: The type of clock (Campaign, Tension, Trace)
   - `progress`: The current number of filled segments
   - `isComplete`: Whether the clock is completely filled
   - `completedAt`: When the clock was completed

4. **Clock Types**:
   - `Campaign`: Clocks that track campaign-level events
   - `Tension`: Clocks that track tension or threat levels
   - `Trace`: Clocks that track trace or detection levels

5. **Benefits of this Architecture**:
   - **Separation of Concerns**: Each component has a specific responsibility
   - **Modularity**: Components can be developed and tested independently
   - **Reusability**: Components can be reused in different contexts
   - **Maintainability**: Changes to one component don't affect others
   - **Testability**: Components can be tested in isolation

This architecture follows the same pattern as other refactored systems in the application, providing a consistent approach to component organization and interaction.

## Future Architectural Considerations

### Potential Refactorings
- Consider moving to a more structured state management solution like Bloc or Redux for complex state
- Extract repository logic from providers into dedicated repository classes
- Implement a more robust offline-first data synchronization strategy
- Enhance the Quest model with support for dependencies and prerequisites
- Apply the component extraction pattern to more complex features

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

## Node Type System Architecture

The Node Type system is designed to handle location node types from the Datasworn JSON structure. This system follows these key architectural patterns:

```
┌─────────────────────────────────────────────────────────┐
│                   Datasworn JSON                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              node_type (oracle_collection)       │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ collections     │  │ name: "Node Types"  │   │   │
│  │  └───────┬─────────┘  └─────────────────────┘   │   │
│  └──────────┬───────────────────────────────────────┘   │
│             │                                           │
│             ▼                                           │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Node Type Collections              │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ social          │  │ commerce            │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ gaming          │  │ entertainment       │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Datasworn JSON Structure

The node types are structured in the Datasworn JSON as follows:

```json
"node_type": {
    "name": "Node Types",
    "oracle_type": "tables",
    "type": "oracle_collection",
    "collections": {
        "social": {
            "name": "Social / Communications",
            "type": "oracle_collection",
            "oracle_type": "tables",
            ...
        },
        "commerce": {
            "name": "Commerce",
            "type": "oracle_collection",
            "oracle_type": "tables",
            ...
        },
        ...
    }
}
```

### Component Responsibilities

1. **DataswornParser**:
   - Parses the Datasworn JSON structure
   - Creates OracleCategory objects for node_type and its subcategories
   - Sets the `isNodeType` flag on the node_type category

2. **DataswornProvider**:
   - Provides access to the parsed oracle categories
   - Implements `getAllNodeTypes()` to extract node types from the node_type category
   - Finds the node_type category by ID or name
   - Extracts node type information from subcategories
   - Sorts node types alphabetically by display name

3. **NodeTypeInfo**:
   - A model class that represents a node type with key and display name
   - Used in the LocationForm for the node type dropdown

4. **NodeTypeUtils**:
   - Provides utility methods for working with node types
   - Maps segment types to oracle table IDs for segment-specific node type rolls
   - Implements methods to find node types by key and get random node types

5. **LocationForm**:
   - Displays a dropdown of available node types
   - Handles selection of node types
   - Provides buttons for random node type selection
   - Gracefully handles cases where no node types are available

### Process Flow

1. When the application loads:
   - DataswornParser parses the Datasworn JSON
   - It creates an OracleCategory for the node_type collection with isNodeType=true
   - It creates subcategories for each node type collection (social, commerce, etc.)

2. When the LocationForm is displayed:
   - It calls DataswornProvider.getAllNodeTypes()
   - DataswornProvider finds the node_type category by ID or name
   - It extracts node type information from the subcategories
   - It returns a sorted list of NodeTypeInfo objects

3. When a random node type is requested:
   - For segment-specific rolls, it uses the segment to determine the oracle table ID
   - It rolls on the appropriate oracle table
   - It matches the result to a node type
   - For any node type, it randomly selects from the available node types

### Benefits

- **Flexible Structure**: The system can handle different node type structures in the Datasworn JSON
- **Robust Lookup**: Multiple methods for finding the node_type category (by ID or name)
- **Graceful Degradation**: Handles cases where node types are not available
- **Alphabetical Sorting**: Provides a consistent ordering of node types in the dropdown
- **Random Selection**: Supports both segment-specific and general random node type selection

## Tutorial System Architecture

The application implements a tutorial system to help guide new players through the application. This system follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   SettingsProvider                      │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              enableTutorials                     │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                       Game Model                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              tutorialsEnabled                    │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   TutorialService                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │         showTutorialIfNeeded()                  │   │
│  │         hasShownTutorial()                      │   │
│  │         markTutorialAsShown()                   │   │
│  │         resetAllTutorials()                     │   │
│  └───────────────────────┬─────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   TutorialPopup                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              title                               │   │
│  │              message                             │   │
│  │              onClose                             │   │
│  │              showDisableOption                   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Component Responsibilities

1. **SettingsProvider**:
   - Manages the global setting for enabling/disabling tutorials
   - Persists the setting using SharedPreferences
   - Provides the setting to other components through the Provider pattern

2. **Game Model**:
   - Contains a per-game setting for enabling/disabling tutorials
   - Allows different games to have different tutorial settings
   - Persists the setting as part of the game data

3. **TutorialService**:
   - Provides static methods for managing tutorial state
   - Checks if a tutorial should be shown based on multiple conditions
   - Tracks which tutorials have been shown using SharedPreferences
   - Provides methods to reset tutorial state for testing

4. **TutorialPopup**:
   - Displays tutorial content in a modal dialog
   - Provides a consistent UI for all tutorials
   - Includes an option to disable all tutorials
   - Handles user interaction and dismissal

### Process Flow

1. When a screen is loaded that might need to show a tutorial:
   - The screen calls `TutorialService.showTutorialIfNeeded()`
   - The service checks if tutorials are enabled globally in SettingsProvider
   - The service checks if tutorials are enabled for the current game
   - The service checks if this specific tutorial has already been shown
   - The service checks if the condition for showing the tutorial is met
   - If all conditions are met, the TutorialPopup is displayed

2. When the user interacts with a TutorialPopup:
   - They can dismiss the popup by clicking "Got it"
   - They can disable all tutorials by checking the "Disable all tutorials" checkbox
   - When dismissed, the tutorial is marked as shown so it won't appear again

3. Tutorial state persistence:
   - The global enableTutorials setting is stored in SharedPreferences
   - The per-game tutorialsEnabled setting is stored as part of the Game object
   - The shown state of each tutorial is stored in SharedPreferences with a prefix

### Benefits

- **Contextual Help**: Provides help exactly when and where it's needed
- **Non-intrusive**: Can be disabled globally or per-game
- **Persistent**: Remembers which tutorials have been shown
- **Flexible**: Can be easily added to any screen or feature
- **Consistent**: Provides a uniform experience across the application

### Implementation Examples

The tutorial system has been integrated with the Journal Screen to provide guidance on:
- Creating a session when none exists
- Understanding what sessions are after creating the first one

This pattern can be extended to other screens and features as needed, providing a comprehensive onboarding experience for new users.

## Image Handling System Architecture

The application implements a robust image handling system that allows users to upload, save, and display images from both URLs and local storage. This system follows a modular architecture that separates concerns and improves maintainability:

```
┌─────────────────────────────────────────────────────────┐
│                   Models                                │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              AppImage                           │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ id, path, url   │  │ metadata            │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Character                          │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ imageUrl        │  │ imageId             │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              JournalEntry                       │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ embeddedImages  │  │ embeddedImageIds    │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Services                              │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ImageStorageService                │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ saveImage       │  │ getImage            │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ deleteImage     │  │ getAllImages        │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   Providers                             │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ImageManagerProvider               │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ addImageFromFile│  │ addImageFromUrl     │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ getImageById    │  │ getAllImages        │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   UI Components                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              AppImageWidget                     │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ imageUrl        │  │ imageId             │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ImagePickerDialog                  │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ URL input       │  │ File picker         │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐                            │   │
│  │  │ Saved images    │                            │   │
│  │  └─────────────────┘                            │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **AppImage Model**: Represents an image with metadata
   - Contains properties for id, path, url, and metadata
   - Supports both URL-based and locally stored images
   - Includes methods for serialization and deserialization

2. **ImageStorageService**: Handles saving and loading images to/from disk
   - Provides methods for saving, loading, and deleting images
   - Manages the file system storage for images
   - Handles file naming and organization

3. **ImageManagerProvider**: Manages images throughout the app
   - Provides a high-level API for image operations
   - Coordinates between UI and storage service
   - Handles image caching and memory management
   - Manages image metadata and relationships

4. **AppImageWidget**: A reusable widget for displaying images
   - Supports both URL-based and locally stored images
   - Handles loading states and errors
   - Provides consistent image display throughout the app

5. **ImagePickerDialog**: A dialog for selecting images
   - Allows selecting images from URL, file system, or saved images
   - Provides a consistent UI for image selection
   - Returns a standardized result format

### Integration with Existing Models

1. **Character Model**:
   - Added `imageId` field for locally stored images
   - Added `imageSource` getter to determine the image source (URL or local)
   - Updated serialization and deserialization methods

2. **JournalEntry Model**:
   - Added `embeddedImageIds` list for locally stored images
   - Updated serialization and deserialization methods
   - Enhanced markdown processing to handle image references

3. **LinkedItemsManager**:
   - Added methods for tracking embedded image IDs
   - Updated journal entry updating to include embedded image IDs

### Markdown Integration

The system supports a custom format for image references in markdown:
- Standard format: `![alt](url)` for URL-based images
- Custom format: `![alt](id:imageId)` for locally stored images

This allows for seamless integration with the existing markdown processing system while supporting both types of images.

### Benefits

- **Flexibility**: Supports both URL-based and locally stored images
- **Offline Support**: Images can be saved locally for offline use
- **Consistency**: Provides a consistent UI for image selection and display
- **Extensibility**: Designed to support future enhancements like AI-generated images
- **Modularity**: Components can be developed and tested independently

This architecture follows the same pattern as other systems in the application, providing a consistent approach to component organization and interaction.

## Loading Screen Architecture

The application implements a specialized loading screen pattern for handling resource-intensive operations that may take significant time to complete. This pattern provides a visually engaging experience while background processes run.

```
┌─────────────────────────────────────────────────────────┐
│                   LoadingScreen                         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Background Loading                  │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ DataswornLoading│  │ Minimum Time Enforcer│  │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              ConsoleTextAnimation               │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Message Provider│  │ Typing Animation    │   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  │  ┌─────────────────┐  ┌─────────────────────┐   │   │
│  │  │ Fixed Messages  │  │ Random Boot Messages│   │   │
│  │  └─────────────────┘  └─────────────────────┘   │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Key Components

1. **LoadingScreen**: Coordinates the loading process and animation
   - Manages the state of resource loading (e.g., Datasworn data)
   - Enforces minimum loading time for better user experience
   - Provides message sequences to the animation component
   - Handles navigation after loading completes

2. **ConsoleTextAnimation**: Displays animated console-style text
   - Uses a message provider callback to get messages dynamically
   - Implements typing animation with character-by-character display
   - Shows fixed messages with guaranteed minimum display times
   - Displays random messages during background loading
   - Shows "System ready." only when loading is complete

### Process Flow

1. When a resource-intensive operation is needed (e.g., loading Datasworn data):
   - The LoadingScreen is shown with a console-style animation
   - Fixed initial messages are displayed with minimum display times
   - Background loading of resources begins simultaneously
   - Random "boot" messages are shown while loading continues
   - When loading completes, "System ready." is displayed
   - After a short delay, navigation to the target screen occurs

2. The implementation ensures:
   - A minimum loading time (e.g., 3 seconds) even if loading completes quickly
   - Proper coordination between animation and background loading
   - Graceful handling of loading errors
   - Smooth transition to the target screen

### Benefits

- **Improved User Experience**: Provides visual feedback during long-running operations
- **Reduced Perceived Wait Time**: Engaging animation makes waiting feel shorter
- **Flexible Message System**: Can be customized for different loading contexts
- **Proper Resource Loading**: Ensures resources are fully loaded before proceeding
- **Error Resilience**: Handles loading failures gracefully

### Reusability

This pattern can be applied to other resource-intensive operations in the application:
- Initial data loading
- Large asset downloads
- Complex data processing
- Image loading and caching
- Any operation that might take more than a second to complete

The message provider pattern allows for easy customization of the loading messages for different contexts, making this a highly reusable component.
