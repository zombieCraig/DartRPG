import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../../models/location.dart';
import '../location_edge_painter.dart';

/// A renderer for edges between location nodes in the graph
class LocationEdgeRenderer {
  /// Creates a new LocationEdgeRenderer
  const LocationEdgeRenderer();
  
  /// Builds a custom painter for the edges
  CustomPaint buildEdges({
    required Graph graph,
    required Map<String, Offset> nodePositions,
    required List<Location> locations,
    bool enhancedVisibility = false,
  }) {
    // Create a map of location IDs to locations for easy lookup
    final locationMap = {for (var loc in locations) loc.id: loc};
    
    return CustomPaint(
      painter: LocationEdgePainter(
        graph: graph,
        nodePositions: nodePositions,
        locationMap: locationMap,
        strokeWidth: enhancedVisibility ? 3.5 : 2.5, // Thicker lines when grid is hidden
        useShadow: true,
        enhancedGlow: enhancedVisibility, // Add stronger glow when grid is hidden
      ),
      // Use a transparent child to ensure the painter covers the entire area
      child: Container(color: Colors.transparent),
    );
  }
  
  /// Determines the color for an edge based on the segments of the connected locations.
  Color getEdgeColor(LocationSegment sourceSegment, LocationSegment targetSegment) {
    // If both locations are in the same segment, use that segment's color
    if (sourceSegment == targetSegment) {
      return getSegmentEdgeColor(sourceSegment);
    }
    
    // If they're in different segments, blend the colors
    final sourceColor = getSegmentEdgeColor(sourceSegment);
    final targetColor = getSegmentEdgeColor(targetSegment);
    
    // Create a blend of the two colors
    return Color.lerp(sourceColor, targetColor, 0.5)!;
  }
  
  /// Gets a color for a segment that's suitable for edges (may be different from node colors).
  Color getSegmentEdgeColor(LocationSegment segment) {
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
}
