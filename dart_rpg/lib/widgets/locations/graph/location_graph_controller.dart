import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../../models/location.dart';
import '../../../models/game.dart';
import 'dart:math' as math;
import 'force_directed_layout_controller.dart';

/// A controller for managing the location graph state and logic
class LocationGraphController {
  /// The graph instance
  final Graph graph = Graph()..isTree = false;
  
  /// Map of location IDs to graph nodes
  final Map<String, Node> nodeMap = {};
  
  /// Map of nodes to their positions
  final Map<Node, Offset> nodePositions = {};
  
  /// Map of location IDs to their positions
  final Map<String, Offset> nodePositionsByLocationId = {};
  
  /// The algorithm used for layout
  late Algorithm algorithm;
  
  /// Whether auto-arrange is enabled
  bool autoArrangeEnabled = false;
  
  /// The current scale of the graph
  double scale = 1.0;
  
  /// Map to store positions that need to be saved after drag
  final Map<String, Offset> _pendingSavePositions = {};
  
  /// The transformation controller for the interactive viewer
  final TransformationController transformationController = TransformationController();
  
  /// The game instance
  Game? game;
  
  /// Callback when a location is tapped
  final Function(String locationId)? onLocationTap;
  
  /// Callback when a location is long-pressed for editing
  final Function(String locationId)? onLocationEdit;
  
  /// Callback when a location is moved
  final Function(String locationId, double x, double y)? onLocationMoved;
  
  /// Callback when the scale is changed
  final Function(double scale)? onScaleChanged;
  
  /// The force-directed layout controller
  ForceDirectedLayoutController? _forceDirectedLayoutController;
  
  /// The ticker provider for animations
  final TickerProvider _tickerProvider;
  
  /// Flag to disable saving during animation
  bool _savingDisabled = false;
  
  /// Creates a new LocationGraphController
  LocationGraphController({
    this.onLocationTap,
    this.onLocationEdit,
    this.onLocationMoved,
    this.onScaleChanged,
    this.game,
    required TickerProvider tickerProvider,
  }) : _tickerProvider = tickerProvider {
    // Initialize with FruchtermanReingoldAlgorithm
    algorithm = FruchtermanReingoldAlgorithm(iterations: 100);
  }
  
  /// Builds the graph from a list of locations
  void buildGraph(List<Location> locations) {
    graph.edges.clear();
    graph.nodes.clear();
    nodeMap.clear();
    nodePositions.clear();
    nodePositionsByLocationId.clear();
    
    // Create nodes for each location
    for (final location in locations) {
      final node = Node.Id(location.id);
      nodeMap[location.id] = node;
      graph.addNode(node);
      
      // Always try to use saved positions first, regardless of auto-arrange setting
      if (location.x != null && location.y != null) {
        final position = Offset(location.x!, location.y!);
        nodePositions[node] = position;
        nodePositionsByLocationId[location.id] = position;
      } else {
        // Generate a random position if no saved position is available
        final position = _generateRandomPosition();
        nodePositions[node] = position;
        nodePositionsByLocationId[location.id] = position;
      }
    }
    
    // Create edges for connections
    for (final location in locations) {
      final sourceNode = nodeMap[location.id];
      if (sourceNode == null) continue;
      
      for (final targetId in location.connectedLocationIds) {
        final targetNode = nodeMap[targetId];
        if (targetNode == null) continue;
        
        // Only add edge if it doesn't already exist
        bool edgeExists = false;
        for (final edge in graph.edges) {
          if ((edge.source == sourceNode && edge.destination == targetNode) ||
              (edge.source == targetNode && edge.destination == sourceNode)) {
            edgeExists = true;
            break;
          }
        }
        
        if (!edgeExists) {
          // Get the segments of the source and target locations
          final sourceSegment = location.segment;
          final targetLocation = locations.firstWhere(
            (loc) => loc.id == targetId,
            orElse: () => location,
          );
          final targetSegment = targetLocation.segment;
          
          // Create a custom Paint object based on the segments
          final edgePaint = Paint()
            ..color = _getEdgeColor(sourceSegment, targetSegment)
            ..strokeWidth = 2.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          
          // Add the edge with the custom Paint
          graph.addEdge(sourceNode, targetNode, paint: edgePaint);
        }
      }
    }
    
    // Update algorithm iterations based on auto-arrange setting
    algorithm = FruchtermanReingoldAlgorithm(
      iterations: autoArrangeEnabled ? 1000 : 100
    );
    
    // Initialize force-directed layout controller if auto-arrange is enabled
    if (autoArrangeEnabled) {
      _initializeForceDirectedLayout(locations);
    } else {
      // If auto-arrange is disabled, position nodes in a more structured way
      _arrangeNodesInCircle(locations);
    }
  }
  
