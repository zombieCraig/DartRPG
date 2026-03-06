import '../utils/logging_service.dart';

/// Encapsulates all AI-related configuration for a Game.
class AiConfig {
  // Sentient AI settings
  bool sentientAiEnabled;
  String? sentientAiName;
  String? sentientAiPersona;
  String? sentientAiImagePath;

  // AI Image Generation settings
  bool aiImageGenerationEnabled;
  String? aiImageProvider;
  String? openaiModel;
  Map<String, String> aiApiKeys;
  Map<String, String> aiArtisticDirections;

  static const String _defaultModel = 'dall-e-2';
  static const String _defaultArtisticDirection =
      'cyberpunk scene, digital art, detailed illustration';

  AiConfig({
    this.sentientAiEnabled = false,
    this.sentientAiName,
    this.sentientAiPersona,
    this.sentientAiImagePath,
    this.aiImageGenerationEnabled = false,
    this.aiImageProvider,
    this.openaiModel = _defaultModel,
    Map<String, String>? aiApiKeys,
    Map<String, String>? aiArtisticDirections,
  })  : aiApiKeys = aiApiKeys != null ? Map.from(aiApiKeys) : {},
        aiArtisticDirections = aiArtisticDirections != null
            ? Map.from(aiArtisticDirections)
            : {} {
    // Set default artistic direction for Minimax if not provided
    this.aiArtisticDirections.putIfAbsent('minimax', () => _defaultArtisticDirection);
  }

  // --- Image generation ---

  void setAiApiKey(String provider, String apiKey) {
    aiApiKeys[provider] = apiKey;
  }

  String? getAiApiKey(String provider) => aiApiKeys[provider];

  void removeAiApiKey(String provider) {
    aiApiKeys.remove(provider);
  }

  bool isAiImageGenerationAvailable() {
    return aiImageGenerationEnabled &&
        aiImageProvider != null &&
        aiApiKeys.containsKey(aiImageProvider!);
  }

  String getOpenAiModelOrDefault() => openaiModel ?? _defaultModel;

  void setAiArtisticDirection(String provider, String direction) {
    aiArtisticDirections[provider] = direction;
  }

  String? getAiArtisticDirection(String provider) =>
      aiArtisticDirections[provider];

  String getAiArtisticDirectionOrDefault() {
    if (aiImageProvider != null &&
        aiArtisticDirections.containsKey(aiImageProvider!)) {
      return aiArtisticDirections[aiImageProvider!]!;
    }
    return _defaultArtisticDirection;
  }

  // --- Serialization ---

  Map<String, dynamic> toJson() {
    return {
      'sentientAiEnabled': sentientAiEnabled,
      'sentientAiName': sentientAiName,
      'sentientAiPersona': sentientAiPersona,
      'sentientAiImagePath': sentientAiImagePath,
      'aiImageGenerationEnabled': aiImageGenerationEnabled,
      'aiImageProvider': aiImageProvider,
      'openaiModel': openaiModel,
      'aiApiKeys': Map<String, dynamic>.from(aiApiKeys),
      'aiArtisticDirections': Map<String, dynamic>.from(aiArtisticDirections),
    };
  }

  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      sentientAiEnabled: json['sentientAiEnabled'] ?? false,
      sentientAiName: json['sentientAiName'],
      sentientAiPersona: json['sentientAiPersona'],
      sentientAiImagePath: json['sentientAiImagePath'],
      aiImageGenerationEnabled: json['aiImageGenerationEnabled'] ?? false,
      aiImageProvider: json['aiImageProvider'],
      openaiModel: json['openaiModel'] ?? _defaultModel,
      aiApiKeys: _parseStringMap(json['aiApiKeys'], 'API keys'),
      aiArtisticDirections:
          _parseStringMap(json['aiArtisticDirections'], 'artistic directions'),
    );
  }

  static Map<String, String> _parseStringMap(dynamic value, String label) {
    if (value == null) return {};
    try {
      final map = Map<String, dynamic>.from(value);
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      LoggingService().error(
        'Failed to parse $label from JSON',
        tag: 'AiConfig',
        error: e,
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }
}
