# Active Context: DartRPG

## Current Work Focus

The current development focus is on improving the journal entry screen and character handling in the Fe-Runners game. This includes:

1. Enhancing the journal entry screen with rich text editing capabilities
2. Adding character handle/short name support for easier referencing
3. Implementing autocompletion for character and location references
4. Creating a linked items summary for journal entries
5. Improving navigation flow based on character creation status

This work enhances the journaling system to provide a more intuitive and feature-rich experience for players, making it easier to document their game progress and reference characters and locations.

## Recent Changes

### Journal Entry Screen Enhancements
- Implemented a rich text editor with markdown-style formatting
- Added toolbar with formatting options (bold, italic, headings, lists)
- Created character and location reference system with @ and # syntax
- Implemented autocompletion for character and location references
- Added image embedding support
- Implemented keyboard shortcuts for common actions (Ctrl+M for Move, Ctrl+O for Oracle)

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
- Added visual feedback for autocompletion suggestions
- Improved error handling and validation in forms
- Enhanced the overall journal writing experience with modern text editor features

## Next Steps

### Short-term Tasks
1. **Testing Journal Entry Features**
   - Test character and location autocompletion
   - Verify tab-completion functionality
   - Check image embedding and display
   - Test keyboard shortcuts for moves and oracles

2. **UI Refinements**
   - Improve the visual design of the rich text editor
   - Enhance the linked items summary with better organization
   - Add animations for smoother transitions
   - Optimize mobile experience for the journal entry screen

3. **Performance Optimization**
   - Optimize autocompletion for large character/location lists
   - Improve rendering of complex journal entries
   - Enhance image handling and caching
   - Optimize saving and loading of rich text content

### Medium-term Goals
1. **Enhanced Journal Features**
   - Add support for more advanced formatting options
   - Implement full-text search across journal entries
   - Add tagging system for better organization
   - Support for templates and presets for common entry types

2. **Gameplay Integration**
   - Link journal entries to game mechanics and progress
   - Add automatic journaling for key game events
   - Implement timeline view for chronological entry browsing
   - Create relationship mapping between characters and locations

3. **Export/Import Functionality**
   - Add ability to export journal entries as markdown or PDF
   - Support for sharing journal content between players
   - Implement backup and restore functionality
   - Add printing support for physical copies

## Active Decisions and Considerations

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

1. **Rich Text Persistence**: What's the most efficient way to store and retrieve rich text content?
2. **Autocompletion UX**: How can we make the autocompletion experience more intuitive without being intrusive?
3. **Image Handling**: What's the best approach for handling and storing embedded images?
4. **Performance Limits**: How can we ensure good performance with large journal entries and many references?
5. **Mobile Experience**: How can we optimize the rich text editor for smaller touch screens?

## Current Challenges

1. **Text Editor Complexity**: Balancing feature richness with simplicity and usability
2. **Reference Management**: Ensuring references remain valid even when characters or locations are renamed
3. **Performance**: Maintaining smooth performance with complex journal entries and many references
4. **Intuitive Interaction**: Making the editor interaction intuitive for users of all experience levels
5. **Cross-platform Consistency**: Ensuring consistent behavior across different platforms and screen sizes
