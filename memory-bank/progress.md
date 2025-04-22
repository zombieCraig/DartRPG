# Progress Report: DartRPG

## Current Status

The DartRPG application is in active development with core functionality implemented and working. The application provides a digital companion for Ironsworn-based RPG systems, with a focus on the Fe-Runners hacking-themed game. Recent work has focused on implementing a Quest viewer system and enhancing the journal entry system with rich text editing capabilities.

**Overall Progress**: ~90% complete towards initial release

## What Works

### Core Functionality
- ✅ Game creation, editing, and deletion
- ✅ Character management (creation, editing, stats tracking)
- ✅ Location tracking and management with network graph visualization
- ✅ Session management and journal entries
- ✅ Move and oracle consultation
- ✅ Dice rolling mechanics
- ✅ Quest tracking and management
- ✅ Basic navigation and UI flow

### Data Management
- ✅ Local storage of game data using SharedPreferences
- ✅ JSON serialization/deserialization of game objects
- ✅ Import/export functionality for game data
- ✅ Settings persistence
- ✅ Location connection management and persistence
- ✅ Quest data persistence and status tracking

### User Interface
- ✅ Game selection screen
- ✅ Game screen with bottom navigation
- ✅ Journal screen and entry editing
- ✅ Character screen
- ✅ Location screen with graph and list views
- ✅ Moves and oracles screens
- ✅ Quests screen with tabs for different quest statuses
- ✅ Settings screen with customization options
- ✅ Dark mode support
- ✅ Font size and family customization
- ✅ Comprehensive logging system and log viewer

### Recently Completed
- ✅ Implemented AI image generation for character portraits and other game assets:
  - ✅ Created `AiImageProvider` to handle generating images using AI services
  - ✅ Added support for the Minimax API as the initial AI provider
  - ✅ Implemented context-aware prompt generation based on character, location, or journal entry data
  - ✅ Created `AiImageGenerationSettingsWidget` for configuring AI image generation settings
  - ✅ Enhanced `ImagePickerDialog` with an AI tab for generating and selecting AI images
  - ✅ Added support for saving API keys for different AI providers
  - ✅ Implemented proper error handling for API responses, including "insufficient balance" errors
  - ✅ Added detailed logging for debugging API interactions
  - ✅ Ensured AI-generated images are properly saved to permanent storage
  - ✅ Updated the character screen to refresh immediately when images are updated
  - ✅ Modified the `Game` model to store AI image generation settings
  - ✅ Added help text and links to guide users in setting up their API keys
  - ✅ This implementation provides a powerful tool for creating thematic images for game content
- ✅ Implemented a robust image handling system for uploading, saving, and displaying images:
  - ✅ Created `AppImage` model to represent images with metadata
  - ✅ Implemented `ImageStorageService` to handle saving and loading images to/from disk
  - ✅ Added `ImageManagerProvider` to manage images throughout the app
  - ✅ Created `AppImageWidget` for displaying images from both URLs and local storage
  - ✅ Implemented `ImagePickerDialog` for selecting images from different sources
  - ✅ Enhanced the `JournalEntry` model to support both URL-based and locally stored images
  - ✅ Updated the `Character` model to include an `imageId` field for locally stored images
  - ✅ Modified the `JournalEntryEditor` to use the new image picker dialog
  - ✅ Enhanced the `JournalEntryViewer` to render both URL and local images inline
  - ✅ Updated the `LinkedItemsSummary` widget to display both types of images
  - ✅ Added special handling for image markdown syntax (![alt](url))
  - ✅ Implemented support for a custom format for local images (id:imageId)
- ✅ Implemented a Linked Items feature in the journal editor to view linked characters, locations, move rolls, and oracle rolls:
  - ✅ Added a "Linked Items" button to the editor toolbar for toggling the linked items section
  - ✅ Reused the existing LinkedItemsSummary component from the journal entry viewer
  - ✅ Implemented dialog-based viewing of linked item details when clicked
  - ✅ Modified the following files:
    - ✅ `dart_rpg/lib/widgets/journal/editor_toolbar.dart`: Added Linked Items button
    - ✅ `dart_rpg/lib/widgets/journal/journal_entry_editor.dart`: Added linked items section and dialog methods
    - ✅ `dart_rpg/lib/screens/journal_entry_screen.dart`: Updated to pass the onLinkedItemsPressed callback
  - ✅ This feature provides easy access to linked content while editing journal entries
  - ✅ Improves user experience by allowing reference to linked items without leaving the editor
