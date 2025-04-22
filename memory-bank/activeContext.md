# Active Context: DartRPG

## Current Work Focus

The current development focus is on restructuring the application's components to improve maintainability, testability, and reduce the risk of data loss, as well as adding new gameplay features. This includes:

1. Restructuring the Oracle functionality into a more modular architecture (completed)
2. Restructuring the Move functionality into a more modular architecture (completed)
3. Restructuring the Journal Entry Editor System into specialized components (completed)
4. Restructuring the Quest Management System into specialized components (completed)
5. Restructuring the Location Graph System into specialized components (completed)
6. Implementing the Countdown Clock feature for tracking game events (completed)
7. Addressing code quality issues and deprecated functions (completed)
8. Fixing GitHub Actions workflow for multi-platform builds (completed)
9. Planning for future restructuring of the Character Management System
10. Enhancing test coverage for restructured components
11. Improving performance for complex journal entries and large datasets
12. Refining UI for better user experience
13. Documenting the restructured architecture

This work enhances the overall architecture of the application, making it more maintainable and reducing the risk of data loss when making changes to complex features.

## Recent Changes

### Move Results Screen Formatting Fix (April 2025)
- Fixed formatting issue with the move results screen in the journal editor:
  - Added `softLineBreak: true` to all MarkdownBody widgets in the move results screens
  - Ensured consistent formatting between the initial move dialog and the results screen
  - Modified the following files:
    - `dart_rpg/lib/widgets/moves/roll_result_view.dart`: Added softLineBreak property to MarkdownBody widgets
    - `dart_rpg/lib/widgets/journal/journal_entry_viewer.dart`: Verified softLineBreak property in MarkdownBody widgets
  - This fix ensures that text in move descriptions and outcomes is properly formatted with soft newline returns
  - Improved readability and consistency of move results throughout the application

### Journal Entry Navigation Fix (April 2025)
- Fixed issue with duplicate back buttons in the journal editor when accessed from the quests screen:
  - Added a `metadata` property to the `JournalEntry` class to store additional information about the entry
  - Added a `hideAppBarBackButton` parameter to the `JournalEntryScreen` class to control whether to show the back button in the AppBar
  - Modified the `completeQuest`, `forsakeQuest`, and `makeQuestProgressRoll` methods in the `GameProvider` class to set the metadata for journal entries created from quests
  - Updated the journal screen to check for the metadata property when navigating to the journal entry screen, and to hide the AppBar back button if the entry was created from a quest
  - Key files modified:
    - `dart_rpg/lib/models/journal_entry.dart`: Added metadata property to JournalEntry class
    - `dart_rpg/lib/screens/journal_entry_screen.dart`: Added hideAppBarBackButton parameter
    - `dart_rpg/lib/providers/game_provider.dart`: Updated quest methods to set metadata
    - `dart_rpg/lib/screens/journal_screen.dart`: Updated navigation to use metadata

### GitHub Actions Workflow Fixes (April 2025)
- Fixed issues with the multi-platform release GitHub Actions workflow:
  - Replaced the deprecated `actions/upload-release-asset@v1` action with the modern `softprops/action-gh-release@v1` to resolve the warning about the deprecated `set-output` command
  - Updated the Windows build path to include the `x64` directory: `build/windows/x64/runner/Release`
  - Added directory verification to provide better error messages if the path is incorrect
  - Added directory listing to help diagnose path issues
  - Added file existence verification after creating the macOS zip file
  - Improved error reporting for macOS packaging
  - Added explicit bash shell specification for the version extraction step to fix PowerShell compatibility issues on Windows
  - Updated the MULTI_PLATFORM_RELEASE.md documentation to reflect these changes

### Location Graph "Fit to Screen" Functionality Fix (April 2025)
- Fixed the "fit to screen" button in the Location Graph System to ensure all nodes are visible:
  - Modified the `fitToScreen` method in `LocationGraphController` to always arrange nodes in a circle when called
  - Updated the node arrangement process to save positions to the database immediately
  - Added detailed debugging to track node positions and transformation matrix calculations
  - Fixed the transformation matrix creation to properly center and scale the graph
  - Improved the coordinate system handling to ensure consistent positioning
  - Enhanced the circle arrangement algorithm to better distribute nodes by segment
  - Added more robust error handling for edge cases
  - Ensured proper padding around the graph bounds for better visibility
  - Fixed the file structure confusion by identifying and working with the correct files
  - Updated the memory bank documentation to reflect the correct file structure and implementation details

