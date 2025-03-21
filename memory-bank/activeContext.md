# Active Context: DartRPG

## Current Work Focus

The current development focus is on implementing a network graph visualization for locations in the Fe-Runners game. This includes:

1. Creating a graph-based visualization for locations (nodes)
2. Implementing connections between locations with visual representation
3. Organizing locations into four segments (Core, CorpNet, GovNet, DarkNet) with distinct colors
4. Adding connection management functionality (creating, editing, removing connections)
5. Supporting position persistence and auto-layout for the graph

This work enhances the location management system to better represent the network-based structure of the Fe-Runners hacking-themed game, providing a more intuitive and visually appealing way for players to navigate and understand the game world.

## Recent Changes

### Location Model Enhancements
- Updated the `Location` model to include segment information (Core, CorpNet, GovNet, DarkNet)
- Added connection management with bidirectional links between locations
- Implemented position persistence for graph layout
- Added color coding for different segments

### Graph Visualization
- Created a new `LocationGraphWidget` for visualizing the location network
- Implemented interactive features (dragging, zooming, tapping)
- Added gradient lines between nodes in different segments
- Implemented auto-layout functionality for decluttering the graph

### Connection Management
- Added methods to `Game` and `GameProvider` for managing connections between locations
- Implemented segment adjacency rules to enforce the progression (Core→CorpNet→GovNet→DarkNet)
- Added validation to prevent invalid connections between non-adjacent segments
- Created UI for adding, viewing, and removing connections

### Location Screen Improvements
- Updated `LocationScreen` to support both list and graph views
- Added toggle buttons to switch between views
- Enhanced location creation dialog with segment selection
- Improved location details dialog with connection management
- Added support for creating connected locations

### User Experience Enhancements
- Added color coding for segments in both list and graph views
- Implemented visual feedback for connections and segments
- Added context-sensitive segment selection based on adjacency rules
- Improved navigation between connected locations

## Next Steps

### Short-term Tasks
1. **Testing the Location Graph**
   - Test connection creation and removal
   - Verify segment validation rules
   - Check position persistence across app restarts
   - Test auto-layout functionality

2. **UI Refinements**
   - Improve the visual design of the graph
   - Optimize layout algorithm for better node distribution
   - Add animations for smoother transitions
   - Enhance node appearance with more information

3. **Performance Optimization**
   - Optimize graph rendering for large networks
   - Implement efficient position calculation
   - Add pagination or virtualization for large location lists

### Medium-term Goals
1. **Enhanced Graph Features**
   - Add minimap for navigation in large graphs
   - Implement node grouping by segment
   - Add search functionality for finding locations in the graph
   - Support for filtering nodes by segment or other criteria

2. **Gameplay Integration**
   - Link location graph to game mechanics
   - Add status indicators for locations (e.g., explored, locked)
   - Implement progression tracking through the network
   - Add special node types for key locations

3. **Export/Import Functionality**
   - Add ability to export the location graph as an image
   - Support for sharing location networks between players
   - Implement templates for common network structures

## Active Decisions and Considerations

### Graph Visualization Approach
- **Current Approach**: Custom implementation using the `graphview` package
- **Considerations**:
  - Custom implementation provides more control over appearance and behavior
  - Using a package reduces development time but may limit customization
  - Need to balance visual appeal with performance
- **Decision**: Use the `graphview` package as a foundation with custom rendering for connections

### Segment Progression Rules
- **Current Approach**: Enforce adjacency rules between segments
- **Considerations**:
  - Strict rules ensure logical progression through the network
  - Rules should be clear to users to avoid confusion
  - Need to balance restrictions with player freedom
- **Decision**: Enforce adjacency rules (Core↔CorpNet↔GovNet↔DarkNet) with clear UI feedback

### Position Persistence Strategy
- **Current Approach**: Store x/y coordinates in the Location model
- **Considerations**:
  - Persistent positions provide a consistent experience across sessions
  - Manual positioning gives users control over the graph layout
  - Auto-layout provides a good starting point but may disrupt user arrangements
- **Decision**: Support both manual positioning and auto-layout with user control

### Connection Management UI
- **Current Approach**: Primary management through node detail dialog with optional context menu
- **Considerations**:
  - Dialog-based approach provides clear structure and validation
  - Direct graph interaction would be more intuitive but more complex to implement
  - Need to balance ease of use with functionality
- **Decision**: Use dialog-based approach with potential for direct interaction in future updates

## Open Questions

1. **Graph Scaling**: How should the graph scale for very large networks with many nodes?
2. **Visual Differentiation**: What additional visual cues could help distinguish different types of nodes?
3. **Performance Limits**: What is the practical limit for the number of nodes before performance issues arise?
4. **User Guidance**: How can we guide users to create well-organized graphs?
5. **Mobile Experience**: How can we optimize the graph interaction for smaller touch screens?

## Current Challenges

1. **Layout Algorithm**: Finding the right balance between automatic and manual layout
2. **Visual Clarity**: Ensuring the graph remains clear and understandable as it grows
3. **Performance**: Maintaining smooth performance with large graphs
4. **Intuitive Interaction**: Making the graph interaction intuitive for users
5. **Cross-platform Consistency**: Ensuring consistent behavior across different platforms
