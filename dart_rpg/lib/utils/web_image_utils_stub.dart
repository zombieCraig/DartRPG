// This is a stub file for non-web platforms
// It provides a factory function that returns a basic implementation

import 'image_utils.dart';

/// Factory function to create the appropriate implementation
/// On non-web platforms, this returns a basic WebImageUtils instance
ImageUtils createWebImageUtils() {
  return WebImageUtils();
}