- ✅ Simplified the search functionality in the Move Dialog and Moves Screen to only search move titles:
  - ✅ Modified the search filter in both locations to only check `move.name` instead of also checking `move.description` and `move.trigger`
  - ✅ Updated the hint text from "Enter move name or description" to "Enter move title" for clarity
  - ✅ Modified the following files:
    - ✅ `dart_rpg/lib/widgets/journal/move_dialog.dart`: Updated search filter and hint text
    - ✅ `dart_rpg/lib/screens/moves_screen.dart`: Updated search filter and hint text
  - ✅ This change makes the search more focused and only returns moves whose titles match the search query
  - ✅ Improved user experience by providing more relevant search results
- ✅ Further modularized the Location Graph System into specialized components following the component extraction pattern:
  - ✅ LocationGraphController: Manages the state and logic for the graph
  - ✅ LocationNodeRenderer: Handles the rendering of location nodes
  - ✅ LocationEdgeRenderer: Handles the rendering of edges between nodes
  - ✅ LocationInteractionHandler: Handles user interactions with the graph
  - ✅ LocationGraphWidget: Orchestrates the other components and renders the graph
- ✅ Created a dedicated LocationEdgePainter for drawing edges between nodes
- ✅ Added an index file for easy importing of all location graph components
- ✅ Created comprehensive documentation in a README file
- ✅ Enhanced screen transitions with improved visual effects and added a new Circuit Reveal transition
- ✅ Fixed deprecated `withOpacity()` method usage throughout the codebase
- ✅ Replaced all instances with `withAlpha()` for better precision and future compatibility
- ✅ Updated multiple files including location_graph_widget.dart, location_node_widget.dart, oracle_category_list.dart, and quest_card.dart
- ✅ Documented conversion formula (Alpha = Opacity × 255) for future reference
- ✅ Added code quality best practices to `.clinerules` file
- ✅ Created a comprehensive guide for handling color opacity in Flutter
- ✅ Documented common opacity-to-alpha conversions for reference
- ✅ Added special handling patterns for dynamic opacity with animations
- ✅ Created a code review checklist for catching deprecation issues
- ✅ Implemented a countdown clock system for tracking game events
- ✅ Created Clock model with properties for title, segments (4, 6, 8, or 10), type (Campaign, Tension, or Trace), and progress
- ✅ Developed a custom ClockSegmentPainter for drawing circular segmented clocks
- ✅ Added clock-related methods to the Game model and GameProvider
- ✅ Created specialized components for the clock system:
  - ✅ ClockService: Service for clock operations
  - ✅ ClockForm: Component for clock data entry
  - ✅ ClockDialog: Component for clock creation and editing
  - ✅ ClockProgressPanel: Component for displaying and managing clock progress
  - ✅ ClockCard: Component for displaying individual clocks
  - ✅ ClocksTabView: Component for displaying the clocks tab
