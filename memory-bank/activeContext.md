# Active Context: DartRPG

## Current Work Focus

The current development focus is on restructuring the application's components to improve maintainability, testability, and reduce the risk of data loss. This includes:

1. Restructuring the Oracle functionality into a more modular architecture (completed)
2. Restructuring the Move functionality into a more modular architecture (completed)
3. Restructuring the Journal Entry Editor System into specialized components (completed)
4. Restructuring the Quest Management System into specialized components (completed)
5. Restructuring the Location Graph System into specialized components (completed)
6. Planning for future restructuring of the Character Management System
7. Enhancing test coverage for restructured components
8. Improving performance for complex journal entries and large datasets
9. Refining UI for better user experience
10. Documenting the restructured architecture

This work enhances the overall architecture of the application, making it more maintainable and reducing the risk of data loss when making changes to complex features.

## Recent Changes

### Move Oracle Integration (April 2025)
- Implemented dropdown and dice button for moves with embedded oracles
- Created MoveOracle model to represent embedded oracles in moves
- Enhanced the Move model to handle embedded oracles
- Created MoveOraclePanel widget to display the dropdown and dice button
- Updated MoveDetails widget to include the MoveOraclePanel when a move has embedded oracles
- Updated MoveDialog class to handle oracle rolls from moves
- Fixed issue with oracle results not showing in the journal
- Stored oracle results in the MoveRoll's moveData property
- Enhanced journal entry display to show oracle results
- Added tests to verify the implementation
- Improved the user experience for moves with embedded oracles

### Asset Card System Improvements (April 2025)
- Redesigned the asset card system to properly display abilities with toggle circles
- Created a flexible AssetContentWidget that handles both summary and detail views
- Fixed layout issues that were causing overflow errors in asset cards
- Improved the display of asset abilities with toggle circles (empty when disabled, filled when enabled)
- Updated all asset display locations to use the new components consistently
- Removed the asset description section as it's not a field in the JSON
- Modified the AssetPanel to use the AssetDetailDialog for consistent display
- Enhanced the user experience when viewing and managing character assets

### Tutorial System Implementation (April 2025)
- Implemented a tutorial system to help guide new players through the application
- Created a TutorialService to manage tutorial state and display logic
- Developed a reusable TutorialPopup widget for displaying contextual help
- Added a global setting to enable/disable tutorials in the SettingsProvider
- Added a per-game setting to enable/disable tutorials during game creation
- Integrated tutorials with the Journal Screen to guide users in creating sessions
- Added tutorial popups that explain what sessions are and how to use them
- Implemented persistence of tutorial state using SharedPreferences
- Added ability to disable all tutorials directly from any tutorial popup
- Designed the system to be easily extensible for adding more tutorials in the future

### Character Short Name Enhancements (April 2025)
- Enhanced the character short name (handle) functionality with automatic generation and customization options
- Added auto-generation of short name when the field gets focus and is empty but the name field is filled
- Implemented "Random Handle" button that rolls on the fe_runner_handles oracle and appends the result
- Added "Make l33t" button with a terminal icon to convert the short name to leet speak
- Created LeetSpeakConverter utility for converting text to leet speak with appropriate character substitutions
- Enhanced OracleService with a recursive search method to find oracle tables by key anywhere in the hierarchy
- Improved oracle table lookup to work with nested tables like "social/fe_runner_handles"
- Made the character creation process more thematically consistent with the cyberpunk/hacking theme

### Loading Screen Implementation (April 2025)
- Implemented a specialized loading screen for handling resource-intensive operations
- Created a console-style text animation with typing effect for visual engagement
- Implemented background loading of Datasworn data with proper coordination
- Added support for fixed initial messages with guaranteed minimum display times
- Created a dynamic message provider system for flexible content generation
- Implemented random "boot" messages during loading for visual interest
- Added "System ready." message that only appears when loading is complete
- Ensured minimum loading time for better user experience
- Implemented proper error handling and navigation after loading
- Enhanced the separation of concerns with specialized components
- Documented the loading screen architecture in the system patterns

### Location Graph System Restructuring (April 2025)
- Restructured the Location Graph functionality into a more modular and maintainable architecture
- Created specialized components for different aspects of the location system:
  - LocationService: Service for location operations
  - LocationForm: Component for location data entry
  - ConnectionPanel: Component for managing connections
  - LocationNodeWidget: Component for displaying individual nodes
  - LocationDialog: Component for location creation and editing
  - LocationListView: Component for displaying locations in list format
