import 'dart:io';
import 'package:flutter/material.dart';

/// Utility functions for the Sentient AI feature
class SentientAiUtils {
  /// Returns the asset path for a given persona name
  static String? getDefaultImageAsset(String? personaText) {
    if (personaText == null) return null;
    
    // Extract just the persona name without description
    final personaName = personaText.split(' - ')[0];
    
    // Convert to lowercase and replace spaces with underscores
    final assetName = personaName.toLowerCase().replaceAll(' ', '_');
    
    return 'assets/images/sentient_ai/$assetName.webp';
  }
  
  /// Builds an AI image widget that handles both custom and default images
  static Widget buildAiImage(
    BuildContext context,
    String? imagePath,
    String? personaText, {
    double? height,
    bool useResponsiveHeight = true,
  }) {
    final imageHeight = height ?? 
        (useResponsiveHeight && MediaQuery.of(context).size.width < 600 ? 100.0 : 150.0);
    
    // First try custom image
    if (imagePath != null && File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          height: imageHeight,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // Fall back to default image based on persona
    final defaultAsset = getDefaultImageAsset(personaText);
    if (defaultAsset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          defaultAsset,
          height: imageHeight,
          fit: BoxFit.cover,
        ),
      );
    }
    
    // No image available - show placeholder
    return Container(
      height: imageHeight,
      width: imageHeight * 0.75, // Maintains 4:3 ratio
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(100)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }
}
