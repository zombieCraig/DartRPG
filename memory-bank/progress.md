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

### Milestone: Tutorial System Implementation (April 2025)
- ✅ Implemented a tutorial system to help guide new players through the application
- ✅ Created a TutorialService to manage tutorial state and display logic
- ✅ Developed a reusable TutorialPopup widget for displaying contextual help
- ✅ Added a global setting to enable/disable tutorials in the SettingsProvider
- ✅ Added a per-game setting to enable/disable tutorials during game creation
- ✅ Integrated tutorials with the Journal Screen to guide users in creating sessions
- ✅ Added tutorial popups that explain what sessions are and how to use them
- ✅ Implemented persistence of tutorial state using SharedPreferences
- ✅ Added ability to disable all tutorials directly from any tutorial popup
- ✅ Designed the system to be easily extensible for adding more tutorials in the future

### Milestone: Character Short Name Enhancements (April 2025)
- ✅ Enhanced character short name (handle) functionality with automatic generation and customization
- ✅ Added auto-generation of short name when field gets focus and is empty but name field is filled
- ✅ Implemented "Random Handle" button that rolls on the fe_runner_handles oracle
- ✅ Added "Make l33t" button with terminal icon to convert short names to leet speak
- ✅ Created LeetSpeakConverter utility for converting text to leet speak
- ✅ Enhanced OracleService with recursive search for oracle tables by key anywhere in hierarchy
- ✅ Improved oracle table lookup to work with nested tables like "social/fe_runner_handles"
- ✅ Made the character creation process more thematically consistent with the cyberpunk theme

### Milestone: Loading Screen Implementation (April 2025)
- ✅ Implemented a specialized loading screen for handling resource-intensive operations
- ✅ Created a console-style text animation with typing effect for visual engagement
- ✅ Implemented background loading of Datasworn data with proper coordination
- ✅ Added support for fixed initial messages with guaranteed minimum display times
- ✅ Created a dynamic message provider system for flexible content generation
- ✅ Implemented random "boot" messages during loading for visual interest
- ✅ Added "System ready." message that only appears when loading is complete
- ✅ Ensured minimum loading time for better user experience
- ✅ Implemented proper error handling and navigation after loading
- ✅ Enhanced the separation of concerns with specialized components
- ✅ Documented the loading screen architecture in the system patterns

### Milestone: Location Graph System Restructuring (April 2025)
- ✅ Restructured the Location Graph functionality into a more modular architecture
- ✅ Created specialized components for different aspects of the location system
- ✅ Improved code organization and maintainability
- ✅ Reduced risk of data loss by isolating changes to specific components
- ✅ Enhanced the separation of concerns in the location system
- ✅ Simplified the LocationScreen by delegating to specialized components
- ✅ Improved error handling and user feedback

### Milestone: Quest Management System Restructuring (April 2025)
- ✅ Restructured the Quest Management functionality into a more modular architecture
- ✅ Created specialized components for different aspects of the quest system
- ✅ Improved code organization and maintainability
- ✅ Reduced risk of data loss by isolating changes to specific components
- ✅ Enhanced the separation of concerns in the quest system
- ✅ Added tests for the new components

### Milestone: Oracle Reference Processing Implementation (April 2025)
- ✅ Enhanced DataswornLinkParser to handle both link formats for oracle references
- ✅ Created OracleReferenceProcessor utility to process nested oracle references
- ✅ Updated OracleResultText widget to handle reference processing with loading indicators
- ✅ Enhanced OracleRoll model to store nested oracle rolls
- ✅ Modified all oracle rolling methods to use the new reference processing functionality
- ✅ Added comprehensive error handling and logging for oracle reference processing
- ✅ Improved oracle result display to show nested oracle rolls
- ✅ Added unit tests to verify oracle reference processing functionality

### Milestone: Quest System Implementation (March 2025)
- ✅ Created Quest model with title, rank, progress, status, and notes
- ✅ Implemented QuestsScreen with tabs for Ongoing, Completed, and Forsaken quests
- ✅ Added quest management methods to GameProvider
- ✅ Implemented progress tracking with 10-segment progress bar
- ✅ Added quest status changes (complete, forsake)
- ✅ Integrated with keyboard shortcuts (CTRL+Q)
- ✅ Connected quest system with journal entries