  /// Initializes the force-directed layout controller
  void _initializeForceDirectedLayout(List<Location> locations) {
    // Create the controller if it doesn't exist
    _forceDirectedLayoutController ??= ForceDirectedLayoutController(
      vsync: _tickerProvider,
      repulsionStrength: 20000.0, // Doubled repulsion for more separation
      attractionStrength: 0.2, // Reduced attraction for less clustering
      damping: 0.9, // Increased damping for smoother movement
      maxVelocity: 100.0, // Increased max velocity for more dynamic movement
      minEnergyThreshold: 1.0, // Increased threshold to allow settling
      minNodeDistance: 250.0, // Increased minimum distance between nodes
      maxSimulationTime: 10.0, // Maximum simulation time in seconds
      onSimulationStateChanged: _handleSimulationStateChanged,
    );
    
    // Initialize with current locations and positions
    _forceDirectedLayoutController!.initialize(locations, nodePositionsByLocationId);
    
    // Start the simulation
    _forceDirectedLayoutController!.startSimulation();
  }
  
  /// Generates a random position for a node
  Offset _generateRandomPosition() {
    // Generate a random position within the fixed-size background
    // The background is 2000x2000 with (0,0) at the center, so valid range is ±1000
    final random = math.Random();
    
    // Use a larger range for initial positions to spread nodes out more
    // This helps prevent overlapping nodes
    final radius = 800.0; // Increased radius for better initial spacing
    
    // Use a minimum distance from center to avoid clustering in the middle
    final minDistance = 200.0;
    
    // Generate a random angle
    final angle = random.nextDouble() * 2 * math.pi;
    
    // Generate a random distance from the center, but ensure it's at least minDistance
    final distance = minDistance + random.nextDouble() * (radius - minDistance);
    
    // Convert polar coordinates to Cartesian coordinates
    final x = distance * math.cos(angle);
    final y = distance * math.sin(angle);
    
    return Offset(x, y);
  }
  
  /// Toggles auto-arrange mode
  void toggleAutoArrange() {
    autoArrangeEnabled = !autoArrangeEnabled;
    
    if (autoArrangeEnabled) {
      // When enabling auto-arrange, use force-directed layout
      
      // Get locations from the game if available
      List<Location> locations = [];
      if (game != null && game!.locations.isNotEmpty) {
        // Use the actual locations from the game
        locations = game!.locations;
      } else {
        // If game is not available or has no locations, create dummy locations
        // This is a fallback for testing or when the game is not properly initialized
        for (final entry in nodeMap.entries) {
          final locationId = entry.key;
          final segment = LocationSegment.core; // Default to core segment
          final location = Location(
            id: locationId,
            name: 'Location $locationId',
            segment: segment,
          );
          locations.add(location);
        }
      }
      
      // Save current positions before starting force-directed layout
      // This ensures that if the simulation is stopped, we have the current positions saved
      for (final entry in nodePositionsByLocationId.entries) {
        _pendingSavePositions[entry.key] = entry.value;
      }
      
      // Initialize and start force-directed layout
      _initializeForceDirectedLayout(locations);
      
      // Use more iterations for better layout
      algorithm = FruchtermanReingoldAlgorithm(iterations: 1000);
    } else {
      // When disabling auto-arrange, stop the force-directed layout
      if (_forceDirectedLayoutController != null) {
        _forceDirectedLayoutController!.stopSimulation();
      }
      
      // Use fewer iterations to avoid major changes
      algorithm = FruchtermanReingoldAlgorithm(iterations: 100);
    }
  }
  
  /// Resets the zoom level
  void resetZoom() {
    scale = 1.0;
    transformationController.value = Matrix4.identity();
    if (onScaleChanged != null) {
      onScaleChanged!(scale);
    }
  }
  