- ✅ Added a new "Clocks" tab to the Quests screen
- ✅ Implemented "Advance all Campaign" and "Advance all Tension" buttons for batch operations
- ✅ Added journal entry creation when clocks are filled completely
- ✅ Created unit tests for the Clock model and Game model's clock-related methods
- ✅ Enhanced the UI with clear, high-contrast buttons for better readability
- ✅ Implemented dropdown and dice button for moves with embedded oracles
- ✅ Created MoveOracle model to represent embedded oracles in moves
- ✅ Enhanced the Move model to handle embedded oracles
- ✅ Created MoveOraclePanel widget to display the dropdown and dice button
- ✅ Updated MoveDetails widget to include the MoveOraclePanel when a move has embedded oracles
- ✅ Updated MoveDialog class to handle oracle rolls from moves
- ✅ Fixed issue with oracle results not showing in the journal
- ✅ Stored oracle results in the MoveRoll's moveData property
- ✅ Enhanced journal entry display to show oracle results
- ✅ Added tests to verify the implementation
- ✅ Improved the user experience for moves with embedded oracles
- ✅ Improved asset card system to properly display abilities with toggle circles
- ✅ Created a flexible AssetContentWidget that handles both summary and detail views
- ✅ Fixed layout issues that were causing overflow errors in asset cards
- ✅ Updated all asset display locations to use the new components consistently
- ✅ Modified the AssetPanel to use the AssetDetailDialog for consistent display
- ✅ Implemented tutorial system with contextual help popups for new players
- ✅ Created TutorialService to manage tutorial state and display logic
- ✅ Developed a reusable TutorialPopup widget for displaying contextual help
- ✅ Added global and per-game settings to enable/disable tutorials
- ✅ Integrated tutorials with the Journal Screen to guide users in creating sessions
- ✅ Implemented persistence of tutorial state using SharedPreferences
- ✅ Enhanced character short name functionality with auto-generation and customization options
- ✅ Added "Random Handle" and "Make l33t" buttons to the character form
- ✅ Created LeetSpeakConverter utility for converting text to leet speak
- ✅ Enhanced OracleService with recursive search for oracle tables by key anywhere in hierarchy
- ✅ Improved oracle table lookup to work with nested tables like "social/fe_runner_handles"
- ✅ Implemented a loading screen for resource-intensive operations with console-style animation
- ✅ Created a dynamic message provider system for flexible loading screen content
- ✅ Added background loading of Datasworn data with proper coordination
- ✅ Implemented minimum loading time enforcement for better user experience
- ✅ Added "System ready." message that only appears when loading is complete
- ✅ Restructured the Location Graph System into a more modular and maintainable architecture
- ✅ Created specialized components for the location system:
  - ✅ LocationService: Service for location operations
  - ✅ LocationForm: Component for location data entry
  - ✅ ConnectionPanel: Component for managing connections
  - ✅ LocationNodeWidget: Component for displaying individual nodes
  - ✅ LocationDialog: Component for location creation and editing
  - ✅ LocationListView: Component for displaying locations in list format
- ✅ Simplified the LocationScreen by delegating to specialized components
- ✅ Improved error handling and user feedback for location operations
- ✅ Restructured the Quest Management System into a more modular and maintainable architecture
- ✅ Created specialized components for the quest system:
  - ✅ QuestForm: Component for quest data entry
  - ✅ QuestDialog: Component for quest creation and editing
  - ✅ QuestProgressPanel: Component for progress tracking
  - ✅ QuestTabList: Component for displaying quests by status
  - ✅ QuestCard: Component for displaying individual quests
  - ✅ QuestActionsPanel: Component for quest actions
  - ✅ QuestService: Service for quest operations
- ✅ Added tests for the new quest components
- ✅ Restructured the Move functionality into a more modular and maintainable architecture
- ✅ Created a dedicated MoveDialog class to encapsulate move selection and rolling logic
- ✅ Separated move-related widgets into specialized components
- ✅ Moved move-related methods from JournalEntryScreen to the MoveDialog class
- ✅ Enhanced test structure to accommodate the new architecture
- ✅ Fixed issues with the Move button in the journal entry screen
- ✅ Improved test reliability by making tests more resilient to UI changes
- ✅ Implemented automatic processing of oracle references in oracle results
- ✅ Enhanced DataswornLinkParser to handle both link formats for oracle references
- ✅ Created OracleReferenceProcessor utility to process nested oracle references
- ✅ Updated OracleResultText widget to handle reference processing with loading indicators
- ✅ Enhanced OracleRoll model to store nested oracle rolls
- ✅ Modified all oracle rolling methods to use the new reference processing functionality
- ✅ Added comprehensive error handling and logging for oracle reference processing
- ✅ Improved oracle result display to show nested oracle rolls
- ✅ Added unit tests to verify oracle reference processing functionality
- ✅ Fixed issue with collections in JSON file not being properly parsed
- ✅ Standardized logging approach to always use LoggingService instead of dart:developer
- ✅ Updated DataswornLinkParser to use LoggingService for consistent logging
- ✅ Enhanced logging with proper tags and context information for better traceability
- ✅ Quest button in journal editor toolbar for direct access to Quest Screen
- ✅ Fixed GameScreen to respect initialTabIndex when explicitly provided
- ✅ Enhanced keyboard shortcut handling for CTRL+Q in the editor
- ✅ Quest viewer with tabs for Ongoing, Completed, and Forsaken quests
- ✅ Quest creation and management functionality
- ✅ Quest progress tracking with 10-segment progress bar
- ✅ Quest status changes (complete, forsake)
- ✅ Keyboard shortcuts for quick navigation (CTRL+Q for Quests)
- ✅ Enhanced journal entry screen with rich text editing
- ✅ Character handle/short name support for easier referencing
- ✅ Autocompletion for character and location references
- ✅ Linked items summary for journal entries
- ✅ Improved navigation flow based on character creation status

