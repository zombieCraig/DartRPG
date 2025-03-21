import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/location.dart';
import '../models/game.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

class LocationGraphWidget extends StatefulWidget {
  final List<Location> locations;
  final Function(String locationId) onLocationTap;
  final Function(String locationId, double x, double y) onLocationMoved;
  final Function(double scale) onScaleChanged;
  final String? searchQuery;
  final String? focusLocationId;
  final Game? game;

  const LocationGraphWidget({
    Key? key,
    required this.locations,
    required this.onLocationTap,
    required this.onLocationMoved,
    required this.onScaleChanged,
    this.searchQuery,
    this.focusLocationId,
    this.game,
  }) : super(key: key);

  @override
  _LocationGraphWidgetState createState() => _LocationGraphWidgetState();
}

class _LocationGraphWidgetState extends State<LocationGraphWidget> with SingleTickerProviderStateMixin {
  late Graph graph;
  late Algorithm algorithm;
  double _scale = 1.0;
  bool _autoArrangeEnabled = false;
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _graphKey = GlobalKey();
  Map<String, Node> _nodeMap = {};
  Map<Node, Offset> _nodePositions = {};
  
  // For rig node pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _buildGraph();
    
    // Setup animation for rig node
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // Focus on location if provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.focusLocationId != null) {
        _focusOnLocation(widget.focusLocationId!);
      }
    });
  }
  
  @override
  void didUpdateWidget(LocationGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Rebuild graph if locations list changes or connections change
    bool needsRebuild = oldWidget.locations.length != widget.locations.length;
    
    if (!needsRebuild) {
      // Check if the location IDs have changed
      final oldIds = oldWidget.locations.map((loc) => loc.id).toSet();
      final newIds = widget.locations.map((loc) => loc.id).toSet();
      
      if (!const SetEquality<String>().equals(oldIds, newIds)) {
        needsRebuild = true;
      } else {
        // Check if any location's connections have changed
        for (int i = 0; i < widget.locations.length; i++) {
          final oldLoc = oldWidget.locations.firstWhere(
            (loc) => loc.id == widget.locations[i].id, 
            orElse: () => widget.locations[i]
          );
          final newLoc = widget.locations[i];
          
          if (oldLoc.connectedLocationIds.length != newLoc.connectedLocationIds.length) {
            needsRebuild = true;
            break;
          }
          
          for (final connId in oldLoc.connectedLocationIds) {
            if (!newLoc.connectedLocationIds.contains(connId)) {
              needsRebuild = true;
              break;
            }
          }
          
          if (needsRebuild) break;
        }
      }
    }
    
    if (needsRebuild) {
      _buildGraph();
    }
    
    // Focus on location if it changed
    if (widget.focusLocationId != null && 
        widget.focusLocationId != oldWidget.focusLocationId) {
      _focusOnLocation(widget.focusLocationId!);
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _transformationController.dispose();
    super.dispose();
  }
  
  void _buildGraph() {
    graph = Graph()..isTree = false;
    _nodeMap = {};
    
    // Create nodes for each location
    for (final location in widget.locations) {
      final node = Node.Id(location.id);
      _nodeMap[location.id] = node;
      graph.addNode(node);
    }
    
    // Create edges for connections
    for (final location in widget.locations) {
      final sourceNode = _nodeMap[location.id];
      if (sourceNode == null) continue;
      
      for (final targetId in location.connectedLocationIds) {
        final targetNode = _nodeMap[targetId];
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
          graph.addEdge(sourceNode, targetNode);
        }
      }
    }
    
    // Apply saved positions if available and auto-arrange is disabled
    if (!_autoArrangeEnabled) {
      for (final location in widget.locations) {
        if (location.x != null && location.y != null) {
          final node = _nodeMap[location.id];
          if (node != null) {
            // We can't directly set node positions in the algorithm,
            // but we'll use this information in the layout
          }
        }
      }
    }
    
    // Use FruchtermanReingoldAlgorithm for layout
    algorithm = FruchtermanReingoldAlgorithm(iterations: _autoArrangeEnabled ? 1000 : 100);
  }
  
  void _toggleAutoArrange() {
    setState(() {
      _autoArrangeEnabled = !_autoArrangeEnabled;
      _buildGraph();
    });
  }
  
  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
    widget.onScaleChanged(_scale);
  }
  
  void _fitToScreen() {
    if (_graphKey.currentContext == null || widget.locations.isEmpty) return;
    
    // Get the size of the graph container
    final RenderBox renderBox = _graphKey.currentContext!.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    
    // Calculate the bounds of all nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    
    // This is a simplification since we don't have direct access to node positions
    // In a real implementation, you'd get the actual positions from the algorithm
    final nodeCount = widget.locations.length;
    if (nodeCount > 0) {
      // Estimate the graph bounds based on the number of nodes
      // This is a very rough approximation
      final estimatedWidth = math.sqrt(nodeCount) * 100.0;
      final estimatedHeight = math.sqrt(nodeCount) * 100.0;
      
      minX = -estimatedWidth / 2;
      minY = -estimatedHeight / 2;
      maxX = estimatedWidth / 2;
      maxY = estimatedHeight / 2;
      
      // Calculate the scale needed to fit the graph in the container
      final graphWidth = maxX - minX;
      final graphHeight = maxY - minY;
      
      if (graphWidth > 0 && graphHeight > 0) {
        final scaleX = size.width / graphWidth;
        final scaleY = size.height / graphHeight;
        _scale = math.min(scaleX, scaleY) * 0.9; // 90% to add some padding
        
        // Create a transformation matrix that centers and scales the graph
        final matrix = Matrix4.identity()
          ..translate(size.width / 2, size.height / 2)
          ..scale(_scale, _scale)
          ..translate(-(minX + maxX) / 2, -(minY + maxY) / 2);
        
        setState(() {
          _transformationController.value = matrix;
        });
        
        widget.onScaleChanged(_scale);
      }
    }
  }
  
  void _focusOnLocation(String locationId) {
    final node = _nodeMap[locationId];
    if (node == null) return;
    
    // Wait for the layout to be calculated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_graphKey.currentContext == null) return;
      
      // Get the size of the graph container
      final RenderBox renderBox = _graphKey.currentContext!.findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      
      // Get the node position from the algorithm
      final position = algorithm.getNodePosition(node);
      if (position == null) return;
      
      // Create a transformation matrix that centers on the node
      final matrix = Matrix4.identity()
        ..translate(size.width / 2 - position.dx * _scale, size.height / 2 - position.dy * _scale)
        ..scale(_scale, _scale);
      
      setState(() {
        _transformationController.value = matrix;
      });
    });
  }
  
  // Helper method to get node positions from the algorithm
  Offset? _getNodePosition(Node node) {
    try {
      // This is a workaround since we don't have direct access to the node positions
      // In a real implementation, you'd get the actual position from the algorithm
      final builder = Builder(
        builder: (context) {
          final position = algorithm.getNodePosition(node);
          if (position != null) {
            _nodePositions[node] = position;
          }
          return Container();
        }
      );
      
      // Force build to get position
      builder.build(context);
      
      return _nodePositions[node];
    } catch (e) {
      return null;
    }
  }
  
  // Helper method to format node text
  String _formatNodeText(String name) {
    if (name.isEmpty) return '';
    
    // Split the name into words
    final words = name.split(' ');
    
    if (words.length == 1) {
      // Single word - take first two characters
      return name.substring(0, math.min(2, name.length));
    } else {
      // Multiple words - take first character of each word (up to 3 words)
      final buffer = StringBuffer();
      for (int i = 0; i < math.min(3, words.length); i++) {
        if (words[i].isNotEmpty) {
          buffer.write(words[i][0]);
        }
      }
      return buffer.toString();
    }
  }
  
  // Check if a location is the rig
  bool _isRigLocation(Location location) {
    return widget.game?.rigLocation?.id == location.id;
  }
  
  @override
  Widget build(BuildContext context) {
    // Filter locations based on search query
    List<Location> filteredLocations = widget.locations;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      final query = widget.searchQuery!.toLowerCase();
      filteredLocations = widget.locations.where((loc) => 
        loc.name.toLowerCase().contains(query) ||
        (loc.description != null && loc.description!.toLowerCase().contains(query))
      ).toList();
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() {
                    _scale = math.min(2.0, _scale + 0.1);
                    final matrix = _transformationController.value.clone()
                      ..setEntry(0, 0, _scale)
                      ..setEntry(1, 1, _scale);
                    _transformationController.value = matrix;
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() {
                    _scale = math.max(0.5, _scale - 0.1);
                    final matrix = _transformationController.value.clone()
                      ..setEntry(0, 0, _scale)
                      ..setEntry(1, 1, _scale);
                    _transformationController.value = matrix;
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetZoom,
              ),
              IconButton(
                icon: const Icon(Icons.fit_screen),
                onPressed: _fitToScreen,
                tooltip: 'Fit to screen',
              ),
              IconButton(
                icon: Icon(Icons.auto_graph),
                color: _autoArrangeEnabled ? Theme.of(context).colorScheme.primary : null,
                onPressed: _toggleAutoArrange,
                tooltip: _autoArrangeEnabled ? 'Auto-arrange on' : 'Auto-arrange off',
              ),
            ],
          ),
        ),
        Expanded(
          key: _graphKey,
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.5,
            maxScale: 2.0,
            transformationController: _transformationController,
            onInteractionEnd: (details) {
              widget.onScaleChanged(_scale);
            },
            child: GraphView(
              key: ValueKey(widget.locations.map((l) => l.id).join(',')),
              graph: graph,
              algorithm: algorithm,
              paint: Paint()
                ..color = Colors.black
                ..strokeWidth = 2.0
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final locationId = node.key!.value as String;
                final location = widget.locations.firstWhere(
                  (loc) => loc.id == locationId,
                  orElse: () => widget.locations.first,
                );
                
                // Highlight the node if it matches the search query
                bool isHighlighted = false;
                if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                  final query = widget.searchQuery!.toLowerCase();
                  isHighlighted = location.name.toLowerCase().contains(query) ||
                    (location.description != null && location.description!.toLowerCase().contains(query));
                }
                
                // Highlight the focused node
                bool isFocused = widget.focusLocationId == locationId;
                
                // Check if this is the rig location
                bool isRig = _isRigLocation(location);
                
                return _buildLocationNode(location, node, isHighlighted, isFocused, isRig);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocationNode(Location location, Node node, bool isHighlighted, bool isFocused, bool isRig) {
    // For rig node, use animated builder to apply pulse effect
    if (isRig) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return _buildNodeContent(location, node, isHighlighted, isFocused, isRig, _pulseAnimation.value);
        },
      );
    } else {
      return _buildNodeContent(location, node, isHighlighted, isFocused, isRig, 1.0);
    }
  }
  
  Widget _buildNodeContent(Location location, Node node, bool isHighlighted, bool isFocused, bool isRig, double animationValue) {
    // Format the node text
    final nodeText = _formatNodeText(location.name);
    
    return Tooltip(
      message: location.name,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () => widget.onLocationTap(location.id),
        onPanUpdate: !_autoArrangeEnabled ? (details) {
          // Get the current position
          final position = _getNodePosition(node);
          if (position == null) return;
          
          // Update the position based on the drag
          final newX = position.dx + details.delta.dx / _scale;
          final newY = position.dy + details.delta.dy / _scale;
          
          // Store the new position
          _nodePositions[node] = Offset(newX, newY);
          
          // Force a rebuild
          setState(() {});
        } : null,
        onPanEnd: !_autoArrangeEnabled ? (details) {
          // Get the final position
          final position = _nodePositions[node];
          if (position == null) return;
          
          // Update the location's position
          widget.onLocationMoved(location.id, position.dx, position.dy);
        } : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: location.segment.color,
            shape: isRig ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRig ? BorderRadius.circular(8) : null,
            border: Border.all(
              color: isHighlighted || isFocused ? Colors.white : Colors.black,
              width: isHighlighted || isFocused ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isRig 
                  ? Colors.blue.withOpacity(0.5 * animationValue)
                  : isHighlighted || isFocused 
                    ? Colors.yellow.withOpacity(0.5)
                    : Colors.black.withOpacity(0.2),
                spreadRadius: isRig ? 3 * animationValue : isHighlighted || isFocused ? 3 : 1,
                blurRadius: isRig ? 5 * animationValue : isHighlighted || isFocused ? 5 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            nodeText,
            style: TextStyle(
              color: _getTextColor(location.segment.color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Extension method for Algorithm to get node position
extension AlgorithmExtension on Algorithm {
  Offset? getNodePosition(Node node) {
    try {
      // Since we can't directly access the node positions from the algorithm,
      // we'll use a simplified approach that returns a default position
      // In a real implementation, you'd need to find a way to access the actual positions
      return Offset(0, 0);
    } catch (e) {
      return null;
    }
  }
}
