// This file contains the web-specific implementation of image utilities
// It's only imported and used on web platforms

import 'dart:html' as html;
import 'dart:typed_data';
import '../utils/logging_service.dart';
import 'image_utils.dart';

/// Web-specific implementation of image utilities
class WebImageUtilsImpl extends WebImageUtils {
  static final LoggingService _loggingService = LoggingService();
  
  /// Map to store blob URLs for images
  static final Map<String, String> _blobUrlCache = {};
  
  @override
  String? createDisplayUrlFromBytes(Uint8List bytes) {
    try {
      // Create a blob from the bytes
      final blob = html.Blob([bytes]);
      
      // Create a URL for the blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Cache the URL
      _blobUrlCache[url] = url;
      
      return url;
    } catch (e) {
      _loggingService.error('Error creating blob URL from bytes: $e', tag: 'WebImageUtilsImpl');
      return null;
    }
  }
  
  @override
  void dispose() {
    try {
      // Revoke all blob URLs to free memory
      for (final url in _blobUrlCache.values) {
        if (url.startsWith('blob:')) {
          html.Url.revokeObjectUrl(url);
        }
      }
      _blobUrlCache.clear();
    } catch (e) {
      _loggingService.error('Error disposing WebImageUtilsImpl: $e', tag: 'WebImageUtilsImpl');
    }
    
    super.dispose();
  }
}

/// Factory function to create the appropriate implementation
ImageUtils createWebImageUtils() {
  return WebImageUtilsImpl();
}