- Improved code organization and maintainability
- Reduced risk of data loss by isolating changes to specific components
- Enhanced the separation of concerns in the location system
- Simplified the LocationScreen by delegating to specialized components
- Improved error handling and user feedback

### Quest Management System Restructuring (April 2025)
- Restructured the Quest Management functionality into a more modular and maintainable architecture
- Created specialized components for different aspects of the quest system:
  - QuestForm: Component for quest data entry
  - QuestDialog: Component for quest creation and editing
  - QuestProgressPanel: Component for progress tracking
  - QuestTabList: Component for displaying quests by status
  - QuestCard: Component for displaying individual quests
  - QuestActionsPanel: Component for quest actions
  - QuestService: Service for quest operations
- Improved code organization and maintainability
- Reduced risk of data loss by isolating changes to specific components
- Enhanced the separation of concerns in the quest system
- Added tests for the new components

### Journal Entry Editor System Restructuring (April 2025)
- Restructured the Journal Entry Editor functionality into a more modular and maintainable architecture
- Created specialized components for different aspects of the journal entry system:
  - JournalEntryEditor: Core component for editing journal entries
  - EditorToolbar: Component for formatting actions
  - AutocompleteSystem: Component for handling character and location autocompletion
  - LinkedItemsManager: Component for managing linked items (characters, locations, etc.)
- Created AutosaveService to handle automatic saving of journal entries
- Improved code organization and maintainability
- Reduced risk of data loss by isolating changes to specific components
- Enhanced the separation of concerns in the journal entry system

### Oracle Dialog System Restructuring (April 2025)
- Restructured the Oracle functionality into a more modular and maintainable architecture
- Created a dedicated OracleDialog class to encapsulate oracle selection and rolling logic
- Separated oracle-related widgets into specialized components:
  - OracleCategoryList for displaying oracle categories
  - OracleTableList for displaying oracle tables
  - OracleRollPanel for rolling on oracles
  - OracleResultView for displaying results with nested rolls
- Created OracleService to handle oracle rolling logic
- Moved oracle-related methods from JournalEntryScreen to the OracleDialog class
- Added tests for the new components
- Improved code organization and maintainability
- Reduced risk of data loss by isolating changes to specific components

### Move System Restructuring (April 2025)
- Restructured the Move functionality into a more modular and maintainable architecture
- Created a dedicated MoveDialog class to encapsulate move selection and rolling logic
- Separated move-related widgets into specialized components:
  - MoveList for displaying and selecting moves
  - MoveDetails for showing move information
  - ActionRollPanel, ProgressRollPanel, and NoRollPanel for different roll types
  - RollResultView for displaying roll outcomes
- Moved move-related methods from JournalEntryScreen to the MoveDialog class
- Enhanced test structure to accommodate the new architecture
- Fixed issues with the Move button in the journal entry screen
- Improved test reliability by making tests more resilient to UI changes

### Oracle Reference Processing Enhancement (April 2025)
- Implemented automatic processing of oracle references in oracle results
- Enhanced DataswornLinkParser to handle both link formats:
  - `[Text](oracle_rollable:path/to/oracle)`
  - `[Text](datasworn:oracle_rollable:path/to/oracle)`
- Created OracleReferenceProcessor utility to process nested oracle references
- Updated OracleResultText widget to handle reference processing with loading indicators
- Enhanced OracleRoll model to store nested oracle rolls
- Modified all oracle rolling methods to use the new reference processing functionality
- Added comprehensive error handling and logging for oracle reference processing
- Improved oracle result display to show nested oracle rolls
- Added unit tests to verify oracle reference processing functionality

### Oracle Parser Enhancement (April 2025)
- Fixed issue with collections in JSON file not being properly parsed
- Enhanced DataswornParser to handle both "contents" and "collections" structures
- Added support for nested oracle collections like "node_type" with subcategories
- Created unit tests to ensure proper parsing of collection structures
- Improved logging for better debugging of oracle parsing issues

### Logging Standardization (March 2025)
- Established standard to always use the custom LoggingService instead of dart:developer or print statements
- Updated DataswornLinkParser to use LoggingService for consistent logging
- Enhanced logging with proper tags and context information for better traceability
- Documented logging best practices in memory bank files

