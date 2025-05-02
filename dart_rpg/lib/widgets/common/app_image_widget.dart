import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/image_manager_provider.dart';

/// A widget for displaying images from either a URL or local storage.
class AppImageWidget extends StatelessWidget {
  /// The URL of the image to display.
  final String? imageUrl;
  
  /// The ID of the locally stored image to display.
  final String? imageId;
  
  /// The width of the image.
  final double? width;
  
  /// The height of the image.
  final double? height;
  
  /// How to fit the image within its bounds.
  final BoxFit fit;
  
  /// A widget to display while the image is loading.
  final Widget? placeholder;
  
  /// A widget to display if the image fails to load.
  final Widget? errorWidget;

  /// Creates a new AppImageWidget.
  const AppImageWidget({
    super.key,
    this.imageUrl,
    this.imageId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Default placeholder and error widgets
    final defaultPlaceholder = Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final defaultErrorWidget = Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );

    // If we have an imageId, try to load from local storage
    if (imageId != null) {
      return Consumer<ImageManagerProvider>(
        builder: (context, imageManager, _) {
          final image = imageManager.getImageById(imageId!);

          if (image != null) {
            // On web, we can't use Image.file
            if (kIsWeb) {
              // If the image has an original URL, use that
              if (image.originalUrl != null && image.originalUrl!.isNotEmpty) {
                return Image.network(
                  image.originalUrl!,
                  width: width,
                  height: height,
                  fit: fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return placeholder ?? defaultPlaceholder;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return errorWidget ?? defaultErrorWidget;
                  },
                );
              } else if (image.localPath.startsWith('http') || image.localPath.startsWith('blob:')) {
                // If the localPath is actually a URL (which happens on web), use that
                return Image.network(
                  image.localPath,
                  width: width,
                  height: height,
                  fit: fit,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return placeholder ?? defaultPlaceholder;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return errorWidget ?? defaultErrorWidget;
                  },
                );
              } else {
                // No valid URL available
                return errorWidget ?? defaultErrorWidget;
              }
            } else {
              // On native platforms, we can use Image.file
              return Image.file(
                File(image.localPath),
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (context, error, stackTrace) {
                  return errorWidget ?? defaultErrorWidget;
                },
              );
            }
          }

          // Fallback to URL if available
          if (imageUrl != null) {
            return Image.network(
              imageUrl!,
              width: width,
              height: height,
              fit: fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return placeholder ?? defaultPlaceholder;
              },
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ?? defaultErrorWidget;
              },
            );
          }

          // No image available
          return errorWidget ?? defaultErrorWidget;
        },
      );
    }

    // If we only have a URL, load from network
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? defaultPlaceholder;
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? defaultErrorWidget;
        },
      );
    }

    // No image source provided
    return errorWidget ?? defaultErrorWidget;
  }
}
