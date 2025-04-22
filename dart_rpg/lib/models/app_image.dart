import 'package:uuid/uuid.dart';

/// Represents the source of an image.
enum ImageSource {
  gallery,
  url,
}

/// A model representing an image stored in the application.
class AppImage {
  final String id;
  final String localPath;
  final String? originalUrl;
  final String? thumbnailPath;
  final DateTime createdAt;
  final ImageSource source;
  final Map<String, dynamic> metadata;

  AppImage({
    String? id,
    required this.localPath,
    this.originalUrl,
    this.thumbnailPath,
    DateTime? createdAt,
    this.source = ImageSource.url,
    Map<String, dynamic>? metadata,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'originalUrl': originalUrl,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.toIso8601String(),
      'source': source.toString(),
      'metadata': metadata,
    };
  }

  factory AppImage.fromJson(Map<String, dynamic> json) {
    return AppImage(
      id: json['id'],
      localPath: json['localPath'],
      originalUrl: json['originalUrl'],
      thumbnailPath: json['thumbnailPath'],
      createdAt: DateTime.parse(json['createdAt']),
      source: _parseImageSource(json['source']),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : {},
    );
  }

  static ImageSource _parseImageSource(String? source) {
    if (source == null) return ImageSource.url;
    return ImageSource.values.firstWhere(
      (e) => e.toString() == source,
      orElse: () => ImageSource.url,
    );
  }
}