### Journal Editor Toolbar Enhancement (March 2025)
- Added a Quest button to the journal editor toolbar for quick access to the Quest Screen
- Fixed GameScreen to respect initialTabIndex when explicitly provided
- Enhanced keyboard shortcut handling for CTRL+Q to work directly from the editor
- Updated navigation to use pushReplacement for consistent behavior with other screens

### Quest System Implementation (March 2025)
- Added Quest model with properties for title, rank, progress, status, and notes
- Implemented QuestsScreen with three tabs (Ongoing, Completed, Forsaken)
- Created quest management methods in GameProvider
- Added progress tracking with a 10-segment progress bar
- Implemented quest status changes (complete, forsake)
- Added CTRL+Q keyboard shortcut for quick navigation to Quests screen
- Integrated quest system with the journal entry system for recording quest events
- Added quest creation dialog with character association
- Implemented quest progress rolls similar to other game mechanics

### Bug Fixes and UI Improvements (March 2025)
- Fixed duplicate journal entry bug when closing the editor
- Fixed journal entries not opening correctly when clicked
- Fixed Oracle icon inconsistency across the application
- Improved dark mode text readability in Asset Cards
- Added search functionality to Moves and Oracles screens
- Fixed game screen navigation to go to journal screen when main character exists
- Implemented inline suggestions for character/location autocompletion
- Enhanced tab completion for character and location references
- Fixed Oracle widget in journal entry screen to prevent errors when rolling on categories
- Improved Oracle dialog UI with ExpansionTile for categories
- Added search functionality to Oracle dialog in journal entry screen
- Fixed bug where journal entry content wasn't loading in the editor when opening existing entries
- Added "Jump to last entry" button on journal screen when entries are scrollable

### Journal Screen Enhancements
- Added a floating action button to jump to the last journal entry when there are enough entries to create a scroll bar
- Improved scrolling behavior with smooth animations
- Enhanced user experience for reviewing previous journal entries

### Journal Entry Screen Enhancements
- Implemented a rich text editor with markdown-style formatting
- Added toolbar with formatting options (bold, italic, headings, lists)
- Created character and location reference system with @ and # syntax
- Implemented autocompletion for character and location references
- Added image embedding support
- Implemented keyboard shortcuts for common actions (Ctrl+M for Move, Ctrl+O for Oracle, Ctrl+Q for Quests)

### Character Model Improvements
- Added handle/short name property to Character model
- Implemented automatic handle generation from first name if not provided
- Added validation to prevent spaces and special characters in handles
- Updated character creation and editing UI to include handle field
- Modified character reference system to use handles for better readability

### Navigation Flow Improvements
- Updated game screen to check for main character existence
- Modified navigation to go to journal screen if main character exists
- Improved character creation workflow with better validation
- Enhanced journal entry linking with characters and locations

### Linked Items Summary
- Created a collapsible summary of linked items in journal entries
- Implemented sections for characters, locations, move rolls, and oracle rolls
- Added interactive elements to view details of linked items
- Improved visual presentation of move outcomes with color coding

### User Experience Enhancements
- Added tooltips to all toolbar buttons
- Implemented tab-completion for character and location references
- Added visual feedback for autocompletion suggestions with greyed-out text
- Improved error handling and validation in forms
- Enhanced the overall journal writing experience with modern text editor features

## Next Steps

### Short-term Tasks
1. **Testing Quest System Features**
   - Add unit tests for Quest model methods
   - Add widget tests for QuestsScreen and components
   - Test quest progress rolls and status changes
   - Verify integration with journal entry system

3. **UI Refinements**
   - Improve the visual design of the quest cards
   - Enhance the progress bar visualization
   - Add animations for status changes
   - Optimize mobile experience for the quest screen

4. **Performance Optimization**
   - Optimize quest list rendering for large numbers of quests
   - Improve progress tracking and roll calculations
   - Enhance quest filtering and sorting
   - Optimize saving and loading of quest data

5. **Testing Infrastructure**
   - Expand test coverage to other critical components
   - Set up continuous integration for automated testing
   - Create test fixtures for common test scenarios
   - Implement integration tests for key user flows

### Future Restructuring Candidates
Following the successful pattern used in the Move dialog restructuring, Oracle dialog restructuring, Journal Entry Editor restructuring, Quest Management restructuring, and Location Graph System restructuring:

1. **Character Management System**
   - Create a dedicated CharacterDialog class for creation/editing
   - Extract CharacterForm component for character data entry
   - Create StatPanel for stat management
   - Create ConditionPanel for condition meters
   - Extract CharacterList for displaying characters

