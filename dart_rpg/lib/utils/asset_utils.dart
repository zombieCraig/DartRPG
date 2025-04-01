import 'package:flutter/material.dart';

/// Returns the appropriate color for an asset based on its category.
Color getAssetCategoryColor(String category, {bool isDarkMode = false}) {
  final lowerCategory = category.toLowerCase();
  
  // Base Rig
  if (lowerCategory == 'base rig' || lowerCategory.contains('rig')) {
    return isDarkMode ? Colors.white : Colors.black;
  }
  
  // Module
  if (lowerCategory.contains('module')) {
    return Colors.blue.shade500;
  }
  
  // Path
  if (lowerCategory.contains('path')) {
    return Colors.purple.shade500;
  }
  
  // Companion
  if (lowerCategory.contains('companion')) {
    return isDarkMode ? Colors.amber.shade300 : Colors.amber.shade700;
  }
  
  // Default fallback
  return Colors.purple.shade500;
}
