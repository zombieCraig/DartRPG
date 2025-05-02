import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_image.dart';
import '../utils/logging_service.dart';

/// A service for storing and managing images.
class ImageStorageService {
  final LoggingService _loggingService = LoggingService();
  
  // In-memory storage for web platform
  static final Map<String, AppImage> _webImages = {};
  
  /// Get the application documents directory
  Future<Directory?> get _appDir async {
    if (kIsWeb) return null;
    
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      _loggingService.error(
        'Error getting application documents directory: $e',
        tag: 'ImageStorageService',
        error: e,
      );
      return null;
    }
  }
  
  /// Get the images directory
  Future<Directory?> get _imagesDir async {
    if (kIsWeb) return null;
    
    try {
      final appDir = await _appDir;
      if (appDir == null) return null;
      
      final imagesDir = Directory('${appDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      return imagesDir;
    } catch (e) {
      _loggingService.error(
        'Error getting images directory: $e',
        tag: 'ImageStorageService',
        error: e,
      );
      return null;
    }
  }
  
  /// Save an image from a URL
  Future<AppImage?> saveImageFromUrl(String url, {Map<String, dynamic>? metadata}) async {
    try {
      // Download the image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        _loggingService.error(
          'Failed to download image from URL: $url',
          tag: 'ImageStorageService',
        );
        return null;
      }
      
      // Generate a unique ID
      final id = const Uuid().v4();
      
      if (kIsWeb) {
        // On web, we just store the URL
        final appImage = AppImage(
          id: id,
          localPath: url, // Use the URL as the path on web
          originalUrl: url,
          source: ImageSource.url,
          metadata: metadata,
        );
        
        // Store in memory
        _webImages[id] = appImage;
        
        return appImage;
      } else {
        // Get the images directory
        final imagesDir = await _imagesDir;
        if (imagesDir == null) return null;
        
        // Generate a unique filename
        final filename = '$id.jpg';
        
        // Save the image to the file system
        final file = File('${imagesDir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        
        // Create and return the AppImage object
        return AppImage(
          id: id,
          localPath: file.path,
          originalUrl: url,
          source: ImageSource.url,
          metadata: metadata,
        );
      }
    } catch (e) {
      _loggingService.error(
        'Error saving image from URL: $e',
        tag: 'ImageStorageService',
        error: e,
      );
      return null;
    }
  }
  
  /// Save an image from a file (e.g., picked from gallery)
  Future<AppImage?> saveImageFromFile(File imageFile, {Map<String, dynamic>? metadata}) async {
    try {
      // Generate a unique ID
      final id = const Uuid().v4();
      
      if (kIsWeb) {
        // On web, we can't use the file system
        // Instead, we create an AppImage with the original path
        // and store it in memory
        final appImage = AppImage(
          id: id,
          localPath: imageFile.path, // This will be a blob URL on web
          source: ImageSource.gallery,
          metadata: metadata,
        );
        
        // Store in memory
        _webImages[id] = appImage;
        
        return appImage;
      } else {
        // Get the images directory
        final imagesDir = await _imagesDir;
        if (imagesDir == null) return null;
        
        // Generate a unique filename
        final filename = '$id.jpg';
        
        // Copy the image to the app's directory
        final file = await imageFile.copy('${imagesDir.path}/$filename');
        
        // Create and return the AppImage object
        return AppImage(
          id: id,
          localPath: file.path,
          source: ImageSource.gallery,
          metadata: metadata,
        );
      }
    } catch (e) {
      _loggingService.error(
        'Error saving image from file: $e',
        tag: 'ImageStorageService',
        error: e,
      );
      return null;
    }
  }
  
  /// Delete an image
  Future<bool> deleteImage(AppImage image) async {
    try {
      if (kIsWeb) {
        // On web, we just remove it from memory
        _webImages.remove(image.id);
        return true;
      } else {
        // Delete the image file
        final file = File(image.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Delete the thumbnail if it exists
        if (image.thumbnailPath != null) {
          final thumbnailFile = File(image.thumbnailPath!);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        }
        
        return true;
      }
    } catch (e) {
      _loggingService.error(
        'Error deleting image: $e',
        tag: 'ImageStorageService',
        error: e,
      );
      return false;
    }
  }
}