### Medium-term Goals
1. **Enhanced Quest Features**
   - Add support for quest dependencies and prerequisites
   - Implement quest categories and tags
   - Add milestone tracking within quests
   - Support for recurring or repeatable quests

2. **Gameplay Integration**
   - Link quests to game mechanics and character progression
   - Add automatic quest updates based on game events
   - Implement quest suggestions based on character actions
   - Create relationship mapping between quests, characters, and locations

3. **Export/Import Functionality**
   - Add ability to export quest logs as markdown or PDF
   - Support for sharing quest content between players
   - Implement backup and restore functionality
   - Add printing support for physical copies

## Active Decisions and Considerations

### Quest System Design
- **Current Approach**: Tab-based organization with status filtering
- **Considerations**:
  - Tab-based UI provides clear separation between quest statuses
  - Character-based filtering allows focusing on specific character quests
  - Progress bar visualization provides clear progress tracking
  - Status changes (complete, forsake) move quests between tabs
- **Decision**: Implement a tab-based UI with character filtering and progress tracking

### Quest Progress Tracking
- **Current Approach**: 10-segment progress bar with manual adjustment and progress rolls
- **Considerations**:
  - 10-segment progress aligns with game mechanics
  - Manual adjustment allows flexibility
  - Progress rolls integrate with game mechanics
  - Visual feedback on progress is important for user engagement
- **Decision**: Use a 10-segment progress bar with both manual adjustment and progress rolls

### Quest-Journal Integration
- **Current Approach**: Automatic journal entries for quest status changes
- **Considerations**:
  - Automatic entries provide a record of quest progress
  - Manual entries allow for more detailed storytelling
  - Integration enhances the narrative experience
  - Balance between automation and manual control
- **Decision**: Create automatic journal entries for significant quest events while allowing manual entries

### Rich Text Editor Approach
- **Current Approach**: Custom implementation with markdown-style formatting
- **Considerations**:
  - Custom implementation provides more control over appearance and behavior
  - Using a third-party package would reduce development time but limit customization
  - Need to balance feature richness with simplicity
- **Decision**: Implement a custom editor with focused features specific to journaling needs

### Character Reference System
- **Current Approach**: @ syntax with handle-based references
- **Considerations**:
  - Handle-based references are more concise and readable
  - Automatic handle generation simplifies the user experience
  - Need to balance brevity with clarity
- **Decision**: Use handles for references with automatic generation from first name if not provided

### Autocompletion Strategy
- **Current Approach**: Show suggestions after typing @ or # plus one character
- **Considerations**:
  - Immediate suggestions could be distracting
  - Delayed suggestions might be missed
  - Tab completion provides efficient input
- **Decision**: Show suggestions after one character is typed, with tab completion for efficiency

### Linked Items Summary
- **Current Approach**: Collapsible summary below journal entry
- **Considerations**:
  - Summary provides quick access to referenced items
  - Collapsible UI saves space when not needed
  - Need to balance information density with clarity
- **Decision**: Use a collapsible card-based UI with sections for different item types

## Open Questions

1. **Quest Complexity**: How can we balance quest complexity with usability?
2. **Progress Visualization**: What's the most intuitive way to visualize quest progress?
3. **Quest Dependencies**: Should we implement quest dependencies and prerequisites?
4. **Quest Rewards**: How should quest completion rewards be handled?
5. **Rich Text Persistence**: What's the most efficient way to store and retrieve rich text content?
6. **Autocompletion UX**: How can we make the autocompletion experience more intuitive without being intrusive?
7. **Image Handling**: What's the best approach for handling and storing embedded images?
8. **Performance Limits**: How can we ensure good performance with large journal entries and many references?
9. **Mobile Experience**: How can we optimize the rich text editor for smaller touch screens?

## Current Challenges

1. **Quest Management Complexity**: Balancing feature richness with simplicity and usability
2. **Progress Tracking**: Ensuring progress tracking is intuitive and aligns with game mechanics
3. **Status Transitions**: Making quest status changes clear and intuitive
4. **Text Editor Complexity**: Balancing feature richness with simplicity and usability
5. **Reference Management**: Ensuring references remain valid even when characters or locations are renamed
6. **Performance**: Maintaining smooth performance with complex journal entries and many references
7. **Intuitive Interaction**: Making the editor interaction intuitive for users of all experience levels
8. **Cross-platform Consistency**: Ensuring consistent behavior across different platforms and screen sizes