### Location Graph Auto-Centering Implementation (April 2025)
- Implemented automatic centering of the location graph when the user first navigates to the Location tab:
  - Added a `_isFirstBuild` flag to the `LocationGraphWidgetState` class to track first-time loading
  - Modified the `initState` method to automatically call `fitToScreen` on first load
  - Fixed a critical coordinate system issue in the `fitToScreen` method:
    - Discovered that the graph uses two different coordinate systems:
      - Original coordinate system: (0,0) is the center of the graph, nodes positioned at coordinates like (-200, 0) and (200, 0)
      - Adjusted coordinate system: (0,0) is the top-left corner, used by the `Positioned` widget with nodes adjusted by adding `halfSize` (1000.0)
    - Updated the transformation matrix calculation to account for this coordinate system difference
    - Added conversion from original to adjusted coordinates before calculating translation values
    - Enhanced debugging to track coordinate conversion and transformation matrix creation
  - Improved user experience by eliminating the need to manually click the "fit to screen" button

### Location Graph System Modularization (April 2025)
- Further modularized the Location Graph System into specialized components following the component extraction pattern:
  - LocationGraphController: Manages the state and logic for the graph
  - LocationNodeRenderer: Handles the rendering of location nodes
  - LocationEdgeRenderer: Handles the rendering of edges between nodes
  - LocationInteractionHandler: Handles user interactions with the graph
  - LocationGraphWidget: Orchestrates the other components and renders the graph
- Created a dedicated LocationEdgePainter for drawing edges between nodes
- Added an index file for easy importing of all location graph components
- Created comprehensive documentation in a README file
- Improved code organization and maintainability
- Enhanced separation of concerns for better testability
- Reduced risk of data loss by isolating changes to specific components
- Simplified the LocationScreen by delegating to specialized components
- Prepared the system for future enhancements like performance optimization and new layout algorithms
- Fixed issue with nodes being drawn on top of each other by:
  - Properly initializing node positions from saved locations
  - Generating random positions for nodes without saved positions
  - Implementing a circle-based layout algorithm for auto-arrange mode
  - Grouping nodes by segment in the circle layout
  - Updating the position management to properly store and retrieve positions

### Screen Transition Enhancements (April 2025)
- Enhanced the Hacker Fade transition with improved visual effects:
  - Increased matrix rain animation opacity and visibility during transition
  - Added glitch-like transformations with subtle position offsets
  - Implemented perspective transformations for 3D-like effects
  - Added scanline shader effect for a more authentic cyberpunk look
  - Made the matrix rain animation always visible during transition
- Added a new Circuit Reveal transition:
  - Created CircuitRevealAnimation widget with custom painter
  - Implemented circuit board pattern that progressively reveals the screen
  - Added support for different reveal directions (center-out, left-to-right, etc.)
  - Used cyan accent color for a distinct cyberpunk aesthetic
  - Implemented fade-in effect for the content as the circuit pattern reveals
- Updated TransitionType enum to include the new Circuit Reveal transition
- Added appropriate icon (developer_board) and description for the new transition
- Ensured all transitions work consistently with the animation speed settings

### Code Quality Improvements (April 2025)
- Fixed deprecated `withOpacity()` method usage throughout the codebase
- Replaced all instances with `withAlpha()` for better precision and future compatibility
- Updated multiple files including:
  - location_graph_widget.dart
  - location_node_widget.dart
  - oracle_category_list.dart
  - quest_card.dart
- Documented conversion formula (Alpha = Opacity × 255) for future reference
- Added code quality best practices to `.clinerules` file
- Created a comprehensive guide for handling color opacity in Flutter
- Documented common opacity-to-alpha conversions for reference
- Added special handling patterns for dynamic opacity with animations
- Created a code review checklist for catching deprecation issues
- Ran `flutter analyze` and `flutter test` to verify fixes

