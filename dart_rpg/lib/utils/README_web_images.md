# Web Image Handling in DartRPG

## Quick Reference

### Key Files

- `image_utils.dart` - Platform-agnostic interface for image operations
- `web_image_utils_impl.dart` - Web-specific implementation (uses dart:html)
- `web_image_utils_stub.dart` - Stub implementation for non-web platforms

### Key Classes

- `ImageUtils` - Abstract base class with platform detection
- `WebImageUtils` - Basic implementation for web platforms
- `WebImageUtilsImpl` - Full implementation for web platforms (with dart:html)
- `NativeImageUtils` - Implementation for native platforms

## Usage Guidelines

### Displaying Images

Always use conditional logic based on platform:

```dart
if (kIsWeb) {
  // Use Image.network with URL or blob URL
  Image.network(imageUrl)
} else {
  // Use Image.file with File object
  Image.file(File(imagePath))
}
```

### Picking Images

When using the image picker on web:

1. The `XFile.path` is a blob URL, not a file path
2. Store this URL and use it with `Image.network`
3. Pass the URL instead of a File object when saving

```dart
// After picking an image
if (kIsWeb) {
  _selectedImageUrl = pickedFile.path; // Store blob URL
} else {
  _selectedFile = File(pickedFile.path); // Store file
}
```

### Saving Images

For web platforms:

1. Store URLs instead of file paths
2. Use in-memory storage instead of file system
3. For persistence, consider using localStorage or IndexedDB

## Common Pitfalls

1. Using `Image.file` on web platforms
2. Trying to access the file system on web
3. Not handling blob URLs correctly
4. Not providing error handlers for `Image.network`

## For More Information

See the full documentation in `docs/web_image_handling.md`