## What's Left to Build

### High Priority
- ✅ Oracle Dialog System Restructuring
  - ✅ Created OracleDialog class
  - ✅ Extracted OracleCategoryList and OracleTableList components
  - ✅ Created OracleRollPanel and OracleResultView components
  - ✅ Moved oracle rolling logic to OracleService
  - ✅ Updated JournalEntryScreen to use the new components
  - ✅ Added tests for the new components
- ✅ Countdown Clock Feature Implementation
  - ✅ Created Clock model with properties for title, segments, type, and progress
  - ✅ Developed a custom ClockSegmentPainter for drawing circular segmented clocks
  - ✅ Added clock-related methods to the Game model and GameProvider
  - ✅ Created specialized components for the clock system
  - ✅ Added a new "Clocks" tab to the Quests screen
  - ✅ Implemented "Advance all Campaign" and "Advance all Tension" buttons
  - ✅ Added journal entry creation when clocks are filled completely
  - ✅ Created unit tests for the Clock model and Game model's clock-related methods
- ✅ Location Graph System Further Modularization
  - ✅ Created LocationGraphController for state and logic management
  - ✅ Created LocationNodeRenderer for node rendering
  - ✅ Created LocationEdgeRenderer for edge rendering
  - ✅ Created LocationInteractionHandler for user interactions
  - ✅ Refactored LocationGraphWidget to use these specialized components
  - ✅ Created comprehensive documentation in a README file
- ✅ GitHub Actions Workflow Fixes
  - ✅ Fixed deprecated `set-output` command warning
  - ✅ Updated Windows build path to include x64 directory
  - ✅ Added better error handling and diagnostics
  - ✅ Fixed macOS packaging issues
  - ✅ Updated documentation
- ⬜ Testing for Quest system features
- ⬜ Performance optimization for complex journal entries
- ⬜ UI refinements for the rich text editor and quest cards
- ⬜ Mobile-friendly interaction improvements for text editing

### Future Restructuring Candidates
- ✅ Journal Entry Editor System
  - ✅ Created a dedicated JournalEntryEditor component
  - ✅ Extracted EditorToolbar component for formatting actions
  - ✅ Created specialized AutocompleteSystem component
  - ✅ Extracted LinkedItemsManager for handling references
  - ✅ Moved autosave logic to a dedicated service
- ✅ Quest Management System
  - ✅ Created a dedicated QuestDialog class for creation/editing
  - ✅ Extracted QuestForm component for quest data entry
  - ✅ Created QuestProgressPanel for progress management
  - ✅ Extracted QuestTabList for displaying quest lists by status
  - ✅ Created QuestCard component for individual quest display
  - ✅ Created QuestActionsPanel for quest actions
  - ✅ Created QuestService for quest operations
- ✅ Location Graph System
  - ✅ Created LocationDialog class for creation/editing
  - ✅ Created LocationForm component for location data entry
  - ✅ Created ConnectionPanel for managing connections
  - ✅ Created LocationNodeWidget for individual node display
  - ✅ Created LocationService for location operations
  - ✅ Created LocationListView for displaying locations in list format
  - ✅ Created LocationGraphController for state and logic management
  - ✅ Created LocationNodeRenderer for node rendering
  - ✅ Created LocationEdgeRenderer for edge rendering
  - ✅ Created LocationInteractionHandler for user interactions
- ⬜ Character Management System
  - ⬜ Create a dedicated CharacterDialog class for creation/editing
  - ⬜ Extract CharacterForm component for character data entry
  - ⬜ Create StatPanel for stat management
  - ⬜ Create ConditionPanel for condition meters

### Medium Priority
- ⬜ Enhanced character progression tracking
- ⬜ Improved asset management
- ⬜ Full-text search across journal entries
- ⬜ Better linking between journal entries and game elements
- ⬜ Relationship mapping between characters and locations
- ⬜ Quest dependencies and prerequisites