### Countdown Clock Feature Implementation (April 2025)
- Implemented a countdown clock system for tracking game events
- Created Clock model with properties for title, segments (4, 6, 8, or 10), type (Campaign, Tension, or Trace), and progress
- Developed a custom ClockSegmentPainter for drawing circular segmented clocks
- Added clock-related methods to the Game model and GameProvider
- Created specialized components for the clock system:
  - ClockService: Service for clock operations
  - ClockForm: Component for clock data entry
  - ClockDialog: Component for clock creation and editing
  - ClockProgressPanel: Component for displaying and managing clock progress
  - ClockCard: Component for displaying individual clocks
  - ClocksTabView: Component for displaying the clocks tab
- Added a new "Clocks" tab to the Quests screen
- Implemented "Advance all Campaign" and "Advance all Tension" buttons for batch operations
- Added journal entry creation when clocks are filled completely
- Created unit tests for the Clock model and Game model's clock-related methods
- Enhanced the UI with clear, high-contrast buttons for better readability

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
1. **Continue Code Quality Improvements**
   - Run `flutter analyze` regularly to catch new deprecation warnings
   - Address any remaining code quality issues
   - Implement the code review checklist for new code
   - Consider creating helper methods for common opacity-to-alpha conversions

2. **Testing Countdown Clock Features**
   - Add widget tests for ClocksTabView and components
   - Test clock advancement and reset functionality
   - Verify integration with journal entry system
   - Test batch operations for advancing clocks by type

3. **Countdown Clock UI Refinements**
   - Improve the visual design of the clock visualization
   - Add animations for clock advancement
   - Optimize mobile experience for the clocks tab
   - Enhance accessibility features for the clock components

4. **UI Refinements**
   - Improve the visual design of the quest cards
   - Enhance the progress bar visualization
   - Add animations for status changes
   - Optimize mobile experience for the quest screen

5. **Performance Optimization**
   - Optimize quest list rendering for large numbers of quests
   - Improve progress tracking and roll calculations
   - Enhance quest filtering and sorting
   - Optimize saving and loading of quest data

6. **Testing Infrastructure**
   - Expand test coverage to other critical components
   - Set up continuous integration for automated testing
   - Create test fixtures for common test scenarios
   - Implement integration tests for key user flows

7. **Location Graph Performance Optimization**
   - Improve rendering performance for large graphs
   - Optimize node positioning algorithm
   - Implement more efficient edge rendering
   - Add support for graph zooming and panning optimizations

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

4. **Location Graph Enhancements**
   - Add more layout algorithms for different graph visualization styles
   - Implement edge styling options for different connection types
   - Add support for grouping nodes by segment or other criteria
   - Create a minimap for navigating large graphs
   - Add support for exporting and importing graph layouts

## Active Decisions and Considerations

### Location Graph Modularization Approach
- **Current Approach**: Component extraction pattern with specialized components
- **Considerations**:
  - Breaking down the large LocationGraphWidget into smaller, focused components
  - Separating state management, rendering, and interaction handling
  - Improving testability by isolating components
  - Enhancing maintainability with clear component responsibilities
- **Decision**: Implement a modular architecture with LocationGraphController, LocationNodeRenderer, LocationEdgeRenderer, and LocationInteractionHandler

### Code Quality Approach
- **Current Approach**: Proactive identification and fixing of deprecated functions
- **Considerations**:
  - Deprecated functions may cause issues in future Flutter versions
  - Addressing issues early prevents technical debt accumulation
  - Documentation helps prevent similar issues in future code
  - Standardized approaches improve code consistency
- **Decision**: Document best practices in `.clinerules` and fix all instances of deprecated functions

### Countdown Clock System Design
- **Current Approach**: Tab-based integration with the Quest screen and circular visualization
- **Considerations**:
  - Circular visualization provides clear representation of clock segments
  - Integration with Quest screen keeps related gameplay mechanics together
  - Type-based organization (Campaign, Tension, Trace) aligns with game mechanics
  - Batch operations for advancing clocks by type improves usability
- **Decision**: Implement as a tab in the Quest screen with circular visualization and type-based operations

### Clock Progress Tracking
- **Current Approach**: Segment-based visualization with manual advancement
- **Considerations**:
  - Segment counts (4, 6, 8, 10) align with game mechanics
  - Manual advancement provides control over pacing
  - Type-based batch operations allow for efficient gameplay
  - Visual feedback on progress is important for user engagement
- **Decision**: Use a segment-based visualization with both individual and batch advancement options

