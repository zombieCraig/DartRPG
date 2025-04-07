# Location Graph System

This directory contains the modularized components of the location graph system. The system has been refactored to follow the component extraction pattern, which improves maintainability, testability, and makes future enhancements easier to implement.

## Architecture

The location graph system is composed of the following specialized components:

```
LocationGraphWidget
    ├── LocationGraphController
    ├── LocationNodeRenderer
    ├── LocationEdgeRenderer
    └── LocationInteractionHandler
```

### Components

1. **LocationGraphWidget**: The main widget that orchestrates the other components and renders the graph.
   - Manages the overall UI structure
   - Coordinates between specialized components
   - Handles animations and visual effects

2. **LocationGraphController**: Manages the state and logic for the graph.
   - Builds the graph from a list of locations
   - Manages node positions and connections
   - Handles auto-arrange functionality
   - Provides methods for zooming, panning, and focusing

3. **LocationNodeRenderer**: Handles the rendering of location nodes.
   - Creates node widgets with appropriate styling
   - Formats node text for display
   - Handles highlighting and focus effects

4. **LocationEdgeRenderer**: Handles the rendering of edges between nodes.
   - Creates edge painters with appropriate styling
   - Determines edge colors based on location segments
   - Manages edge visual effects

5. **LocationInteractionHandler**: Handles user interactions with the graph.
   - Processes zoom, pan, and drag events
   - Manages node selection and movement
   - Coordinates with the controller to update the graph state

### Supporting Components

- **LocationEdgePainter**: A custom painter for drawing edges between nodes.
  - Draws edges with appropriate colors and styles
  - Handles edge visual effects like gradients and shadows

## Usage

To use the location graph system, import the index file:

```dart
import '../widgets/locations/graph/index.dart';
```

Then create a `LocationGraphWidget` with the required parameters:

```dart
LocationGraphWidget(
  locations: locations,
  onLocationTap: handleLocationTap,
  onLocationMoved: handleLocationMoved,
  onScaleChanged: handleScaleChanged,
  searchQuery: searchQuery,
  focusLocationId: focusLocationId,
  game: game,
)
```

## Benefits of Modularization

1. **Improved Maintainability**: Each component has a clear, focused responsibility.
2. **Better Testability**: Components can be tested in isolation.
3. **Reduced Risk of Data Loss**: Changes to one component are less likely to affect others.
4. **Enhanced User Experience**: More consistent UI and behavior.
5. **Easier Future Enhancements**: New features can be added to specific components.
6. **Improved Performance**: Potential for better optimization of each component.

## Future Enhancements

Potential future enhancements to the location graph system:

1. **Performance Optimization**: Improve rendering performance for large graphs.
2. **Layout Algorithms**: Add more layout algorithms for different graph visualization styles.
3. **Edge Styling**: Add more edge styling options for different connection types.
4. **Node Grouping**: Add support for grouping nodes by segment or other criteria.
5. **Minimap**: Add a minimap for navigating large graphs.
6. **Export/Import**: Add support for exporting and importing graph layouts.
