import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../models/location.dart';
import 'dart:ui' as ui;

/// A custom painter for drawing edges between location nodes with colors based on their segments.
class LocationEdgePainter extends CustomPainter {
  final Graph graph;
  final Map<String, Offset> nodePositions;
  final Map<String, Location> locationMap;
  final double strokeWidth;
  final bool useShadow;

  LocationEdgePainter({
    required this.graph,
    required this.nodePositions,
    required this.locationMap,
    this.strokeWidth = 2.0,
    this.useShadow = true,
  });

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
      
      // Draw the edge
      _drawEdge(canvas, sourcePosition, targetPosition, edgeColor);
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Draw shadow/glow effect for better visibility if enabled
    if (useShadow) {
      final shadowPaint = Paint()
        ..color = color.withAlpha(77) // 0.3 opacity = 77 alpha
        ..strokeWidth = strokeWidth + 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawLine(source, target, shadowPaint);
    }
    
    // Draw the main line
    canvas.drawLine(source, target, paint);
    
    // Draw a gradient effect along the line for a more cyberpunk look
    final gradient = ui.Gradient.linear(
      source,
      target,
      [
        color.withAlpha(204), // 0.8 opacity = 204 alpha
        color.withAlpha(102), // 0.4 opacity = 102 alpha
        color.withAlpha(204), // 0.8 opacity = 204 alpha
      ],
      [0.0, 0.5, 1.0],
    );
    
    final gradientPaint = Paint()
      ..shader = gradient
      ..strokeWidth = strokeWidth * 0.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(source, target, gradientPaint);
  }

  @override
  bool shouldRepaint(LocationEdgePainter oldDelegate) {
    return oldDelegate.graph != graph ||
        oldDelegate.nodePositions != nodePositions ||
        oldDelegate.locationMap != locationMap ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.useShadow != useShadow;
  }
}
