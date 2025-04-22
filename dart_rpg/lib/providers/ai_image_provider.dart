import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/app_image.dart';
import '../models/location.dart';
import '../utils/logging_service.dart';

/// A provider for generating images using AI services.
class AiImageProvider extends ChangeNotifier {
  final LoggingService _loggingService = LoggingService();
  
  /// Generate images using the Minimax API.
  /// 
  /// [prompt] - The text prompt to generate images from
  /// [apiKey] - The API key for the Minimax service
  /// [aspectRatio] - The aspect ratio of the generated images (default: "16:9")
  /// [count] - The number of images to generate (default: 3)
  /// [metadata] - Additional metadata to store with the images
  /// 
  /// Returns a list of AppImage objects representing the generated images.
  Future<List<AppImage>> generateImagesWithMinimax({
    required String prompt,
    required String apiKey,
    String aspectRatio = "16:9",
    int count = 3,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _loggingService.info(
        'Generating images with Minimax: prompt="${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}..."',
        tag: 'AiImageProvider',
      );
      
      // Make the API request
      final response = await http.post(
        Uri.parse('https://api.minimaxi.chat/v1/image_generation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'image-01',
          'prompt': prompt,
          'aspect_ratio': aspectRatio,
          'response_format': 'url',
          'n': count,
          'prompt_optimizer': true,
        }),
      );
      
      // Parse the response regardless of status code to check for specific error messages
      final responseData = jsonDecode(response.body);
      
      // Check for specific error conditions
      if (response.statusCode != 200 || 
          (responseData.containsKey('base_resp') && 
           responseData['base_resp']['status_code'] != 0)) {
        
        // Check for insufficient balance error
        if (responseData.containsKey('base_resp') && 
            responseData['base_resp']['status_code'] == 1008) {
          _loggingService.error(
            'Insufficient balance in Minimax account: ${response.body}',
            tag: 'AiImageProvider',
          );
          throw Exception('Insufficient balance in your Minimax account. Please add credits to your account to generate images.');
        }
        
        // General error
        _loggingService.error(
          'Failed to generate images with Minimax: ${response.statusCode} ${response.body}',
          tag: 'AiImageProvider',
        );
        throw Exception('Failed to generate images: ${response.statusCode} ${response.body}');
      }
      
      // Response was successful, continue processing
      
      // Log the full response for debugging
      _loggingService.debug(
        'Minimax API response: ${response.body}',
        tag: 'AiImageProvider',
      );
      
      // Extract the image URLs with proper error handling
      List<dynamic> imageUrls = [];
      
      if (responseData.containsKey('data') && responseData['data'] != null) {
        final data = responseData['data'];
        
        if (data.containsKey('image_urls') && data['image_urls'] != null) {
          imageUrls = data['image_urls'];
        } else if (data is List) {
          // Try the original format where data is a list of objects with url property
          imageUrls = data.map((item) => item['url']).toList();
        } else {
          _loggingService.error(
            'Unexpected response format: image_urls not found in data',
            tag: 'AiImageProvider',
          );
          throw Exception('Unexpected response format: image_urls not found in data');
        }
      } else {
        _loggingService.error(
          'Unexpected response format: data field is null or missing',
          tag: 'AiImageProvider',
        );
        throw Exception('Unexpected response format: data field is null or missing');
      }
      
      _loggingService.debug(
        'Generated ${imageUrls.length} images with Minimax',
        tag: 'AiImageProvider',
      );
      
      // Download and save the images
      final List<AppImage> appImages = [];
      
      for (int i = 0; i < imageUrls.length; i++) {
        final imageUrl = imageUrls[i];
        
        try {
          // Download the image
          final imageResponse = await http.get(Uri.parse(imageUrl));
          
          if (imageResponse.statusCode != 200) {
            _loggingService.error(
              'Failed to download image from $imageUrl: ${imageResponse.statusCode}',
              tag: 'AiImageProvider',
            );
            continue;
          }
          
          // Save the image to a permanent file in the app's documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          final imageId = const Uuid().v4();
          final imagePath = path.join(imagesDir.path, '$imageId.jpg');
          
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(imageResponse.bodyBytes);
          
          // Create an AppImage object
          final appImage = AppImage(
            id: imageId,
            localPath: imagePath,
            originalUrl: imageUrl,
            metadata: {
              'source': 'minimax',
              'prompt': prompt,
              'aspectRatio': aspectRatio,
              'generatedAt': DateTime.now().toIso8601String(),
              ...?metadata,
            },
          );
          
          appImages.add(appImage);
          
          _loggingService.debug(
            'Saved generated image to $imagePath',
            tag: 'AiImageProvider',
          );
        } catch (e) {
          _loggingService.error(
            'Failed to process image from $imageUrl: $e',
            tag: 'AiImageProvider',
            error: e,
          );
        }
      }
      
      return appImages;
    } catch (e) {
      _loggingService.error(
        'Failed to generate images with Minimax: $e',
        tag: 'AiImageProvider',
        error: e,
      );
      rethrow;
    }
  }
  
  /// Generate a context-aware prompt based on the provided object.
  /// 
  /// [contextObject] - The object to generate a prompt from (Character, Location, JournalEntry, etc.)
  /// [contextType] - The type of context object (e.g., "character", "location", "journal")
  /// 
  /// Returns a prompt string that can be used for image generation.
  String generateContextAwarePrompt(dynamic contextObject, String contextType) {
    switch (contextType.toLowerCase()) {
      case 'character':
        return _generateCharacterPrompt(contextObject);
      case 'location':
        return _generateLocationPrompt(contextObject);
      case 'journal':
        return _generateJournalPrompt(contextObject);
      default:
        return _generateGenericPrompt();
    }
  }
  
  /// Generate a prompt for a character.
  String _generateCharacterPrompt(dynamic character) {
    final List<String> promptParts = [];
    
    // Add name
    promptParts.add(character.name);
    
    // Add character type (cyberpunk hacker, etc.)
    promptParts.add("cyberpunk hacker");
    
    // Add physical description from bio if available
    if (character.bio != null && character.bio!.isNotEmpty) {
      promptParts.add(character.bio!);
    }
    
    // Add other details if available (for NPCs)
    if (character.firstLook != null && character.firstLook!.isNotEmpty) {
      promptParts.add(character.firstLook!);
    }
    
    if (character.trademarkAvatar != null && character.trademarkAvatar!.isNotEmpty) {
      promptParts.add("with ${character.trademarkAvatar}");
    }
    
    // Add artistic direction
    promptParts.add("detailed portrait, cyberpunk style, digital art");
    
    return promptParts.join(", ");
  }
  
  /// Generate a prompt for a location.
  String _generateLocationPrompt(dynamic location) {
    final List<String> promptParts = [];
    
    // Add name
    promptParts.add(location.name);
    
    // Add description if available
    if (location.description != null && location.description!.isNotEmpty) {
      promptParts.add(location.description!);
    }
    
    // Add segment information
    String segmentDescription = "digital environment";
    if (location.segment != null) {
      if (location.segment == LocationSegment.core) {
        segmentDescription = "secure digital environment, clean interface";
      } else if (location.segment == LocationSegment.corpNet) {
        segmentDescription = "corporate network, sleek and professional, high security";
      } else if (location.segment == LocationSegment.govNet) {
        segmentDescription = "government system, bureaucratic, heavily monitored";
      } else if (location.segment == LocationSegment.darkNet) {
        segmentDescription = "dark web, chaotic, dangerous digital space";
      }
    }
    promptParts.add(segmentDescription);
    
    // Add artistic direction
    promptParts.add("cyberpunk digital location, detailed illustration");
    
    return promptParts.join(", ");
  }
  
  /// Generate a prompt for a journal entry.
  String _generateJournalPrompt(dynamic entry) {
    final List<String> promptParts = [];
    
    // Remove markdown formatting
    String plainText = entry.content.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // Bold
    plainText = plainText.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // Italic
    plainText = plainText.replaceAll(RegExp(r'#\s(.*)'), r'$1'); // Headings
    plainText = plainText.replaceAll(RegExp(r'!\[(.*?)\]\(.*?\)'), ''); // Images
    
    // Extract first 100-150 words or characters as a summary
    final words = plainText.split(' ');
    final summary = words.take(30).join(' ');
    
    // Add summary
    promptParts.add(summary);
    
    // Add artistic direction
    promptParts.add("cyberpunk scene, digital art, detailed illustration");
    
    return promptParts.join(", ");
  }
  
  /// Generate a generic prompt.
  String _generateGenericPrompt() {
    return "cyberpunk digital scene, detailed illustration, digital art";
  }
}
