import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart' as picker;
import '../../models/app_image.dart';
import '../../models/journal_entry.dart';
import '../../providers/ai_image_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/image_manager_provider.dart';
import '../../utils/logging_service.dart';

/// A dialog for picking images from different sources.
class ImagePickerDialog extends StatefulWidget {
  /// The initial image URL.
  final String? initialImageUrl;
  
  /// The initial image ID.
  final String? initialImageId;
  
  /// The context object for AI image generation (e.g., Character, Location, JournalEntry).
  final dynamic contextObject;
  
  /// The context type for AI image generation (e.g., "character", "location", "journal").
  final String? contextType;

  /// Creates a new ImagePickerDialog.
  const ImagePickerDialog({
    super.key,
    this.initialImageUrl,
    this.initialImageId,
    this.contextObject,
    this.contextType,
  });

  /// Shows the image picker dialog and returns the selected image info.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialImageUrl,
    String? initialImageId,
    dynamic contextObject,
    String? contextType,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImagePickerDialog(
        initialImageUrl: initialImageUrl,
        initialImageId: initialImageId,
        contextObject: contextObject,
        contextType: contextType,
      ),
    );
  }

  @override
  State<ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<ImagePickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  String? _selectedImageId;
  File? _selectedFile;
  String? _selectedImageUrl; // URL for web platforms
  AppImage? _selectedAiImage;
  List<AppImage> _generatedImages = [];
  bool _isGeneratingImages = false;
  String? _generationError;
  final LoggingService _loggingService = LoggingService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize with existing values if provided
    if (widget.initialImageUrl != null) {
      _urlController.text = widget.initialImageUrl!;
    }

    if (widget.initialImageId != null) {
      _selectedImageId = widget.initialImageId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final imagePicker = picker.ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: picker.ImageSource.gallery);

      if (pickedFile != null) {
        if (kIsWeb) {
          // On web, we need to handle the file differently
          // The path is actually a blob URL that we can use directly
          setState(() {
            _selectedFile = File(''); // Dummy file for web
            _selectedImageUrl = pickedFile.path; // Store the blob URL
            _selectedImageId = null; // Clear selected saved image
          });
        } else {
          // On native platforms, we can use the file directly
          setState(() {
            _selectedFile = File(pickedFile.path);
            _selectedImageUrl = null; // Clear any previous URL
            _selectedImageId = null; // Clear selected saved image
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Image'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'URL'),
                Tab(text: 'Gallery'),
                Tab(text: 'Saved'),
                Tab(text: 'AI'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // URL Tab
                  _buildUrlTab(),

                  // Gallery Tab
                  _buildGalleryTab(),

                  // Saved Tab
                  _buildSavedTab(),
                  
                  // AI Tab
                  _buildAiTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Return the selected image info based on the active tab
            final activeTab = _tabController.index;

            if (activeTab == 0 && _urlController.text.isNotEmpty) {
              // URL tab
              Navigator.pop(context, {
                'type': 'url',
                'url': _urlController.text,
              });
            } else if (activeTab == 1 && _selectedFile != null) {
              // Gallery tab
              if (kIsWeb && _selectedImageUrl != null) {
                // On web, return the URL instead of the file
                Navigator.pop(context, {
                  'type': 'url',
                  'url': _selectedImageUrl,
                });
              } else {
                // On native platforms, return the file
                Navigator.pop(context, {
                  'type': 'file',
                  'file': _selectedFile,
                });
              }
            } else if (activeTab == 2 && _selectedImageId != null) {
              // Saved tab
              Navigator.pop(context, {
                'type': 'saved',
                'imageId': _selectedImageId,
              });
            } else if (activeTab == 3 && _selectedAiImage != null) {
              // AI tab - Ensure the image is saved to permanent storage
              final imageManagerProvider = Provider.of<ImageManagerProvider>(context, listen: false);
              
              // Check if the image is already in the image manager
              final existingImage = imageManagerProvider.getImageById(_selectedAiImage!.id);
              
              if (existingImage != null) {
                // Image is already saved, just return the ID
                Navigator.pop(context, {
                  'type': 'saved',  // Use 'saved' type since it's now in permanent storage
                  'imageId': existingImage.id,
                });
              } else {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Saving image...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                // Save the image to permanent storage
                AppImage? savedImage;
                
                if (!kIsWeb) {
                  // On non-web platforms, we can use File
                  final imageFile = File(_selectedAiImage!.localPath);
                  savedImage = await imageManagerProvider.addImageFromFile(
                    imageFile,
                    metadata: _selectedAiImage!.metadata,
                  );
                } else {
                  // On web, we can't use File, so we'll just use the existing image
                  // This is a workaround since we can't create a File from a path on web
                  savedImage = _selectedAiImage;
                }
                
                if (savedImage != null) {
                  Navigator.pop(context, {
                    'type': 'saved',  // Use 'saved' type since it's now in permanent storage
                    'imageId': savedImage.id,
                  });
                } else {
                  // Failed to save image
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save image'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              // No valid selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select an image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  /// Build the URL tab
  Widget _buildUrlTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://example.com/image.jpg',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_urlController.text.isNotEmpty)
            Expanded(
              child: Image.network(
                _urlController.text,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Invalid image URL'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Build the Gallery tab
  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Pick from Gallery'),
            onPressed: _pickImage,
          ),
          const SizedBox(height: 16),
          if (_selectedFile != null)
            Expanded(
              child: _buildImagePreview(_selectedFile),
            ),
        ],
      ),
    );
  }

  /// Build the Saved tab
  Widget _buildSavedTab() {
    return Consumer<ImageManagerProvider>(
      builder: (context, imageManager, _) {
        if (imageManager.images.isEmpty) {
          return const Center(
            child: Text('No saved images'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: imageManager.images.length,
          itemBuilder: (context, index) {
            final image = imageManager.images[index];
            final isSelected = image.id == _selectedImageId;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageId = image.id;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 3.0,
                  ),
                ),
                child: _buildAppImagePreview(image, isSelected),
              ),
            );
          },
        );
      },
    );
  }
  
  /// Build the AI tab
  Widget _buildAiTab() {
    // Get the game provider to check if AI image generation is available
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final aiImageProvider = Provider.of<AiImageProvider>(context, listen: false);
    
    // Check if AI image generation is available
    final isAiAvailable = gameProvider.isAiImageGenerationAvailable();
    
    if (!isAiAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'AI Image Generation is not available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'To use this feature, you need to enable AI Image Generation in the Game Settings and configure an API key.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Go to Settings'),
                onPressed: () {
                  // Close the dialog
                  Navigator.pop(context);
                  
                  // Navigate to the Game Settings screen
                  Navigator.pushNamed(context, '/game_settings');
                },
              ),
            ],
          ),
        ),
      );
    }
    
    // Generate a context-aware prompt if contextObject and contextType are provided
    if (_promptController.text.isEmpty && widget.contextObject != null && widget.contextType != null) {
      _promptController.text = aiImageProvider.generateContextAwarePrompt(
        widget.contextObject,
        widget.contextType!,
        gameProvider.currentGame,
      );
    }
    
    // Check if there's a referenced character ID in the context object
    String? referencedCharacterId;
    if (widget.contextObject is JournalEntry && widget.contextObject.linkedCharacterIds.isNotEmpty) {
      referencedCharacterId = widget.contextObject.linkedCharacterIds.first;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt input
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              labelText: 'Prompt',
              hintText: 'Describe the image you want to generate',
              border: OutlineInputBorder(),
            ),
            maxLines: 2, // Reduced from 3 to 2 to save space
          ),
          
          const SizedBox(height: 8), // Reduced from 16 to 8
          
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Images'),
              onPressed: _isGeneratingImages ? null : () => _generateImages(context),
            ),
          ),
          
          const SizedBox(height: 8), // Reduced from 16 to 8
          
          // Loading indicator or error message
          if (_isGeneratingImages)
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Generating...'),
                ],
              ),
            )
          else if (_generationError != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _generationError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Generated images
          if (_generatedImages.isNotEmpty) ...[
            const SizedBox(height: 8), // Reduced from 16 to 8
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Generated Images',
                  style: TextStyle(
                    fontSize: 14, // Reduced from 16 to 14
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Select an image',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // Reduced from 8 to 4
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0, // Ensure square cells
                ),
                itemCount: _generatedImages.length,
                itemBuilder: (context, index) {
                  final image = _generatedImages[index];
                  final isSelected = _selectedAiImage?.id == image.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAiImage = image;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _buildAppImagePreview(image, isSelected),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Build an image preview for a File
  Widget _buildImagePreview(File? file) {
    if (file == null) return const SizedBox();
    
    if (kIsWeb) {
      // On web, we can't use Image.file directly
      // Instead, we use the URL we stored when picking the image
      if (_selectedImageUrl != null) {
        return Image.network(
          _selectedImageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        // No URL available yet
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'Image selected',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // On native platforms, we can use Image.file
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image),
          );
        },
      );
    }
  }
  
  /// Build an image preview for an AppImage
  Widget _buildAppImagePreview(AppImage image, bool isSelected) {
    if (kIsWeb) {
      // On web, we try to use the original URL if available
      if (image.originalUrl != null && image.originalUrl!.isNotEmpty) {
        return Image.network(
          image.originalUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400],
              ),
            );
          },
        );
      } else {
        // If no URL is available, show an icon
        return Center(
          child: Icon(
            Icons.image,
            size: 40,
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[400],
          ),
        );
      }
    } else {
      // On native platforms, we can use Image.file
      return Image.file(
        File(image.localPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image),
          );
        },
      );
    }
  }
  
  /// Generate images using the AI provider
  Future<void> _generateImages(BuildContext context) async {
    // Get the game provider and AI image provider
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final aiImageProvider = Provider.of<AiImageProvider>(context, listen: false);
    final imageManagerProvider = Provider.of<ImageManagerProvider>(context, listen: false);
    
    // Check if the prompt is empty
    if (_promptController.text.isEmpty) {
      setState(() {
        _generationError = 'Please enter a prompt';
      });
      return;
    }
    
    // Get the API key and provider
    final provider = gameProvider.currentGame!.aiImageProvider;
    final apiKey = gameProvider.currentGame!.getAiApiKey(provider!);
    
    if (apiKey == null) {
      setState(() {
        _generationError = 'API key not found';
      });
      return;
    }
    
    // Clear any previous error
    setState(() {
      _isGeneratingImages = true;
      _generationError = null;
    });
    
    try {
      // Generate images
      List<AppImage> generatedImages;
      
      // Check if there's a referenced character ID in the context object
      String? referencedCharacterId;
      if (widget.contextObject is JournalEntry && widget.contextObject.linkedCharacterIds.isNotEmpty) {
        referencedCharacterId = widget.contextObject.linkedCharacterIds.first;
      }
      
      // Get the character if available
      dynamic referencedCharacter;
      if (referencedCharacterId != null) {
        try {
          referencedCharacter = gameProvider.currentGame!.characters.firstWhere(
            (c) => c.id == referencedCharacterId
          );
        } catch (e) {
          // Character not found, ignore
        }
      }
      
      // Create metadata with subject reference if character has an image
      Map<String, dynamic> metadata = {
        'usage': 'ai_generated',
        'prompt': _promptController.text,
      };
      
      if (provider == 'minimax') {
        // Add subject_reference if character has an image
        if (referencedCharacter != null) {
          String? imageUrl;
          String? imagePath;
          
          // Check if character has a URL-based image
          if (referencedCharacter.imageUrl != null && referencedCharacter.imageUrl!.isNotEmpty) {
            imageUrl = referencedCharacter.imageUrl;
            
            // Add subject_reference with URL
            metadata['subject_reference'] = [{
              'type': 'character',
              'image_file': imageUrl
            }];
            
            _loggingService.debug(
              'Using character image URL for subject_reference: $imageUrl',
              tag: 'ImagePickerDialog',
            );
          } 
          // Check if character has a local image
          else if (referencedCharacter.imageId != null && referencedCharacter.imageId!.isNotEmpty) {
            // Get the image from the image manager
            final imageManagerProvider = Provider.of<ImageManagerProvider>(context, listen: false);
            final image = imageManagerProvider.getImageById(referencedCharacter.imageId!);
            
            if (image != null) {
              imagePath = image.localPath;
              
              // Add subject_reference with local file path
              metadata['subject_reference_file_path'] = imagePath;
              metadata['subject_reference_character_id'] = referencedCharacterId;
              
              _loggingService.debug(
                'Using character image file for subject_reference: $imagePath',
                tag: 'ImagePickerDialog',
              );
            }
          }
        }
        
        generatedImages = await aiImageProvider.generateImagesWithMinimax(
          prompt: _promptController.text,
          apiKey: apiKey,
          metadata: metadata,
        );
      } else if (provider == 'openai') {
        // Get the OpenAI model from the game settings
        final openaiModel = gameProvider.currentGame!.openaiModel ?? 'dall-e-2';
        
        // Add model to metadata
        metadata['model'] = openaiModel;
        
        // Prepare reference image for image editing if available
        File? referenceImage;
        if (!kIsWeb && referencedCharacter != null && referencedCharacter.imageId != null) {
          // Get the image from the image manager
          final image = imageManagerProvider.getImageById(referencedCharacter.imageId!);
          if (image != null) {
            referenceImage = File(image.localPath);
            
            _loggingService.debug(
              'Using character image file for OpenAI reference image: ${image.localPath}',
              tag: 'ImagePickerDialog',
            );
          }
        }
        
        // Set moderation level for gpt-image-1
        String? moderationLevel;
        if (openaiModel == 'gpt-image-1') {
          moderationLevel = 'low'; // Default to low moderation
        }
        
        // Generate images with OpenAI
        generatedImages = await aiImageProvider.generateImagesWithOpenAI(
          prompt: _promptController.text,
          apiKey: apiKey,
          model: openaiModel,
          moderationLevel: moderationLevel,
          referenceImage: referenceImage,
          metadata: metadata,
        );
      } else {
        throw Exception('Unsupported provider: $provider');
      }
      
      // Save the generated images to the ImageManagerProvider and keep track of the saved images
      final List<AppImage> savedImages = [];
      
      for (final image in generatedImages) {
        AppImage? savedImage;
        
        if (!kIsWeb) {
          // On non-web platforms, we can use File
          savedImage = await imageManagerProvider.addImageFromFile(
            File(image.localPath),
            metadata: image.metadata,
          );
        } else {
          // On web, we can't use File, so we'll just use the existing image
          savedImage = image;
        }
        
        if (savedImage != null) {
          savedImages.add(savedImage);
        }
      }
      
      // Update the state with the saved images
      setState(() {
        _generatedImages = savedImages.isNotEmpty ? savedImages : generatedImages;
        _isGeneratingImages = false;
        
        // Select the first image by default
        if (_generatedImages.isNotEmpty) {
          _selectedAiImage = _generatedImages.first;
        }
      });
    } catch (e) {
      setState(() {
        _isGeneratingImages = false;
        _generationError = 'Failed to generate images: ${e.toString()}';
      });
    }
  }
}