### Clock-Journal Integration
- **Current Approach**: Automatic journal entries for clock completion
- **Considerations**:
  - Automatic entries provide a record of significant events
  - Integration enhances the narrative experience
  - Balance between automation and manual control
- **Decision**: Create automatic journal entries when clocks are filled completely

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

1. **Code Quality Automation**: How can we automate the detection of deprecated functions?
2. **Helper Methods**: Should we create helper methods for common opacity-to-alpha conversions?
3. **Clock Complexity**: How can we balance clock complexity with usability?
4. **Clock Visualization**: What's the most intuitive way to visualize clock progress for different segment counts?
5. **Clock Dependencies**: Should we implement dependencies between clocks?
6. **Clock Triggers**: How should clock completion triggers be handled?
7. **Clock Types**: Should we add more clock types beyond Campaign, Tension, and Trace?
8. **Quest Complexity**: How can we balance quest complexity with usability?
9. **Progress Visualization**: What's the most intuitive way to visualize quest progress?
10. **Quest Dependencies**: Should we implement quest dependencies and prerequisites?
11. **Quest Rewards**: How should quest completion rewards be handled?
12. **Rich Text Persistence**: What's the most efficient way to store and retrieve rich text content?
13. **Autocompletion UX**: How can we make the autocompletion experience more intuitive without being intrusive?
14. **Image Handling**: What's the best approach for handling and storing embedded images?
15. **Performance Limits**: How can we ensure good performance with large journal entries and many references?
16. **Mobile Experience**: How can we optimize the rich text editor for smaller touch screens?
17. **Graph Layout Algorithms**: What additional layout algorithms would be beneficial for the location graph?
18. **Graph Performance**: How can we optimize the location graph for large numbers of nodes and edges?
19. **Graph Interaction**: How can we improve the user interaction with the location graph?
20. **Graph Visualization**: What additional visual elements would enhance the location graph?
21. **Graph Node Positioning**: What's the best approach for positioning nodes when auto-arrange is disabled?
22. **Graph Edge Styling**: How can we make edges more visually informative about the connection type?
23. **Graph Segment Visualization**: How can we better visualize the different segments in the graph?
24. **Graph Persistence**: What's the most efficient way to store and retrieve graph layouts?
25. **Graph Minimap**: Would a minimap be beneficial for navigating large graphs?

## Current Challenges

1. **Deprecated Function Detection**: Ensuring all deprecated functions are identified and fixed
2. **Code Quality Maintenance**: Keeping code quality high as the codebase grows
3. **Clock Management Complexity**: Balancing feature richness with simplicity and usability
4. **Clock Progress Visualization**: Ensuring clock visualization is intuitive and clear for different segment counts
5. **Clock Type Differentiation**: Making clock types visually distinct and meaningful
6. **Quest Management Complexity**: Balancing feature richness with simplicity and usability
7. **Progress Tracking**: Ensuring progress tracking is intuitive and aligns with game mechanics
8. **Status Transitions**: Making quest status changes clear and intuitive
9. **Text Editor Complexity**: Balancing feature richness with simplicity and usability
10. **Reference Management**: Ensuring references remain valid even when characters or locations are renamed
11. **Performance**: Maintaining smooth performance with complex journal entries and many references
12. **Intuitive Interaction**: Making the editor interaction intuitive for users of all experience levels
13. **Cross-platform Consistency**: Ensuring consistent behavior across different platforms and screen sizes
14. **Graph Rendering Performance**: Optimizing the location graph rendering for large graphs
15. **Graph Layout Quality**: Ensuring the graph layout is visually appealing and functional
16. **Graph Interaction Usability**: Making the graph interaction intuitive and responsive
17. **Component Coordination**: Ensuring proper coordination between the specialized components
18. **Node Position Management**: Ensuring node positions are properly saved and restored
19. **Auto-arrange Algorithm**: Balancing automatic layout with user control
20. **Edge Rendering Efficiency**: Optimizing edge rendering for large graphs
21. **Segment-based Visualization**: Making segment-based organization clear and intuitive
22. **Graph Scaling**: Ensuring proper scaling and zooming behavior
23. **Graph Navigation**: Making navigation in large graphs intuitive and efficient
24. **Graph Search**: Implementing efficient search functionality for large graphs
25. **Graph Persistence**: Ensuring graph layouts are properly persisted across sessions
