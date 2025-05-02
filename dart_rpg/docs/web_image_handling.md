# Web Image Handling in DartRPG

This document outlines how images are handled in the DartRPG application when running on web platforms, and the requirements for displaying images correctly.

## Background

Flutter's approach to handling images differs between web and native platforms:

- On native platforms (Android, iOS, desktop), we can use `File` objects and `Image.file` to display images from the local file system.
- On web platforms, `Image.file` is not supported because web browsers don't have direct access to the file system. Instead, we must use `Image.network` with URLs (including blob URLs).

## Implementation

### Core Components

1. **ImageUtils Class**
   - Located in `lib/utils/image_utils.dart`
   - Provides a platform-agnostic interface for image operations
   - Uses factory pattern to return the appropriate implementation based on platform

2. **Web-specific Implementation**
   - Located in `lib/utils/web_image_utils_impl.dart`
   - Handles web-specific image operations using blob URLs
   - Only imported on web platforms

3. **ImageStorageService**
   - Uses in-memory storage for web platforms instead of file system storage
   - Stores URLs instead of file paths for web platforms

4. **ImageManagerProvider**
   - Skips file existence checks on web platforms
   - Handles web-specific image storage and retrieval

5. **AppImageWidget**
   - Uses `Image.network` instead of `Image.file` on web platforms
   - Handles different image sources (URL, file, saved) appropriately based on platform

6. **ImagePickerDialog**
   - Stores blob URLs for selected images on web platforms
   - Displays images using the appropriate widget based on platform

## Requirements for Web Image Display

When displaying images on web platforms, the following requirements must be met:

1. **Never use `Image.file`**
   - Always check `kIsWeb` before using `Image.file`
   - Use `Image.network` instead on web platforms

2. **Handle Blob URLs**
   - When using the image picker on web, the `XFile.path` is actually a blob URL
   - Store this URL and use it with `Image.network` to display the image

3. **URL-based Storage**
   - Store image URLs instead of file paths on web platforms
   - For uploaded images, use the blob URL provided by the image picker
   - For saved images, use the original URL if available

4. **Error Handling**
   - Always provide an `errorBuilder` for `Image.network` to handle loading failures
   - Consider providing a `loadingBuilder` to show a loading indicator

## Example Usage

### Displaying an Image

```dart
Widget buildImageWidget(AppImage image) {
  if (kIsWeb) {
    // On web, use Image.network with the URL
    String? imageUrl;
    
    if (image.originalUrl != null && image.originalUrl!.isNotEmpty) {
      imageUrl = image.originalUrl;
    } else if (image.localPath.startsWith('blob:') || image.localPath.startsWith('http')) {
      imageUrl = image.localPath;
    }
    
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(child: Icon(Icons.broken_image));
        },
      );
    } else {
      return const Center(child: Icon(Icons.image_not_supported));
    }
  } else {
    // On native platforms, use Image.file
    return Image.file(
      File(image.localPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image));
      },
    );
  }
}
```

### Picking an Image

```dart
Future<void> pickImage() async {
  final imagePicker = ImagePicker();
  final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    if (kIsWeb) {
      // On web, store the blob URL
      setState(() {
        _selectedImageUrl = pickedFile.path;
      });
    } else {
      // On native platforms, use the file path
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }
}
```

## Limitations

1. **No File System Access**
   - Web browsers don't allow direct access to the file system
   - All file operations must use the browser's APIs (FileReader, Blob, etc.)

2. **Temporary URLs**
   - Blob URLs are temporary and may be invalidated when the page is refreshed
   - Consider converting images to base64 for more persistent storage

3. **Cross-Origin Restrictions**
   - Web browsers enforce cross-origin restrictions
   - Images from external domains may require CORS headers

4. **Performance Considerations**
   - Large images may impact performance on web platforms
   - Consider implementing image resizing/optimization for web
