import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' as picker;
import '../models/app_image.dart';
import '../utils/logging_service.dart';

// Import web implementation conditionally
// ignore: uri_does_not_exist
import 'web_image_utils_impl.dart' if (dart.library.io) 'web_image_utils_stub.dart';

/// Abstract base class for image utilities
abstract class ImageUtils {
  static final LoggingService _loggingService = LoggingService();
  
  /// Get the platform-specific implementation
  static ImageUtils get instance {
    if (kIsWeb) {
      try {
        // Try to use the web implementation
        return createWebImageUtils();
      } catch (e) {
        // Fall back to the basic implementation
        return WebImageUtils();
      }
    } else {
      return NativeImageUtils();
    }
  }
  
  /// Create a displayable URL from an XFile
  Future<String?> createDisplayUrlFromXFile(picker.XFile file);
  
  /// Create a displayable URL from bytes
  String? createDisplayUrlFromBytes(Uint8List bytes);
  
  /// Get a displayable URL for an AppImage
  String? getDisplayUrlForAppImage(AppImage image);
  
  /// Store a displayable URL for an AppImage
  void storeDisplayUrlForAppImage(AppImage image, String url);
  
  /// Clean up resources
  void dispose();
}

/// Implementation for web platforms
class WebImageUtils implements ImageUtils {
  static final LoggingService _loggingService = LoggingService();
  
  /// Map to store blob URLs for images
  static final Map<String, String> _blobUrlCache = {};
  
  @override
  Future<String?> createDisplayUrlFromXFile(picker.XFile file) async {
    try {
      // On web, XFile.path is not a file system path but a object URL
      if (file.path.startsWith('blob:') || file.path.startsWith('http')) {
        return file.path;
      }
      
      // Read the file as bytes
      final bytes = await file.readAsBytes();
      return createDisplayUrlFromBytes(bytes);
    } catch (e) {
      _loggingService.error('Error creating display URL from XFile: $e', tag: 'WebImageUtils');
      return null;
    }
  }
  
  @override
  String? createDisplayUrlFromBytes(Uint8List bytes) {
    try {
      // For web, we need to use the dart:html API
      // This is handled in a separate file that's imported conditionally
      // Here we just return null as a fallback
      _loggingService.debug('Creating blob URL from bytes', tag: 'WebImageUtils');
      return null;
    } catch (e) {
      _loggingService.error('Error creating display URL from bytes: $e', tag: 'WebImageUtils');
      return null;
    }
  }
  
  @override
  String? getDisplayUrlForAppImage(AppImage image) {
    // Check if we already have a blob URL for this image
    if (_blobUrlCache.containsKey(image.id)) {
      return _blobUrlCache[image.id];
    }
    
    // If the image has an original URL, use that
    if (image.originalUrl != null && image.originalUrl!.isNotEmpty) {
      return image.originalUrl;
    }
    
    return null;
  }
  
  @override
  void storeDisplayUrlForAppImage(AppImage image, String url) {
    _blobUrlCache[image.id] = url;
  }
  
  @override
  void dispose() {
    // Clean up resources
    _blobUrlCache.clear();
  }
}

/// Implementation for native platforms
class NativeImageUtils implements ImageUtils {
  static final LoggingService _loggingService = LoggingService();
  
  @override
  Future<String?> createDisplayUrlFromXFile(picker.XFile file) async {
    // For native platforms, we just return the file path
    return file.path;
  }
  
  @override
  String? createDisplayUrlFromBytes(Uint8List bytes) {
    // For native platforms, we can't create a URL from bytes directly
    // This would typically involve saving the bytes to a temporary file
    // and returning the file path, but for simplicity we return null
    return null;
  }
  
  @override
  String? getDisplayUrlForAppImage(AppImage image) {
    // For native platforms, we return the local path
    return image.localPath;
  }
  
  @override
  void storeDisplayUrlForAppImage(AppImage image, String url) {
    // No-op for native platforms
  }
  
  @override
  void dispose() {
    // No-op for native platforms
  }
}
