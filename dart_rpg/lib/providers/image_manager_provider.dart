import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_image.dart';
import '../services/image_storage_service.dart';
import '../utils/logging_service.dart';

/// A provider for managing images in the application.
class ImageManagerProvider extends ChangeNotifier {
  final ImageStorageService _storageService = ImageStorageService();
  final LoggingService _loggingService = LoggingService();
  
  List<AppImage> _images = [];
  
  /// Get all images
  List<AppImage> get images => _images;
  
  /// Load images from storage
  Future<void> loadImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getString('app_images');
      
      if (imagesJson != null) {
        final List<dynamic> decoded = jsonDecode(imagesJson);
        _images = decoded.map((json) => AppImage.fromJson(json)).toList();
        
        if (!kIsWeb) {
          // On native platforms, verify that all image files still exist
          _images = _images.where((image) {
            final file = File(image.localPath);
            return file.existsSync();
          }).toList();
          
          // Save the cleaned list
          await _saveImagesToPrefs();
        }
      }
      
      notifyListeners();
    } catch (e) {
      _loggingService.error(
        'Error loading images: $e',
        tag: 'ImageManagerProvider',
        error: e,
      );
    }
  }
  
  /// Save images to SharedPreferences
  Future<void> _saveImagesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = jsonEncode(_images.map((image) => image.toJson()).toList());
      await prefs.setString('app_images', imagesJson);
    } catch (e) {
      _loggingService.error(
        'Error saving images to prefs: $e',
        tag: 'ImageManagerProvider',
        error: e,
      );
    }
  }
  
  /// Add an image from a URL
  Future<AppImage?> addImageFromUrl(String url, {Map<String, dynamic>? metadata}) async {
    try {
      final image = await _storageService.saveImageFromUrl(url, metadata: metadata);
      
      if (image != null) {
        _images.add(image);
        await _saveImagesToPrefs();
        notifyListeners();
      }
      
      return image;
    } catch (e) {
      _loggingService.error(
        'Error adding image from URL: $e',
        tag: 'ImageManagerProvider',
        error: e,
      );
      return null;
    }
  }
  
  /// Add an image from a file
  Future<AppImage?> addImageFromFile(File imageFile, {Map<String, dynamic>? metadata}) async {
    try {
      final image = await _storageService.saveImageFromFile(imageFile, metadata: metadata);
      
      if (image != null) {
        _images.add(image);
        await _saveImagesToPrefs();
        notifyListeners();
      }
      
      return image;
    } catch (e) {
      _loggingService.error(
        'Error adding image from file: $e',
        tag: 'ImageManagerProvider',
        error: e,
      );
      return null;
    }
  }
  
  /// Delete an image
  Future<bool> deleteImage(String imageId) async {
    try {
      final imageIndex = _images.indexWhere((image) => image.id == imageId);
      
      if (imageIndex >= 0) {
        final image = _images[imageIndex];
        final success = await _storageService.deleteImage(image);
        
        if (success) {
          _images.removeAt(imageIndex);
          await _saveImagesToPrefs();
          notifyListeners();
        }
        
        return success;
      }
      
      return false;
    } catch (e) {
      _loggingService.error(
        'Error deleting image: $e',
        tag: 'ImageManagerProvider',
        error: e,
      );
      return false;
    }
  }
  
  /// Get an image by ID
  AppImage? getImageById(String imageId) {
    try {
      return _images.firstWhere((image) => image.id == imageId);
    } catch (e) {
      return null;
    }
  }
}