### Low Priority
- ✅ In-app help and tutorials
- ⬜ Customizable themes beyond light/dark mode
- ⬜ Data backup and cloud sync options
- ⬜ Advanced multimedia support in journal entries (audio, video)
- ⬜ Journal entry templates and presets
- ⬜ Quest categories and tags

## Known Issues

### Critical
- None currently identified

### High Priority
- **Graph Performance**: Large networks may experience performance issues
- **Position Persistence**: Position saving may not work perfectly in all scenarios
- **Data Size Limitations**: SharedPreferences may have issues with very large game datasets
- **Rich Text Persistence**: Complex formatting may not be perfectly preserved in all cases

### Medium Priority
- **UI Responsiveness**: Some screens may become sluggish with large amounts of data
- **Graph Layout**: Auto-layout algorithm may not produce optimal results in all cases
- **Image Handling**: Embedded images may have display issues on some devices
- **Quest Filtering**: Performance may degrade with large numbers of quests

### Low Priority
- **Visual Polish**: Some UI elements could use refinement
- **Accessibility**: Additional accessibility features needed
- **Tablet Support**: UI not fully optimized for tablet screens

### Recently Fixed Issues
- ✅ **AI Image Generation**: Fixed issue with AI-generated images not being properly saved to permanent storage and not refreshing in the character screen after editing
- ✅ **Image Handling System**: Implemented a robust system for uploading, saving, and displaying images from both URLs and local storage, with support for custom image markdown syntax
- ✅ **Journal Editor Linked Items**: Added a Linked Items feature to the journal editor that allows viewing and interacting with linked characters, locations, move rolls, and oracle rolls while editing
- ✅ **Move Results Formatting**: Fixed formatting issue with the move results screen in the journal editor by adding `softLineBreak: true` to all MarkdownBody widgets, ensuring consistent text formatting with soft newline returns
- ✅ **Journal Entry Navigation**: Fixed issue with duplicate back buttons in the journal editor when accessed from the quests screen by adding metadata to journal entries and conditionally hiding the AppBar back button
- ✅ **GitHub Actions Windows Build**: Fixed PowerShell compatibility issue by adding explicit bash shell specification for the version extraction step
- ✅ **Location Graph Complexity**: Modularized the location graph system into specialized components for better maintainability
- ✅ **Screen Transitions**: Enhanced the Hacker Fade transition with improved visual effects and added a new Circuit Reveal transition
- ✅ **Deprecated Functions**: Fixed deprecated `withOpacity()` method usage throughout the codebase, replacing with `withAlpha()` for better precision and future compatibility
- ✅ **Code Quality Documentation**: Added comprehensive guide for handling color opacity in Flutter to `.clinerules` file
- ✅ **Move Oracle Results**: Fixed issue with oracle results from moves not showing in the journal
- ✅ **Asset Card Display**: Fixed layout issues in asset cards and improved ability display with toggle circles
- ✅ **Asset Detail Dialog**: Updated character asset detail dialog to use the improved AssetDetailDialog
- ✅ **Oracle Table Lookup**: Enhanced oracle table lookup to find tables by key anywhere in the hierarchy
- ✅ **Oracle Reference Processing**: Implemented automatic processing of nested oracle references in oracle results
- ✅ **Oracle Result Display**: Enhanced oracle result display to show nested oracle rolls
- ✅ **Oracle Collection Parsing**: Fixed issue with collections in JSON file not being properly parsed, enabling display of node types like "Science & Research"
- ✅ **Navigation Flow**: Improved navigation patterns especially for game screen with main character
- ✅ **Autocompletion Accuracy**: Enhanced character/location matching with inline suggestions
- ✅ **Keyboard Shortcuts**: Added support for tab completion and move/oracle/quest shortcuts
- ✅ **Journal Entry Bugs**: Fixed duplicate entry creation and entry opening issues
- ✅ **Journal Content Loading**: Fixed bug where journal entry content wasn't loading in the editor
- ✅ **Dark Mode Readability**: Improved text contrast in dark mode for Asset Cards
- ✅ **Search Functionality**: Added search to Moves and Oracles screens
- ✅ **Oracle Widget**: Fixed Oracle widget in journal entry screen to prevent errors when rolling on categories
- ✅ **Oracle Navigation**: Improved Oracle screen navigation with dedicated category and table screens
- ✅ **Oracle Dialog**: Added search functionality to Oracle dialog in journal entry screen
- ✅ **Regression Testing**: Added comprehensive test suite for Oracle functionality
- ✅ **Journal Navigation**: Added "Jump to last entry" button on journal screen when entries are scrollable

