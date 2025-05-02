import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http_parser/http_parser.dart';
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
    int count = 4,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _loggingService.info(
        'Generating images with Minimax: prompt="${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}..."',
        tag: 'AiImageProvider',
      );
      
      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        'model': 'image-01',
        'prompt': prompt,
        'aspect_ratio': aspectRatio,
        'response_format': 'url',
        'n': count,
        'prompt_optimizer': true,
      };
      
      // Handle subject_reference
      if (metadata != null) {
        // Direct subject_reference (URL-based)
        if (metadata.containsKey('subject_reference')) {
          requestBody['subject_reference'] = metadata['subject_reference'];
          _loggingService.debug(
            'Including subject_reference in Minimax request: ${metadata['subject_reference']}',
            tag: 'AiImageProvider',
          );
        }
        // Local file-based subject_reference
        else if (metadata.containsKey('subject_reference_file_path') && 
                 metadata.containsKey('subject_reference_character_id')) {
          final filePath = metadata['subject_reference_file_path'];
          final characterId = metadata['subject_reference_character_id'];
          
          try {
            // Read the file and convert to base64
            final file = File(filePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Image = base64Encode(bytes);
              final base64String = 'data:image/jpeg;base64,$base64Image';
              
              // Add to request body
              requestBody['subject_reference'] = [{
                'type': 'character',
                'image_file': base64String
              }];
              
              _loggingService.debug(
                'Including base64 subject_reference for character: $characterId',
                tag: 'AiImageProvider',
              );
            } else {
              _loggingService.warning(
                'Subject reference file does not exist: $filePath',
                tag: 'AiImageProvider',
              );
            }
          } catch (e) {
            _loggingService.error(
              'Failed to process subject reference file: $e',
              tag: 'AiImageProvider',
              error: e,
            );
          }
        }
      }
      
      // Make the API request
      final response = await http.post(
        Uri.parse('https://api.minimaxi.chat/v1/image_generation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
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
  /// [game] - The game object containing settings like artistic direction
  /// 
  /// Returns a prompt string that can be used for image generation.
  String generateContextAwarePrompt(dynamic contextObject, String contextType, dynamic game) {
    switch (contextType.toLowerCase()) {
      case 'character':
        return _generateCharacterPrompt(contextObject, game);
      case 'location':
        return _generateLocationPrompt(contextObject, game);
      case 'journal':
        return _generateJournalPrompt(contextObject, game);
      default:
        return _generateGenericPrompt(game);
    }
  }
  
  /// Generate a prompt for a character.
  String _generateCharacterPrompt(dynamic character, dynamic game) {
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
    
    // Add artistic direction from game settings
    String artisticDirection = "detailed portrait, cyberpunk style, digital art";
    if (game != null && 
        game.aiImageProvider != null && 
        game.aiArtisticDirections.containsKey(game.aiImageProvider)) {
      artisticDirection = game.getAiArtisticDirectionOrDefault();
    }
    promptParts.add(artisticDirection);
    
    return promptParts.join(", ");
  }
  
  /// Generate a prompt for a location.
  String _generateLocationPrompt(dynamic location, dynamic game) {
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
    
    // Add artistic direction from game settings
    String artisticDirection = "cyberpunk digital location, detailed illustration";
    if (game != null && 
        game.aiImageProvider != null && 
        game.aiArtisticDirections.containsKey(game.aiImageProvider)) {
      artisticDirection = game.getAiArtisticDirectionOrDefault();
    }
    promptParts.add(artisticDirection);
    
    return promptParts.join(", ");
  }
  
  /// Generate a prompt for a journal entry.
  String _generateJournalPrompt(dynamic entry, dynamic game) {
    final List<String> promptParts = [];
    
    // Remove markdown formatting more comprehensively
    String plainText = entry.content;
    
    // Remove bold formatting
    plainText = plainText.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    
    // Remove italic formatting
    plainText = plainText.replaceAll(RegExp(r'\*(.*?)\*'), r'$1');
    
    // Remove heading formatting (all levels)
    plainText = plainText.replaceAll(RegExp(r'#{1,6}\s(.*)'), r'$1');
    
    // Remove images
    plainText = plainText.replaceAll(RegExp(r'!\[(.*?)\]\(.*?\)'), '');
    
    // Remove links but keep the text
    plainText = plainText.replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');
    
    // Remove bullet points and numbered lists
    plainText = plainText.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    plainText = plainText.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    
    // Remove blockquotes
    plainText = plainText.replaceAll(RegExp(r'^\s*>\s+', multiLine: true), '');
    
    // Remove code blocks
    plainText = plainText.replaceAll(RegExp(r'```.*?```', dotAll: true), '');
    plainText = plainText.replaceAll(RegExp(r'`(.*?)`'), r'$1');
    
    // Remove horizontal rules
    plainText = plainText.replaceAll(RegExp(r'^\s*[-*_]{3,}\s*$', multiLine: true), '');
    
    // Remove extra whitespace and normalize
    plainText = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Extract first 100-150 words or characters as a summary
    final words = plainText.split(' ');
    final summary = words.take(30).join(' ');
    
    // Add summary
    promptParts.add(summary);
    
    // Add artistic direction from game settings
    String artisticDirection = "cyberpunk scene, digital art, detailed illustration";
    if (game != null && 
        game.aiImageProvider != null && 
        game.aiArtisticDirections.containsKey(game.aiImageProvider)) {
      artisticDirection = game.getAiArtisticDirectionOrDefault();
    }
    promptParts.add(artisticDirection);
    
    return promptParts.join(", ");
  }
  
  /// Generate a generic prompt.
  String _generateGenericPrompt(dynamic game) {
    if (game != null && 
        game.aiImageProvider != null && 
        game.aiArtisticDirections.containsKey(game.aiImageProvider)) {
      return game.getAiArtisticDirectionOrDefault();
    }
    return "cyberpunk digital scene, detailed illustration, digital art";
  }
  
  /// Generate images using the OpenAI API.
  /// 
  /// [prompt] - The text prompt to generate images from
  /// [apiKey] - The API key for the OpenAI service
  /// [model] - The OpenAI model to use (dall-e-2, dall-e-3, or gpt-image-1)
  /// [size] - The size of the generated images (default depends on model)
  /// [count] - The number of images to generate (default: 1)
  /// [metadata] - Additional metadata to store with the images
  /// [referenceImage] - Optional reference image for image editing (for journal entries with character reference)
  /// 
  /// Returns a list of AppImage objects representing the generated images.
  Future<List<AppImage>> generateImagesWithOpenAI({
    required String prompt,
    required String apiKey,
    required String model,
    String? size,
    int count = 1,
    String? moderationLevel,
    Map<String, dynamic>? metadata,
    File? referenceImage,
  }) async {
    try {
      // Validate and normalize model name
      final String normalizedModel = model.toLowerCase().trim();
      
      // Validate model name
      if (!['dall-e-2', 'dall-e-3', 'gpt-image-1'].contains(normalizedModel)) {
        throw Exception('Invalid OpenAI model: $normalizedModel. Supported models are: dall-e-2, dall-e-3, gpt-image-1');
      }
      
      // Log the request
      _loggingService.info(
        'Generating images with OpenAI: model=$normalizedModel, prompt="${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}..."',
        tag: 'AiImageProvider',
      );
      
      // Determine if we're using the standard generation endpoint or the edit endpoint
      final bool useEditEndpoint = referenceImage != null && await referenceImage.exists();
      
      // Set default size based on model if not provided
      String effectiveSize = size ?? _getDefaultSizeForModel(normalizedModel);
      
      // Validate size parameter for each model
      if (normalizedModel == 'dall-e-2') {
        // DALL-E 2 supports 256x256, 512x512, or 1024x1024
        if (!['256x256', '512x512', '1024x1024'].contains(effectiveSize)) {
          _loggingService.warning(
            'Invalid size for DALL-E 2: $effectiveSize. Using default: 1024x1024',
            tag: 'AiImageProvider',
          );
          effectiveSize = '1024x1024';
        }
      } else if (normalizedModel == 'dall-e-3') {
        // DALL-E 3 supports 1024x1024, 1792x1024, or 1024x1792
        if (!['1024x1024', '1792x1024', '1024x1792'].contains(effectiveSize)) {
          _loggingService.warning(
            'Invalid size for DALL-E 3: $effectiveSize. Using default: 1024x1024',
            tag: 'AiImageProvider',
          );
          effectiveSize = '1024x1024';
        }
      } else if (normalizedModel == 'gpt-image-1') {
        // GPT-Image-1 only supports "auto" size
        effectiveSize = 'auto';
      }
      
      // Adjust count based on model limitations
      int effectiveCount = count;
      if (normalizedModel == 'dall-e-3' && effectiveCount > 1) {
        _loggingService.warning(
          'DALL-E 3 only supports generating 1 image at a time. Adjusting count from $effectiveCount to 1.',
          tag: 'AiImageProvider',
        );
        effectiveCount = 1;
      } else if (normalizedModel == 'dall-e-2' && effectiveCount > 10) {
        _loggingService.warning(
          'DALL-E 2 supports up to 10 images at a time. Adjusting count from $effectiveCount to 10.',
          tag: 'AiImageProvider',
        );
        effectiveCount = 10;
      } else if (normalizedModel == 'gpt-image-1' && effectiveCount > 4) {
        _loggingService.warning(
          'GPT-Image-1 supports up to 4 images at a time. Adjusting count from $effectiveCount to 4.',
          tag: 'AiImageProvider',
        );
        effectiveCount = 4;
      }
      
      // Prepare headers
      final Map<String, String> headers = {
        'Authorization': 'Bearer $apiKey',
      };
      
      List<dynamic> imageUrls = [];
      List<String> base64Images = [];
      
      if (useEditEndpoint) {
        // Use the image edit endpoint
        _loggingService.debug(
          'Using OpenAI image edit endpoint with reference image',
          tag: 'AiImageProvider',
        );
        
        // Create a multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.openai.com/v1/images/edits'),
        );
        
        // Add headers
        request.headers.addAll(headers);
        
        // Add fields
        request.fields['model'] = normalizedModel;
        request.fields['prompt'] = prompt;
        request.fields['n'] = effectiveCount.toString();
        
        // Only add size for models that support it
        if (normalizedModel != 'gpt-image-1') {
          request.fields['size'] = effectiveSize;
        }
        
        // Add moderation only for gpt-image-1
        if (normalizedModel == 'gpt-image-1' && moderationLevel != null) {
          request.fields['moderation'] = moderationLevel;
        }
        
        // Add the image file
        final imageBytes = await referenceImage!.readAsBytes();
        final imageField = http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'reference.png',
          contentType: MediaType('image', 'png'),
        );
        request.files.add(imageField);
        
        // Send the request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        // Parse the response
        if (response.statusCode != 200) {
          _loggingService.error(
            'Failed to generate images with OpenAI: ${response.statusCode} ${response.body}',
            tag: 'AiImageProvider',
          );
          
          // Check for specific error conditions
          final responseData = jsonDecode(response.body);
          if (responseData.containsKey('error')) {
            final error = responseData['error'];
            if (error.containsKey('code') && error['code'] == 'insufficient_quota') {
              throw Exception('Insufficient credits in your OpenAI account. Please add credits to your account to generate images.');
            }
          }
          
          throw Exception('Failed to generate images: ${response.statusCode} ${response.body}');
        }
        
        // Parse the response
        final responseData = jsonDecode(response.body);
        
        // Log the full response for debugging
        _loggingService.debug(
          'OpenAI API response: ${response.body}',
          tag: 'AiImageProvider',
        );
        
        // Extract the image data
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final data = responseData['data'];
          
          if (data is List) {
            // Check if the response contains URLs or base64 data
            if (data.isNotEmpty && data[0].containsKey('url')) {
              imageUrls = data.map((item) => item['url']).toList();
            } else if (data.isNotEmpty && data[0].containsKey('b64_json')) {
              base64Images = data.map((item) => item['b64_json'] as String).toList();
            } else {
              _loggingService.error(
                'Unexpected response format: neither url nor b64_json found in data',
                tag: 'AiImageProvider',
              );
              throw Exception('Unexpected response format: neither url nor b64_json found in data');
            }
          } else {
            _loggingService.error(
              'Unexpected response format: data is not a list',
              tag: 'AiImageProvider',
            );
            throw Exception('Unexpected response format: data is not a list');
          }
        } else {
          _loggingService.error(
            'Unexpected response format: data field is null or missing',
            tag: 'AiImageProvider',
          );
          throw Exception('Unexpected response format: data field is null or missing');
        }
      } else {
        // Use the standard image generation endpoint
        _loggingService.debug(
          'Using OpenAI standard image generation endpoint',
          tag: 'AiImageProvider',
        );
        
        // Prepare the request body
        final Map<String, dynamic> requestBody = {
          'model': normalizedModel,
          'prompt': prompt,
          'n': effectiveCount,
        };
        
        // Only add size for models that support it
        if (normalizedModel != 'gpt-image-1') {
          requestBody['size'] = effectiveSize;
        }
        
        // Add moderation level for gpt-image-1 if provided
        if (normalizedModel == 'gpt-image-1' && moderationLevel != null) {
          requestBody['moderation'] = moderationLevel;
        }
        
        // Log the request body for debugging
        _loggingService.debug(
          'OpenAI request body: ${jsonEncode(requestBody)}',
          tag: 'AiImageProvider',
        );
        
        // Add content type header for JSON request
        headers['Content-Type'] = 'application/json';
        
        // Make the API request
        final response = await http.post(
          Uri.parse('https://api.openai.com/v1/images/generations'),
          headers: headers,
          body: jsonEncode(requestBody),
        );
        
        // Parse the response
        if (response.statusCode != 200) {
          _loggingService.error(
            'Failed to generate images with OpenAI: ${response.statusCode} ${response.body}',
            tag: 'AiImageProvider',
          );
          
          // Check for specific error conditions
          final responseData = jsonDecode(response.body);
          if (responseData.containsKey('error')) {
            final error = responseData['error'];
            if (error.containsKey('code') && error['code'] == 'insufficient_quota') {
              throw Exception('Insufficient credits in your OpenAI account. Please add credits to your account to generate images.');
            }
          }
          
          throw Exception('Failed to generate images: ${response.statusCode} ${response.body}');
        }
        
        // Parse the response
        final responseData = jsonDecode(response.body);
        
        // Log the full response for debugging
        _loggingService.debug(
          'OpenAI API response: ${response.body}',
          tag: 'AiImageProvider',
        );
        
        // Extract the image data
        if (responseData.containsKey('data') && responseData['data'] != null) {
          final data = responseData['data'];
          
          if (data is List) {
            // Check if the response contains URLs or base64 data
            if (data.isNotEmpty && data[0].containsKey('url')) {
              imageUrls = data.map((item) => item['url']).toList();
            } else if (data.isNotEmpty && data[0].containsKey('b64_json')) {
              base64Images = data.map((item) => item['b64_json'] as String).toList();
            } else {
              _loggingService.error(
                'Unexpected response format: neither url nor b64_json found in data',
                tag: 'AiImageProvider',
              );
              throw Exception('Unexpected response format: neither url nor b64_json found in data');
            }
          } else {
            _loggingService.error(
              'Unexpected response format: data is not a list',
              tag: 'AiImageProvider',
            );
            throw Exception('Unexpected response format: data is not a list');
          }
        } else {
          _loggingService.error(
            'Unexpected response format: data field is null or missing',
            tag: 'AiImageProvider',
          );
          throw Exception('Unexpected response format: data field is null or missing');
        }
      }
      
      _loggingService.debug(
        'Generated ${imageUrls.length} URL images and ${base64Images.length} base64 images with OpenAI',
        tag: 'AiImageProvider',
      );
      
      // Download and save the images
      final List<AppImage> appImages = [];
      
      // Process URL-based images
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
              'source': 'openai',
              'model': normalizedModel,
              'prompt': prompt,
              'size': effectiveSize,
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
      
      // Process base64-encoded images
      for (int i = 0; i < base64Images.length; i++) {
        try {
          // Decode the base64 image
          final imageBytes = base64Decode(base64Images[i]);
          
          // Save the image to a permanent file in the app's documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final imagesDir = Directory('${appDir.path}/images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          
          final imageId = const Uuid().v4();
          final imagePath = path.join(imagesDir.path, '$imageId.jpg');
          
          final imageFile = File(imagePath);
          await imageFile.writeAsBytes(imageBytes);
          
          // Create an AppImage object
          final appImage = AppImage(
            id: imageId,
            localPath: imagePath,
            metadata: {
              'source': 'openai',
              'model': normalizedModel,
              'prompt': prompt,
              'size': effectiveSize,
              'generatedAt': DateTime.now().toIso8601String(),
              ...?metadata,
            },
          );
          
          appImages.add(appImage);
          
          _loggingService.debug(
            'Saved generated base64 image to $imagePath',
            tag: 'AiImageProvider',
          );
        } catch (e) {
          _loggingService.error(
            'Failed to process base64 image: $e',
            tag: 'AiImageProvider',
            error: e,
          );
        }
      }
      
      return appImages;
    } catch (e) {
      _loggingService.error(
        'Failed to generate images with OpenAI: $e',
        tag: 'AiImageProvider',
        error: e,
      );
      rethrow;
    }
  }
  
  /// Get the default size for the specified OpenAI model.
  String _getDefaultSizeForModel(String model) {
    switch (model) {
      case 'dall-e-2':
        return '1024x1024';
      case 'dall-e-3':
        return '1024x1024';
      case 'gpt-image-1':
        return 'auto';
      default:
        return '1024x1024';
    }
  }
  
  /// Get the maximum number of images that can be generated for the specified OpenAI model.
  int _getMaxImagesForModel(String model) {
    switch (model) {
      case 'dall-e-2':
        return 10;
      case 'dall-e-3':
        return 1;
      case 'gpt-image-1':
        return 4;
      default:
        return 1;
    }
  }
}
