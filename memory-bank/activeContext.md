# Active Context: DartRPG

## Current Work Focus

The current development focus is on enhancing the game management features with quest tracking capabilities and continuing to improve the journal entry system. This includes:

1. Implementing a Quest viewer with tabs for Ongoing, Completed, and Forsaken quests
2. Adding quest creation and management functionality
3. Integrating quest progress tracking with a 10-segment progress bar
4. Implementing quest status changes (complete, forsake)
5. Adding keyboard shortcuts for quick navigation (CTRL+Q for Quests)
6. Enhancing the journal entry screen with rich text editing capabilities
7. Adding character handle/short name support for easier referencing
8. Implementing autocompletion for character and location references
9. Creating a linked items summary for journal entries
10. Improving navigation flow based on character creation status

This work enhances both the quest management system and the journaling system to provide a more intuitive and feature-rich experience for players, making it easier to track progress and document their game journey.

## Recent Changes

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

2. **UI Refinements**
   - Improve the visual design of the quest cards
   - Enhance the progress bar visualization
   - Add animations for status changes
   - Optimize mobile experience for the quest screen

3. **Performance Optimization**
   - Optimize quest list rendering for large numbers of quests
   - Improve progress tracking and roll calculations
   - Enhance quest filtering and sorting
   - Optimize saving and loading of quest data

4. **Testing Infrastructure**
   - Expand test coverage to other critical components
   - Set up continuous integration for automated testing
   - Create test fixtures for common test scenarios
   - Implement integration tests for key user flows

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
