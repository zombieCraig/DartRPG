import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/location.dart';
import 'location_graph_controller.dart';

/// A handler for user interactions with the location graph
class LocationInteractionHandler {
  /// The graph controller
  final LocationGraphController controller;
  
  /// Flag to track if a drag operation is in progress
  bool _isDragging = false;
  
  /// Callback when drag starts
  final Function()? onDragStart;
  
  /// Callback when drag updates
  final Function()? onDragUpdate;
  
  /// Callback when drag ends
  final Function()? onDragEnd;
  
  /// Creates a new LocationInteractionHandler
  LocationInteractionHandler({
    required this.controller,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
  });
  
  /// Handles zoom in action
  void zoomIn() {
    final newScale = math.min(2.0, controller.scale + 0.1);
    controller.updateScale(newScale);
  }
  
  /// Handles zoom out action
  void zoomOut() {
    final newScale = math.max(0.5, controller.scale - 0.1);
    controller.updateScale(newScale);
  }
  
  /// Handles reset zoom action
  void resetZoom() {
    controller.resetZoom();
  }
  
  /// Handles fit to screen action
  void fitToScreen(BuildContext context, Size size, List<Location> locations) {
    controller.fitToScreen(context, size, locations);
  }
  
  /// Handles toggle auto-arrange action
  void toggleAutoArrange() {
    controller.toggleAutoArrange();
  }
  
  /// Handles node drag start
  void handleNodeDragStart(String locationId) {
    _isDragging = true;
    
    // Tell the controller to disable autosaving during drag
    controller.setDragInProgress(true);
    
    // Call the drag start callback
    if (onDragStart != null) {
      onDragStart!();
    }
  }
  
  /// Handles node drag update
  void handleNodeDragUpdate(String locationId, DragUpdateDetails details) {
    // If this is the first update and we didn't catch the start event
    if (!_isDragging) {
      handleNodeDragStart(locationId);
    }
    
    // Calculate the delta in the graph's coordinate system
    final delta = details.delta;
    
    if (controller.autoArrangeEnabled) {
      // Apply a force to the node in the direction of the drag
      final force = Offset(delta.dx, delta.dy) * 5.0; // Scale for more noticeable effect
      controller.applyRepulsiveForce(locationId, force);
    } else {
      // Update position without saving
      controller.updateNodePositionWithoutSaving(locationId, delta.dx, delta.dy);
    }
    
    // Call the drag update callback
    if (onDragUpdate != null) {
      onDragUpdate!();
    }
  }
  
  /// Handles node drag end
  void handleNodeDragEnd(String locationId, DragEndDetails details) {
    if (!_isDragging) return;
    
    // Reset drag state
    _isDragging = false;
    
    if (!controller.autoArrangeEnabled) {
      // Tell the controller to re-enable autosaving and save the current state
      controller.setDragInProgress(false);
      controller.saveCurrentPositions();
    } else {
      // For auto-arrange mode, update positions from the force-directed layout
      controller.updatePositionsFromForceDirectedLayout();
    }
    
    // Call the drag end callback
    if (onDragEnd != null) {
      onDragEnd!();
    }
  }
  
  /// Handles node tap
  void handleNodeTap(String locationId) {
    if (controller.onLocationTap != null) {
      controller.onLocationTap!(locationId);
    }
  }
  
  /// Handles node double tap for editing
  void handleNodeDoubleTap(String locationId) {
    if (controller.onLocationEdit != null) {
      controller.onLocationEdit!(locationId);
    }
  }
  
  /// Handles scale changed
  void handleScaleChanged() {
    if (controller.onScaleChanged != null) {
      controller.onScaleChanged!(controller.scale);
    }
  }
}