## Recent Milestones

### Milestone: AI Image Generation Feature Implementation (April 2025)
- ✅ Implemented AI image generation for character portraits and other game assets:
  - ✅ Created `AiImageProvider` to handle generating images using AI services
  - ✅ Added support for the Minimax API as the initial AI provider
  - ✅ Implemented context-aware prompt generation based on character, location, or journal entry data
  - ✅ Created `AiImageGenerationSettingsWidget` for configuring AI image generation settings
  - ✅ Enhanced `ImagePickerDialog` with an AI tab for generating and selecting AI images
  - ✅ Added support for saving API keys for different AI providers
  - ✅ Implemented proper error handling for API responses, including "insufficient balance" errors
  - ✅ Added detailed logging for debugging API interactions
  - ✅ Ensured AI-generated images are properly saved to permanent storage
  - ✅ Updated the character screen to refresh immediately when images are updated
  - ✅ Modified the `Game` model to store AI image generation settings
  - ✅ Added help text and links to guide users in setting up their API keys
  - ✅ This implementation provides a powerful tool for creating thematic images for game content

### Milestone: Image Handling System Implementation (April 2025)
- ✅ Implemented a robust image handling system for uploading, saving, and displaying images:
  - ✅ Created `AppImage` model to represent images with metadata
  - ✅ Implemented `ImageStorageService` to handle saving and loading images to/from disk
  - ✅ Added `ImageManagerProvider` to manage images throughout the app
  - ✅ Created `AppImageWidget` for displaying images from both URLs and local storage
  - ✅ Implemented `ImagePickerDialog` for selecting images from different sources
  - ✅ Enhanced the `JournalEntry` model to support both URL-based and locally stored images
  - ✅ Updated the `Character` model to include an `imageId` field for locally stored images
  - ✅ Modified the `JournalEntryEditor` to use the new image picker dialog
  - ✅ Enhanced the `JournalEntryViewer` to render both URL and local images inline
  - ✅ Updated the `LinkedItemsSummary` widget to display both types of images
  - ✅ Added special handling for image markdown syntax (![alt](url))
  - ✅ Implemented support for a custom format for local images (id:imageId)
  - ✅ This implementation lays the groundwork for future enhancements like AI-generated images

### Milestone: Journal Editor Linked Items Feature Implementation (April 2025)
- ✅ Implemented a Linked Items feature in the journal editor to view linked characters, locations, move rolls, and oracle rolls:
  - ✅ Added a "Linked Items" button to the editor toolbar for toggling the linked items section
  - ✅ Reused the existing LinkedItemsSummary component from the journal entry viewer
  - ✅ Implemented dialog-based viewing of linked item details when clicked
  - ✅ Modified the following files:
    - ✅ `dart_rpg/lib/widgets/journal/editor_toolbar.dart`: Added Linked Items button
    - ✅ `dart_rpg/lib/widgets/journal/journal_entry_editor.dart`: Added linked items section and dialog methods
    - ✅ `dart_rpg/lib/screens/journal_entry_screen.dart`: Updated to pass the onLinkedItemsPressed callback
  - ✅ This feature provides easy access to linked content while editing journal entries
  - ✅ Improves user experience by allowing reference to linked items without leaving the editor
  - ✅ Ensures consistent behavior between the journal entry viewer and editor

### Milestone: Move Results Screen Formatting Fix (April 2025)
- ✅ Fixed formatting issue with the move results screen in the journal editor:
  - ✅ Added `softLineBreak: true` to all MarkdownBody widgets in the move results screens
  - ✅ Modified `roll_result_view.dart` to ensure proper text formatting with soft newline returns
  - ✅ Verified `softLineBreak: true` property in `journal_entry_viewer.dart` and `journal_entry_screen.dart`
  - ✅ Ensured consistent formatting between the initial move dialog and the results screen
  - ✅ Improved readability of move descriptions and outcomes throughout the application
  - ✅ Updated memory bank documentation to reflect the changes