  /// Fits the graph to the screen
  void fitToScreen(BuildContext context, Size size, List<Location> locations) {
    // Early return if size is invalid
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    // Early return if no locations
    if (locations.isEmpty) {
      return;
    }
    
    // Only arrange nodes that don't have saved positions
    // This preserves the positions of nodes that have been manually positioned
    _arrangeNodesInCircle(locations, preserveSavedPositions: true);
    
    // Calculate the bounds of all nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    
    // Use the actual node positions to calculate the bounds
    int validPositions = 0;
    for (final location in locations) {
      final position = nodePositionsByLocationId[location.id];
      if (position != null) {
        minX = math.min(minX, position.dx);
        minY = math.min(minY, position.dy);
        maxX = math.max(maxX, position.dx);
        maxY = math.max(maxY, position.dy);
        validPositions++;
      }
    }
    
    // If no valid positions were found, use default values
    if (validPositions == 0) {
      minX = -500;
      minY = -500;
      maxX = 500;
      maxY = 500;
    }
    
    // Add some padding
    final paddingX = (maxX - minX) * 0.2; // 20% padding
    final paddingY = (maxY - minY) * 0.2; // 20% padding
    
    minX -= paddingX;
    minY -= paddingY;
    maxX += paddingX;
    maxY += paddingY;
    
    // Calculate the scale needed to fit the graph in the container
    final graphWidth = maxX - minX;
    final graphHeight = maxY - minY;
    
    if (graphWidth > 0 && graphHeight > 0) {
      final scaleX = size.width / graphWidth;
      final scaleY = size.height / graphHeight;
      
      // Ensure we have a valid scaleY (handle case where height is very small)
      final effectiveScaleY = graphHeight < 1.0 ? scaleX : scaleY;
      
      scale = math.min(scaleX, effectiveScaleY) * 0.9; // 90% to add some padding
      
      // Calculate the center of the graph
      final centerX = (minX + maxX) / 2;
      final centerY = (minY + maxY) / 2;
      
      // Convert to the adjusted coordinate system (adding halfSize)
      const double halfSize = 1000.0; // Half of the background size
      final adjustedCenterX = centerX + halfSize;
      final adjustedCenterY = centerY + halfSize;
      
      // Calculate the translation needed to center the graph
      final tx = size.width / 2 - adjustedCenterX * scale;
      final ty = size.height / 2 - adjustedCenterY * scale;
      
      // Create a matrix with translation and scale
      final matrix = Matrix4.identity();
      matrix.setEntry(0, 3, tx); // Translation X
      matrix.setEntry(1, 3, ty); // Translation Y
      matrix.setEntry(0, 0, scale); // Scale X
      matrix.setEntry(1, 1, scale); // Scale Y
      matrix.setEntry(2, 2, 1.0); // Scale Z
      
      // Apply the transformation in a post-frame callback to ensure it happens after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        transformationController.value = matrix;
        
        if (onScaleChanged != null) {
          onScaleChanged!(scale);
        }
      });
    }
  }
  
  /// Focuses on a specific location
  void focusOnLocation(String locationId, BuildContext context, Size size) {
    // Early return if size is invalid
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    
    final node = nodeMap[locationId];
    if (node == null) {
      return;
    }
    
    // Get the node position immediately to avoid timing issues
    final position = _getNodePosition(node);
    if (position == null) {
      return;
    }
    
    // For the fixed-size background (2000x2000), we need to adjust the position
    // The background is centered at (0,0), so we need to add 1000 to each coordinate
    // to get the position relative to the top-left corner of the background
    const double halfSize = 1000.0;
    
    // Create a transformation matrix that centers on the node
    // We need to account for the fixed-size background and the node's position within it
    final matrix = Matrix4.identity()
      ..translate(
        size.width / 2 - (position.dx + halfSize) * scale, 
        size.height / 2 - (position.dy + halfSize) * scale
      )
      ..scale(scale, scale);
    
    // Apply the transformation in a post-frame callback to ensure it happens after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transformationController.value = matrix;
    });
  }
  
  /// Updates the position of a node
  void updateNodePosition(String locationId, double x, double y) {
    // If auto-arrange is enabled and force-directed layout is active,
    // apply a force instead of directly updating the position
    if (autoArrangeEnabled && _forceDirectedLayoutController != null && _forceDirectedLayoutController!.isSimulating) {
      // Calculate force based on the drag delta
      final force = Offset(x, y) * 50.0; // Increased scale for more dramatic effect
      
      // Apply force to the node
      _forceDirectedLayoutController!.applyRepulsiveForce(locationId, force);
      
      // Update positions from force-directed layout
      final positions = _forceDirectedLayoutController!.getNodePositions();
      for (final entry in positions.entries) {
        final node = nodeMap[entry.key];
        if (node != null) {
          nodePositions[node] = entry.value;
          nodePositionsByLocationId[entry.key] = entry.value;
        }
      }
    } else {
      // Traditional direct position update
      final node = nodeMap[locationId];
      if (node == null) return;
      
      final position = _getNodePosition(node);
      if (position == null) return;
      
      // Update the position
      final newX = position.dx + x / scale;
      final newY = position.dy + y / scale;
      
      // Enforce boundaries to keep nodes within the fixed-size background
      // The background is 2000x2000 with (0,0) at the center, so valid range is ±1000
      final boundedX = math.max(-950.0, math.min(950.0, newX));
      final boundedY = math.max(-950.0, math.min(950.0, newY));
      
      // Store the new position
      nodePositions[node] = Offset(boundedX, boundedY);
      nodePositionsByLocationId[locationId] = Offset(boundedX, boundedY);
      
      // Notify the callback
      if (onLocationMoved != null) {
        onLocationMoved!(locationId, boundedX, boundedY);
      }
    }
  }
  
  /// Updates the scale of the graph
  void updateScale(double newScale) {
    // Allow a wider range of zoom levels (0.1 to 3.0)
    // This helps users see nodes that are far apart (zoom out)
    // or examine details of specific areas (zoom in)
    scale = math.max(0.1, math.min(3.0, newScale));
    
    final matrix = transformationController.value.clone()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale);
    transformationController.value = matrix;
    
    if (onScaleChanged != null) {
      onScaleChanged!(scale);
    }
  }
  
  /// Gets the position of a node
  Offset? _getNodePosition(Node node) {
    try {
      // Simply return the position from the nodePositions map
      // This map is populated in the buildGraph method
      final position = nodePositions[node];
      
      // If we don't have a position for this node, generate a random one
      if (position == null) {
        final newPosition = _generateRandomPosition();
        nodePositions[node] = newPosition;
        
        // Also store by location ID for the edge painter
        final locationId = node.key!.value as String;
        nodePositionsByLocationId[locationId] = newPosition;
        
        return newPosition;
      }
      
      return position;
    } catch (e) {
      return null;
    }
  }
  
  /// Determines the color for an edge based on the segments of the connected locations.
  Color _getEdgeColor(LocationSegment sourceSegment, LocationSegment targetSegment) {
    // If both locations are in the same segment, use that segment's color
    if (sourceSegment == targetSegment) {
      return _getSegmentEdgeColor(sourceSegment);
    }
    
    // If they're in different segments, blend the colors
    final sourceColor = _getSegmentEdgeColor(sourceSegment);
    final targetColor = _getSegmentEdgeColor(targetSegment);
    
    // Create a blend of the two colors
    return Color.lerp(sourceColor, targetColor, 0.5)!;
  }
  
  /// Gets a color for a segment that's suitable for edges (may be different from node colors).
  Color _getSegmentEdgeColor(LocationSegment segment) {
    switch (segment) {
      case LocationSegment.core:
        return Colors.green.shade400.withAlpha(204); // 0.8 * 255 = 204
      case LocationSegment.corpNet:
        return Colors.yellow.shade600.withAlpha(204); // 0.8 * 255 = 204
      case LocationSegment.govNet:
        return Colors.blue.shade300.withAlpha(204); // 0.8 * 255 = 204, Using blue instead of grey for better visibility
      case LocationSegment.darkNet:
        return Colors.purple.shade300.withAlpha(204); // 0.8 * 255 = 204, Using purple instead of black for better visibility
    }
  }
  
  /// Checks if a location is the rig location
  bool isRigLocation(String locationId) {
    if (game?.rigLocation == null) return false;
    return game!.rigLocation!.id == locationId;
  }
  
  /// Arranges nodes in a circle
  void _arrangeNodesInCircle(List<Location> locations, {bool preserveSavedPositions = false}) {
    if (locations.isEmpty) return;
    
    // If preserveSavedPositions is true, filter out locations that already have saved positions
    List<Location> locationsToArrange;
    if (preserveSavedPositions) {
      locationsToArrange = locations.where((location) => location.x == null || location.y == null).toList();
      if (locationsToArrange.isEmpty) {
        return; // No need to arrange any nodes
      }
    } else {
      locationsToArrange = List.from(locations);
    }
    
    // Group locations by segment
    final Map<LocationSegment, List<Location>> locationsBySegment = {};
    for (final location in locationsToArrange) {
      if (!locationsBySegment.containsKey(location.segment)) {
        locationsBySegment[location.segment] = [];
      }
      locationsBySegment[location.segment]!.add(location);
    }
    
    // Calculate the radius based on the number of locations
    // Ensure the radius is not too large for the fixed-size background (2000x2000)
    // The maximum safe radius is around 800 to keep nodes within the background
    final calculatedRadius = math.min(800.0, math.max(300.0, locations.length * 30.0));
    
    // Position each segment's locations in a circle
    double segmentStartAngle = 0.0;
    final segmentCount = locationsBySegment.length;
    
    // Add some spacing between segments
    const double segmentSpacing = 0.2; // radians
    
    locationsBySegment.forEach((segment, segmentLocations) {
      // Calculate the angle for this segment, leaving some space between segments
      final segmentAngle = (2 * math.pi - segmentSpacing * segmentCount) / segmentCount;
      
      // Calculate the angle for each location, ensuring minimum spacing
      final minLocationSpacing = 0.3; // minimum radians between locations
      final calculatedLocationAngle = segmentAngle / math.max(1, segmentLocations.length);
      final locationAngle = math.max(calculatedLocationAngle, minLocationSpacing);
      
      for (int i = 0; i < segmentLocations.length; i++) {
        final location = segmentLocations[i];
        final node = nodeMap[location.id];
        if (node == null) continue;
        
        // Calculate position on the circle
        // Use a spiral layout if there are too many nodes to fit in the segment
        double angle;
        double radius;
        
        if (locationAngle * segmentLocations.length > segmentAngle) {
          // Use a spiral layout for this segment
          angle = segmentStartAngle + (i * segmentAngle / segmentLocations.length);
          // Increase radius slightly for each node to create a spiral effect
          radius = calculatedRadius * (0.7 + 0.3 * i / segmentLocations.length);
        } else {
          // Use a regular circle layout
          angle = segmentStartAngle + i * locationAngle;
          radius = calculatedRadius;
        }
        
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);
        
        // Ensure the position is within the bounds of the fixed-size background
        final boundedX = math.max(-950.0, math.min(950.0, x));
        final boundedY = math.max(-950.0, math.min(950.0, y));
        
        // Store the position
        final position = Offset(boundedX, boundedY);
        nodePositions[node] = position;
        nodePositionsByLocationId[location.id] = position;
        
        // Update the location's position in the model
        if (onLocationMoved != null) {
          onLocationMoved!(location.id, boundedX, boundedY);
        }
      }
      
      segmentStartAngle += segmentAngle;
    });
  }
  
  /// Flag to track if a drag operation is in progress
  bool _isDragging = false;

  /// Set whether a drag operation is in progress
  void setDragInProgress(bool inProgress) {
    _isDragging = inProgress;
  }
  
  /// Check if a drag operation is in progress
  bool get isDragging => _isDragging;
  
  /// Updates the position of a node without saving to the game state
  void updateNodePositionWithoutSaving(String locationId, double x, double y) {
    final node = nodeMap[locationId];
    if (node == null) return;
    
    final position = _getNodePosition(node);
    if (position == null) return;
    
    // Update the position
    final newX = position.dx + x / scale;
    final newY = position.dy + y / scale;
    
    // Enforce boundaries to keep nodes within the fixed-size background
    final boundedX = math.max(-950.0, math.min(950.0, newX));
    final boundedY = math.max(-950.0, math.min(950.0, newY));
    
    // Store the new position locally
    nodePositions[node] = Offset(boundedX, boundedY);
    nodePositionsByLocationId[locationId] = Offset(boundedX, boundedY);
    
    // Store in pending save positions
    _pendingSavePositions[locationId] = Offset(boundedX, boundedY);
  }
  
  /// Save all pending position changes to the game state
  void saveCurrentPositions() {
    if (_pendingSavePositions.isEmpty) return;
    
    // First, directly update the Location objects in the game
    if (game != null) {
      for (final entry in _pendingSavePositions.entries) {
        final locationId = entry.key;
        final position = entry.value;
        
        try {
          // Find the location in the game
          final location = game!.locations.firstWhere(
            (loc) => loc.id == locationId,
          );
          
          // Update the location's position directly
          location.x = position.dx;
          location.y = position.dy;
        } catch (e) {
        }
      }
    }
    
    // Then notify callbacks for all pending positions
    for (final entry in _pendingSavePositions.entries) {
      final locationId = entry.key;
      final position = entry.value;
      
      if (onLocationMoved != null) {
        onLocationMoved!(locationId, position.dx, position.dy);
      }
    }
    
    // Clear pending positions
    _pendingSavePositions.clear();
  }
  
  /// Applies a repulsive force from a specific node
  void applyRepulsiveForce(String locationId, Offset force) {
    if (_forceDirectedLayoutController != null && _forceDirectedLayoutController!.isSimulating) {
      _forceDirectedLayoutController!.applyRepulsiveForce(locationId, force);
    }
  }
  
  /// Checks if the force-directed layout simulation is running
  bool get isSimulationRunning => 
      _forceDirectedLayoutController != null && _forceDirectedLayoutController!.isSimulating;
  
  /// Disables saving during animation
  void disableSaving() {
    _savingDisabled = true;
  }
  
  /// Enables saving and triggers a save of current positions
  void enableSaving() {
    _savingDisabled = false;
    
    // Create a copy of positions before saving to avoid race conditions
    Map<String, Offset> positionsToSave = Map.from(_pendingSavePositions);
    
    // Ensure all current positions are in the positions to save map
    if (_forceDirectedLayoutController != null) {
      final positions = _forceDirectedLayoutController!.getNodePositions();
      for (final entry in positions.entries) {
        positionsToSave[entry.key] = entry.value;
      }
    }
    
    // Save all current positions
    if (positionsToSave.isNotEmpty) {
      
      // Update _pendingSavePositions with our copy
      _pendingSavePositions.clear();
      _pendingSavePositions.addAll(positionsToSave);
      
      // Save positions
      saveCurrentPositions();
      
      // Force a game save to ensure positions are persisted to the database
      if (game != null && onLocationMoved != null && game!.locations.isNotEmpty) {
        // Find any location to use for triggering a save
        final location = game!.locations.first;
        // This will trigger the GameProvider to save the game to SharedPreferences
        onLocationMoved!(location.id, location.x ?? 0, location.y ?? 0);
      }
    }
  }
  
  /// Updates node positions from the force-directed layout
  void updatePositionsFromForceDirectedLayout() {
    if (_forceDirectedLayoutController == null || !_forceDirectedLayoutController!.isSimulating) return;
    
    // Get current positions from force-directed layout
    final positions = _forceDirectedLayoutController!.getNodePositions();
    
    // Update positions in the graph controller
    for (final entry in positions.entries) {
      final node = nodeMap[entry.key];
      if (node != null) {
        nodePositions[node] = entry.value;
        nodePositionsByLocationId[entry.key] = entry.value;
        
        // Store in pending save positions
        _pendingSavePositions[entry.key] = entry.value;
        
        // Also update the Location objects directly if game is available
        if (game != null && !_savingDisabled) {
          try {
            final location = game!.locations.firstWhere(
              (loc) => loc.id == entry.key,
            );
            
            // Update the location's position directly
            location.x = entry.value.dx;
            location.y = entry.value.dy;
          } catch (e) {
            // Ignore if location not found
          }
        }
      }
    }
    
    // Only save positions to the game if saving is not disabled
    if (!_savingDisabled && onLocationMoved != null) {
      // We'll save all positions at once when animation stops
      // This is handled by enableSaving()
    }
  }
  
  /// Handles simulation state changes from the force-directed layout controller
  void _handleSimulationStateChanged(bool isSimulating) {
    if (isSimulating) {
      // Disable saving when simulation starts
      disableSaving();
    } else {
      // Enable saving when simulation stops
      enableSaving();
    }
  }
  
  /// Disposes of resources
  void dispose() {
    transformationController.dispose();
    _forceDirectedLayoutController?.dispose();
  }
}

// Extension method for Algorithm to get node position
extension AlgorithmExtension on Algorithm {
  Offset? getNodePosition(Node node) {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }
}
