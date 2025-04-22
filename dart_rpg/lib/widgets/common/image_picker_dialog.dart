import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/image_manager_provider.dart';

/// A dialog for picking images from different sources.
class ImagePickerDialog extends StatefulWidget {
  /// The initial image URL.
  final String? initialImageUrl;
  
  /// The initial image ID.
  final String? initialImageId;

  /// Creates a new ImagePickerDialog.
  const ImagePickerDialog({
    super.key,
    this.initialImageUrl,
    this.initialImageId,
  });

  /// Shows the image picker dialog and returns the selected image info.
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialImageUrl,
    String? initialImageId,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ImagePickerDialog(
        initialImageUrl: initialImageUrl,
        initialImageId: initialImageId,
      ),
    );
  }

  @override
  State<ImagePickerDialog> createState() => _ImagePickerDialogState();
}

class _ImagePickerDialogState extends State<ImagePickerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  String? _selectedImageId;
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    super.dispose();
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedImageId = null; // Clear selected saved image
        });
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
          onPressed: () {
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
              Navigator.pop(context, {
                'type': 'file',
                'file': _selectedFile,
              });
            } else if (activeTab == 2 && _selectedImageId != null) {
              // Saved tab
              Navigator.pop(context, {
                'type': 'saved',
                'imageId': _selectedImageId,
              });
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
              child: Image.file(
                _selectedFile!,
                fit: BoxFit.contain,
              ),
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
                child: Image.file(
                  File(image.localPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
