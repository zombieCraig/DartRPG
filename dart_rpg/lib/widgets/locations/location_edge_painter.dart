import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../models/location.dart';
import 'dart:ui' as ui;

/// A custom painter for drawing edges between location nodes with colors based on their segments.
class LocationEdgePainter extends CustomPainter {
  final Graph graph;
  final Map<String, Offset> nodePositions;
  final Map<String, Location> locationMap;
  final double strokeWidth;
  final bool useShadow;
  final bool enhancedGlow;

  LocationEdgePainter({
    required this.graph,
    required this.nodePositions,
    required this.locationMap,
    this.strokeWidth = 2.0,
    this.useShadow = true,
    this.enhancedGlow = false,
  });

  // Node size constants
  static const double nodeSize = 32.0; // Approximate size of a node (16px padding on each side)
  static const double halfNodeSize = nodeSize / 2;
  static const double rigNodeWidth = 32.0; // Approximate width of a rig node
  static const double rigNodeHeight = 32.0; // Approximate height of a rig node
  static const double halfRigNodeWidth = rigNodeWidth / 2;
  static const double halfRigNodeHeight = rigNodeHeight / 2;
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final sourceId = edge.source.key!.value as String;
      final targetId = edge.destination.key!.value as String;
      
      final sourcePosition = nodePositions[sourceId];
      final targetPosition = nodePositions[targetId];
      
      // Skip if we don't have positions for both nodes
      if (sourcePosition == null || targetPosition == null) continue;
      
      // Get the locations for the source and target nodes
      final sourceLocation = locationMap[sourceId];
      final targetLocation = locationMap[targetId];
      
      // Skip if we don't have location data
      if (sourceLocation == null || targetLocation == null) continue;
      
      // Determine the edge color based on the segments
      final edgeColor = _getEdgeColor(sourceLocation.segment, targetLocation.segment);
      
      // Adjust positions to connect to the center of nodes
      final adjustedSourcePosition = _adjustPositionToNodeCenter(sourcePosition, sourceLocation);
      final adjustedTargetPosition = _adjustPositionToNodeCenter(targetPosition, targetLocation);
      
      // Draw the edge
      _drawEdge(canvas, adjustedSourcePosition, adjustedTargetPosition, edgeColor);
    }
  }
  
  /// Adjusts the position to point to the center of the node
  Offset _adjustPositionToNodeCenter(Offset position, Location location) {
    // Check if this is a rig location (rectangular) or a regular location (circular)
    if (location.nodeType == 'rig' || location.id == 'rig') {
      // For rig nodes (rectangular)
      return Offset(
        position.dx + halfRigNodeWidth,
        position.dy + halfRigNodeHeight
      );
    } else {
      // For regular nodes (circular)
      return Offset(
        position.dx + halfNodeSize,
        position.dy + halfNodeSize
      );
    }
  }
  
  /// Determines the color for an edge based on the segments of the connected locations.
  Color _getEdgeColor(LocationSegment sourceSegment, LocationSegment targetSegment) {
    // If both locations are in the same segment, use that segment's color
    if (sourceSegment == targetSegment) {
      return _getSegmentColor(sourceSegment);
    }
    
    // If they're in different segments, blend the colors
    final sourceColor = _getSegmentColor(sourceSegment);
    final targetColor = _getSegmentColor(targetSegment);
    
    // Create a blend of the two colors
    return Color.lerp(sourceColor, targetColor, 0.5)!;
  }
  
  /// Gets a color for a segment that's suitable for edges (may be different from node colors).
  Color _getSegmentColor(LocationSegment segment) {
    switch (segment) {
      case LocationSegment.core:
        return Colors.green.shade400.withAlpha(204); // 0.8 opacity = 204 alpha
      case LocationSegment.corpNet:
        return Colors.yellow.shade600.withAlpha(204); // 0.8 opacity = 204 alpha
      case LocationSegment.govNet:
        return Colors.blue.shade300.withAlpha(204); // 0.8 opacity = 204 alpha, using blue instead of grey for better visibility
      case LocationSegment.darkNet:
        return Colors.purple.shade300.withAlpha(204); // 0.8 opacity = 204 alpha, using purple instead of black for better visibility
    }
  }
  
  /// Draws an edge between two points with the specified color.
  void _drawEdge(Canvas canvas, Offset source, Offset target, Color color) {
    // Use a slightly brighter color when enhanced visibility is enabled
    final edgeColor = enhancedGlow 
        ? Color.lerp(color, Colors.white, 0.2)! 
        : color;
    
    // Create a simple paint for the edge
    final paint = Paint()
      ..color = edgeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw a simple shadow if enabled (much more performant than glow effects)
    if (useShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withAlpha(51) // 0.2 opacity = 51 alpha
        ..strokeWidth = strokeWidth + 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Offset the shadow slightly for a 3D effect
      canvas.drawLine(
        Offset(source.dx + 1, source.dy + 1), 
        Offset(target.dx + 1, target.dy + 1), 
        shadowPaint
      );
    }
    
    // Draw the main line
    canvas.drawLine(source, target, paint);
  }

  @override
  bool shouldRepaint(LocationEdgePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.locationMap != locationMap ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useShadow != useShadow ||
        oldDelegate.enhancedGlow != enhancedGlow;
  }
}
