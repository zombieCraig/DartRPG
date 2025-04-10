import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import '../../../models/location.dart';
import '../../../models/game.dart';
import 'location_graph_controller.dart';
import 'location_node_renderer.dart';
import 'location_edge_renderer.dart';
import 'location_interaction_handler.dart';
import '../../hacker_grid_painter.dart';

/// A widget for displaying a graph of locations
class LocationGraphWidget extends StatefulWidget {
  /// The list of locations to display
  final List<Location> locations;
  
  /// Callback when a location is tapped
  final Function(String locationId) onLocationTap;
  
  /// Callback when a location is long-pressed for editing
  final Function(String locationId) onLocationEdit;
  
  /// Callback when a location is moved
  final Function(String locationId, double x, double y) onLocationMoved;
  
  /// Callback when the scale is changed
  final Function(double scale) onScaleChanged;
  
  /// The search query to highlight matching locations
  final String? searchQuery;
  
  /// The ID of the location to focus on
  final String? focusLocationId;
  
  /// The game instance
  final Game? game;

  /// Creates a new LocationGraphWidget
  const LocationGraphWidget({
    super.key,
    required this.locations,
    required this.onLocationTap,
    required this.onLocationEdit,
    required this.onLocationMoved,
    required this.onScaleChanged,
    this.searchQuery,
    this.focusLocationId,
    this.game,
  });

  @override
  LocationGraphWidgetState createState() => LocationGraphWidgetState();
}

class LocationGraphWidgetState extends State<LocationGraphWidget> with TickerProviderStateMixin {
  late LocationGraphController _controller;
  late LocationNodeRenderer _nodeRenderer;
  late LocationEdgeRenderer _edgeRenderer;
  late LocationInteractionHandler _interactionHandler;
  
  // For rig node pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // For hacker grid background
  late AnimationController _gridPulseController;
  late Animation<double> _gridPulseAnimation;
  late AnimationController _dataFlowController;
  late Animation<double> _dataFlowAnimation;
  
  // Default to true, but can be disabled for testing
  bool _showHackerGrid = true; // In a test environment, this would be set to false
  
  // Key for the graph container
  final GlobalKey _graphKey = GlobalKey();
  
  // Add a flag to track if it's the first time the widget is being built
  bool _isFirstBuild = true;
  
  // Timer for forcing UI updates during dragging
  Timer? _dragUpdateTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and renderers
    _controller = LocationGraphController(
      onLocationTap: widget.onLocationTap,
      onLocationEdit: widget.onLocationEdit,
      onLocationMoved: widget.onLocationMoved,
      onScaleChanged: widget.onScaleChanged,
      game: widget.game,
    );
    
    _nodeRenderer = const LocationNodeRenderer();
    _edgeRenderer = const LocationEdgeRenderer();
    _interactionHandler = LocationInteractionHandler(
      controller: _controller,
      onDragStart: _startDragUpdateTimer,
      onDragUpdate: _triggerDragUpdate,
      onDragEnd: _stopDragUpdateTimer,
    );
    
    // Build the graph
    _controller.buildGraph(widget.locations);
    
