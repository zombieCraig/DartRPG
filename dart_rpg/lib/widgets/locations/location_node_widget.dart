import 'package:flutter/material.dart';
import '../../models/location.dart';
import 'dart:math' as math;

/// A widget for displaying a location node in the graph
class LocationNodeWidget extends StatelessWidget {
  /// The location to display
  final Location location;
  
  /// Whether the node is highlighted
  final bool isHighlighted;
  
  /// Whether the node is focused
  final bool isFocused;
  
  /// Whether the node is the rig location
  final bool isRig;
  
  /// The animation value for pulsing effect
  final double animationValue;
  
  /// Callback when the node is tapped
  final Function() onTap;
  
  /// Callback when the node position is changed
  final Function(Offset)? onPositionChanged;
  
  /// Creates a new LocationNodeWidget
  const LocationNodeWidget({
    super.key,
    required this.location,
    this.isHighlighted = false,
    this.isFocused = false,
    this.isRig = false,
    this.animationValue = 1.0,
    required this.onTap,
    this.onPositionChanged,
  });
  
  /// Format the node text
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
  
  /// Get the text color based on background color
  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  @override
  Widget build(BuildContext context) {
    // Format the node text
    final nodeText = _formatNodeText(location.name);
    
    // Create a border color for better visibility
    final borderColor = isHighlighted || isFocused 
        ? Colors.white 
        : isRig 
            ? Colors.blue.shade300 
            : Colors.black;
    
    return Tooltip(
      message: location.name,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: onPositionChanged != null ? (details) {
          onPositionChanged!(details.delta);
        } : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: location.segment.color,
            shape: isRig ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRig ? BorderRadius.circular(8) : null,
            border: Border.all(
              color: borderColor,
              width: isHighlighted || isFocused || isRig ? 3 : 2,
            ),
            boxShadow: [
              // Simple shadow for depth - no expensive glow effects
              BoxShadow(
                color: Colors.black.withAlpha(77), // 0.3 opacity = 77 alpha
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            nodeText,
            style: TextStyle(
              color: _getTextColor(location.segment.color),
              fontWeight: FontWeight.bold,
              fontSize: 14, // Standard text size for better performance
            ),
          ),
        ),
      ),
    );
  }
}