### Milestone: Journal Entry Improvements (March 2025)
- ✅ Implemented rich text editor with formatting toolbar
- ✅ Added character handle property and automatic generation
- ✅ Created character and location reference system with autocompletion
- ✅ Implemented linked items summary for journal entries
- ✅ Updated navigation flow based on character creation status
- ✅ Added "Jump to last entry" button for improved journal navigation

### Milestone: Location Graph Implementation (March 2025)
- ✅ Updated Location model with segment and connection support
- ✅ Created LocationGraphWidget for visualization
- ✅ Implemented connection management in Game and GameProvider
- ✅ Updated LocationScreen with graph and list views
- ✅ Added segment-based organization and color coding

### Milestone: Logging System Implementation (February 2025)
- ✅ Created LoggingService class
- ✅ Implemented different log levels
- ✅ Added proper error handling in catch blocks
- ✅ Created LogViewerScreen
- ✅ Added log level configuration to settings

### Milestone: Core Game Functionality (January 2025)
- ✅ Implemented game creation and management
- ✅ Added character and location tracking
- ✅ Created journal system
- ✅ Integrated moves and oracles

## Upcoming Milestones

### Milestone: Quest System Enhancements (April 2025)
- ⬜ Add unit tests for Quest model methods
- ⬜ Implement widget tests for QuestsScreen
- ⬜ Enhance quest filtering and sorting
- ⬜ Improve quest card visualization
- ⬜ Optimize quest data persistence

### Milestone: Journal System Enhancements (April 2025)
- ⬜ Rich text editor improvements and bug fixes
- ⬜ Enhanced autocompletion for character and location references
- ⬜ Improved image handling and embedding
- ⬜ Better performance with large journal entries

### Milestone: Graph Enhancements and Stability (April 2025)
- ⬜ Performance optimization for large graphs
- ⬜ Improved graph layout algorithms
- ⬜ Enhanced visual design for nodes and connections
- ⬜ Bug fixes and stability improvements

### Milestone: Enhanced User Experience (May 2025)
- ⬜ UI refinements and visual polish
- ⬜ Improved accessibility
- ⬜ Additional customization options
- ✅ In-app help and tutorials

### Milestone: Advanced Features (June 2025)
- ⬜ Multimedia support
- ⬜ Data backup and sync
- ⬜ Advanced game mechanics
- ⬜ Community features

## Performance Metrics

### Current Performance
- **App Size**: ~16MB
- **Startup Time**: ~2 seconds on mid-range devices
- **Memory Usage**: ~120MB during normal operation
- **Storage Usage**: Varies based on game data (typically <10MB per game)

### Performance Goals
- **App Size**: <20MB
- **Startup Time**: <1.5 seconds on mid-range devices
- **Memory Usage**: <150MB during normal operation
- **Storage Usage**: Efficient storage with compression for large games

## Testing Status

### Automated Testing
- **Unit Tests**: Moderate coverage, primarily for utility functions and model classes
- **Widget Tests**: Limited coverage, focused on critical UI components
- **Integration Tests**: Not yet implemented

### Manual Testing
- **Functional Testing**: Ongoing for all features
- **Usability Testing**: Limited, more needed
- **Performance Testing**: Basic testing completed
- **Cross-platform Testing**: Tested on Android, limited testing on iOS

## Next Development Focus

The immediate focus will be on:

1. **Testing Quest System Features**: Ensuring quest creation, progress tracking, and status changes work correctly
2. **Quest UI Refinements**: Improving the visual design and interaction of quest cards
3. **Performance Optimization**: Addressing potential performance issues with large numbers of quests
4. **Mobile Experience**: Enhancing the touch interaction for mobile devices

Following this, the focus will shift to enhancing the user experience and adding more advanced features such as quest dependencies, full-text search across journal entries, and relationship mapping between characters, locations, and quests.
