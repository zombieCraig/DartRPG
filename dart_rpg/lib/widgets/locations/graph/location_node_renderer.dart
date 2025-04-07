import 'package:flutter/material.dart';
import '../../../models/location.dart';
import 'dart:math' as math;
import '../location_node_widget.dart';

/// A renderer for location nodes in the graph
class LocationNodeRenderer {
  /// Creates a new LocationNodeRenderer
  const LocationNodeRenderer();
  
  /// Builds a node widget for a location
  Widget buildNode({
    required Location location,
    required bool isHighlighted,
    required bool isFocused,
    required bool isRig,
    required Function() onTap,
    Function(Offset)? onPositionChanged,
    double animationValue = 1.0,
  }) {
    return LocationNodeWidget(
      location: location,
      isHighlighted: isHighlighted,
      isFocused: isFocused,
      isRig: isRig,
      animationValue: animationValue,
      onTap: onTap,
      onPositionChanged: onPositionChanged,
    );
  }
  
  /// Formats node text for display
  String formatNodeText(String name) {
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
  
  /// Gets the text color based on background color
  Color getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