    // Setup animation for rig node
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // Setup animation for hacker grid background
    _gridPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _gridPulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gridPulseController, curve: Curves.easeInOut)
    );
    
    // Setup animation for data flow effect
    _dataFlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _dataFlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dataFlowController, curve: Curves.linear)
    );
    
    // Focus on location if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusLocationId != null && _graphKey.currentContext != null) {
        final size = _graphKey.currentContext!.size ?? Size.zero;
        _controller.focusOnLocation(widget.focusLocationId!, context, size);
      }
      // If no specific location to focus on, and it's the first build, fit to screen
      else if (_isFirstBuild && _graphKey.currentContext != null && widget.locations.isNotEmpty) {
        final size = _graphKey.currentContext!.size ?? Size.zero;
        _controller.fitToScreen(context, size, widget.locations);
        _isFirstBuild = false;
      }
    });
  }
  
  @override
  void didUpdateWidget(LocationGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update controller game reference
    _controller.game = widget.game;
    
    // Rebuild graph if locations list changes or connections change
    bool needsRebuild = oldWidget.locations.length != widget.locations.length;
    
    if (!needsRebuild) {
      // Check if the location IDs have changed
      final oldIds = oldWidget.locations.map((loc) => loc.id).toSet();
      final newIds = widget.locations.map((loc) => loc.id).toSet();
      
      if (!const SetEquality<String>().equals(oldIds, newIds)) {
        needsRebuild = true;
      } else {
        // More thorough check for connection changes
        // Create maps of location IDs to their connection sets for both old and new widgets
        final oldConnectionMap = <String, Set<String>>{};
        for (final loc in oldWidget.locations) {
          oldConnectionMap[loc.id] = loc.connectedLocationIds.toSet();
        }
        
        final newConnectionMap = <String, Set<String>>{};
        for (final loc in widget.locations) {
          newConnectionMap[loc.id] = loc.connectedLocationIds.toSet();
        }
        
        // Check if any location's connections have changed
        for (final locId in newIds) {
          final oldConnections = oldConnectionMap[locId] ?? <String>{};
          final newConnections = newConnectionMap[locId] ?? <String>{};
          
          if (!const SetEquality<String>().equals(oldConnections, newConnections)) {
            needsRebuild = true;
            break;
          }
        }
      }
    }
    
    if (needsRebuild) {
      _controller.buildGraph(widget.locations);
    }
    
    // Focus on location if it changed - using post-frame callback to avoid size access during build
    if (widget.focusLocationId != null && 
        widget.focusLocationId != oldWidget.focusLocationId) {
      // Schedule the focus operation after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_graphKey.currentContext != null) {
          final size = _graphKey.currentContext!.size ?? Size.zero;
          _controller.focusOnLocation(widget.focusLocationId!, context, size);
        }
      });
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _gridPulseController.dispose();
    _dataFlowController.dispose();
    _controller.dispose();
    _stopDragUpdateTimer();
    super.dispose();
  }
  
  /// Starts a timer to force UI updates during dragging
  void _startDragUpdateTimer() {
    // Cancel any existing timer
    _stopDragUpdateTimer();
    
    // Start a new timer that triggers a rebuild every 16ms (approximately 60fps)
    _dragUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) {
        setState(() {
          // Just trigger a rebuild to update the UI
        });
      }
    });
  }
  
  /// Triggers a UI update during dragging
  void _triggerDragUpdate() {
    // This method is called on every drag update
    // We don't need to do anything here since the timer is already forcing updates
    // But we could add additional logic if needed
  }
  
  /// Stops the drag update timer
  void _stopDragUpdateTimer() {
    _dragUpdateTimer?.cancel();
    _dragUpdateTimer = null;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          key: _graphKey,
          child: _buildGraphView(),
        ),
      ],
    );
  }
  
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _interactionHandler.zoomIn,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _interactionHandler.zoomOut,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _interactionHandler.resetZoom,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: () {
              if (_graphKey.currentContext != null) {
                final size = _graphKey.currentContext!.size ?? Size.zero;
                _interactionHandler.fitToScreen(context, size, widget.locations);
              }
            },
            tooltip: 'Fit to screen',
          ),
          IconButton(
            icon: const Icon(Icons.auto_graph),
            color: _controller.autoArrangeEnabled ? Theme.of(context).colorScheme.primary : null,
            onPressed: () {
              setState(() {
                _interactionHandler.toggleAutoArrange();
              });
            },
            tooltip: _controller.autoArrangeEnabled ? 'Auto-arrange on' : 'Auto-arrange off',
          ),
          IconButton(
            icon: const Icon(Icons.grid_3x3),
            color: _showHackerGrid ? Theme.of(context).colorScheme.primary : null,
            onPressed: () {
              setState(() {
                _showHackerGrid = !_showHackerGrid;
              });
            },
            tooltip: _showHackerGrid ? 'Hide grid background' : 'Show grid background',
          ),
        ],
      ),
    );
  }
  
  Widget _buildGraphView() {
    // Define a fixed size for the background that's large enough to contain all nodes
    // This ensures consistent performance and prevents clipping issues
    const double backgroundSize = 2000.0; // Fixed size for the background
    const double halfSize = backgroundSize / 2;
    
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1, // Lower minimum scale to allow zooming out further
      maxScale: 3.0, // Higher maximum scale to allow zooming in further
      transformationController: _controller.transformationController,
      onInteractionEnd: (details) {
        _interactionHandler.handleScaleChanged();
      },
      child: SizedBox(
        width: backgroundSize,
        height: backgroundSize,
        child: ClipRect(
          child: Stack(
            children: [
              // Always have a background - either the hacker grid or a solid color
              if (_showHackerGrid)
                Positioned(
                  left: 0,
                  top: 0,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_gridPulseAnimation, _dataFlowAnimation]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: HackerGridPainter(
                          pulseAnimation: _gridPulseAnimation,
                          flowAnimation: _dataFlowAnimation,
                          primaryColor: const Color(0xFF00FFFF), // Cyan
                          secondaryColor: const Color(0xFF00FF88), // Neon green
                          gridSpacing: 40.0,
                          showDataFlow: true,
                        ),
                        size: const Size(backgroundSize, backgroundSize),
                      );
                    },
                  ),
                )
              else
                // Solid background when grid is hidden
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: backgroundSize,
                    height: backgroundSize,
                    color: Colors.black.withAlpha(217), // Same as the grid background
                  ),
                ),
              
              // Graph edges with enhanced visibility
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: backgroundSize,
                  height: backgroundSize,
                  child: _edgeRenderer.buildEdges(
                    graph: _controller.graph,
                    nodePositions: _getAdjustedNodePositions(),
                    locations: widget.locations,
                    enhancedVisibility: !_showHackerGrid, // Enhance visibility when grid is hidden
                  ),
                ),
              ),
              
              // Graph nodes
              ..._buildNodesWithAdjustedPositions(halfSize),
              
              // Add a visual indicator for the center (0,0) to help with orientation
              Positioned(
                left: halfSize - 5,
                top: halfSize - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(128),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Get node positions adjusted to the fixed background size
  Map<String, Offset> _getAdjustedNodePositions() {
    const double halfSize = 1000.0; // Half of the background size
    final adjustedPositions = <String, Offset>{};
    
    for (final entry in _controller.nodePositionsByLocationId.entries) {
      // Adjust the position to be relative to the center of the background
      final adjustedX = entry.value.dx + halfSize;
      final adjustedY = entry.value.dy + halfSize;
      adjustedPositions[entry.key] = Offset(adjustedX, adjustedY);
    }
    
    return adjustedPositions;
  }
  
  // Build nodes with positions adjusted to the fixed background size
  List<Widget> _buildNodesWithAdjustedPositions(double halfSize) {
    final nodes = <Widget>[];
    
    for (final location in widget.locations) {
      final node = _controller.nodeMap[location.id];
      if (node == null) continue;
      
      // Get the node position and adjust it to be relative to the center of the background
      final position = _controller.nodePositionsByLocationId[location.id] ?? Offset.zero;
      final adjustedX = position.dx + halfSize;
      final adjustedY = position.dy + halfSize;
      
      // Determine if the node should be highlighted
      bool isHighlighted = false;
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        final query = widget.searchQuery!.toLowerCase();
        isHighlighted = location.name.toLowerCase().contains(query) ||
          (location.description != null && location.description!.toLowerCase().contains(query));
      }
      
      // Determine if the node is focused
      bool isFocused = widget.focusLocationId == location.id;
      
      // Check if this is the rig location
      bool isRig = _controller.isRigLocation(location.id);
      
      // For rig node, use animated builder to apply pulse effect
      Widget nodeWidget;
      if (isRig) {
        nodeWidget = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _interactionHandler.handleNodeTap(location.id),
              onDoubleTap: () => _interactionHandler.handleNodeDoubleTap(location.id),
              onPanStart: (_) => _interactionHandler.handleNodeDragStart(location.id),
              onPanUpdate: !_controller.autoArrangeEnabled
                ? (details) => _interactionHandler.handleNodeDragUpdate(location.id, details)
                : null,
              onPanEnd: !_controller.autoArrangeEnabled
                ? (details) => _interactionHandler.handleNodeDragEnd(location.id, details)
                : null,
              child: _nodeRenderer.buildNode(
                location: location,
                isHighlighted: isHighlighted,
                isFocused: isFocused,
                isRig: isRig,
                animationValue: _pulseAnimation.value,
                onTap: () {}, // Handled by the GestureDetector
                onPositionChanged: null, // Handled by the GestureDetector
              ),
            );
          },
        );
      } else {
        nodeWidget = GestureDetector(
          onTap: () => _interactionHandler.handleNodeTap(location.id),
          onDoubleTap: () => _interactionHandler.handleNodeDoubleTap(location.id),
          onPanStart: (_) => _interactionHandler.handleNodeDragStart(location.id),
          onPanUpdate: !_controller.autoArrangeEnabled
            ? (details) => _interactionHandler.handleNodeDragUpdate(location.id, details)
            : null,
          onPanEnd: !_controller.autoArrangeEnabled
            ? (details) => _interactionHandler.handleNodeDragEnd(location.id, details)
            : null,
          child: _nodeRenderer.buildNode(
            location: location,
            isHighlighted: isHighlighted,
            isFocused: isFocused,
            isRig: isRig,
            onTap: () {}, // Handled by the GestureDetector
            onPositionChanged: null, // Handled by the GestureDetector
          ),
        );
      }
      
      // Position the node
      nodes.add(
        Positioned(
          left: adjustedX,
          top: adjustedY,
          child: nodeWidget,
        ),
      );
    }
    
    return nodes;
  }
  
}