### Milestone: GitHub Actions Workflow Fixes (April 2025)
- ✅ Fixed issues with the multi-platform release GitHub Actions workflow:
  - ✅ Replaced the deprecated `actions/upload-release-asset@v1` action with the modern `softprops/action-gh-release@v1`
  - ✅ Resolved the warning about the deprecated `set-output` command
  - ✅ Updated the Windows build path to include the `x64` directory: `build/windows/x64/runner/Release`
  - ✅ Added directory verification to provide better error messages if the path is incorrect
  - ✅ Added directory listing to help diagnose path issues
  - ✅ Added file existence verification after creating the macOS zip file
  - ✅ Improved error reporting for macOS packaging
  - ✅ Updated the MULTI_PLATFORM_RELEASE.md documentation to reflect these changes

### Milestone: Location Graph System Modularization (April 2025)
- ✅ Further modularized the Location Graph System into specialized components following the component extraction pattern:
  - ✅ LocationGraphController: Manages the state and logic for the graph
  - ✅ LocationNodeRenderer: Handles the rendering of location nodes
  - ✅ LocationEdgeRenderer: Handles the rendering of edges between nodes
  - ✅ LocationInteractionHandler: Handles user interactions with the graph
  - ✅ LocationGraphWidget: Orchestrates the other components and renders the graph
- ✅ Created a dedicated LocationEdgePainter for drawing edges between nodes
- ✅ Added an index file for easy importing of all location graph components
- ✅ Created comprehensive documentation in a README file
- ✅ Improved code organization and maintainability
- ✅ Enhanced separation of concerns for better testability
- ✅ Reduced risk of data loss by isolating changes to specific components
- ✅ Simplified the LocationScreen by delegating to specialized components
- ✅ Prepared the system for future enhancements like performance optimization and new layout algorithms

### Milestone: Screen Transition Enhancements (April 2025)
- ✅ Enhanced the Hacker Fade transition with improved visual effects
  - ✅ Increased matrix rain animation opacity and visibility during transition
  - ✅ Added glitch-like transformations with subtle position offsets
  - ✅ Implemented perspective transformations for 3D-like effects
  - ✅ Added scanline shader effect for a more authentic cyberpunk look
  - ✅ Made the matrix rain animation always visible during transition
- ✅ Added a new Circuit Reveal transition
  - ✅ Created CircuitRevealAnimation widget with custom painter
  - ✅ Implemented circuit board pattern that progressively reveals the screen
  - ✅ Added support for different reveal directions (center-out, left-to-right, etc.)
  - ✅ Used cyan accent color for a distinct cyberpunk aesthetic
  - ✅ Implemented fade-in effect for the content as the circuit pattern reveals
- ✅ Updated TransitionType enum to include the new Circuit Reveal transition
- ✅ Added appropriate icon (developer_board) and description for the new transition
- ✅ Ensured all transitions work consistently with the animation speed settings

### Milestone: Code Quality Improvements (April 2025)
- ✅ Fixed deprecated `withOpacity()` method usage throughout the codebase
- ✅ Replaced all instances with `withAlpha()` for better precision and future compatibility
- ✅ Updated multiple files including location_graph_widget.dart, location_node_widget.dart, oracle_category_list.dart, and quest_card.dart
- ✅ Documented conversion formula (Alpha = Opacity × 255) for future reference
- ✅ Added code quality best practices to `.clinerules` file
- ✅ Created a comprehensive guide for handling color opacity in Flutter
- ✅ Documented common opacity-to-alpha conversions for reference
- ✅ Added special handling patterns for dynamic opacity with animations
- ✅ Created a code review checklist for catching deprecation issues
- ✅ Ran `flutter analyze` and `flutter test` to verify fixes

### Milestone: Countdown Clock Feature Implementation (April 2025)
- ✅ Implemented a countdown clock system for tracking game events
- ✅ Created Clock model with properties for title, segments, type, and progress
- ✅ Developed a custom ClockSegmentPainter for drawing circular segmented clocks
- ✅ Added clock-related methods to the Game model and GameProvider
- ✅ Created specialized components for the clock
