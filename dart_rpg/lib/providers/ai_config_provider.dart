import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/ai_config.dart';
import '../services/oracle_service.dart';
import 'datasworn_provider.dart';
import 'game_provider.dart';

/// Provider for AI configuration (sentient AI + image generation).
///
/// Delegates persistence to [GameProvider] since all state lives in the
/// [Game] model which is saved as a single JSON blob.
class AiConfigProvider extends ChangeNotifier {
  GameProvider _gameProvider;

  AiConfigProvider(this._gameProvider);

  /// Called by [ChangeNotifierProxyProvider] when [GameProvider] updates.
  void update(GameProvider gameProvider) {
    _gameProvider = gameProvider;
    notifyListeners();
  }

  /// The current game's AI config, or null if no game is loaded.
  AiConfig? get aiConfig => _gameProvider.currentGame?.aiConfig;

  // ---------------------------------------------------------------------------
  // Sentient AI methods
  // ---------------------------------------------------------------------------

  Future<void> updateSentientAiEnabled(bool enabled) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.sentientAiEnabled == enabled) return;
    _gameProvider.currentGame!.aiConfig.sentientAiEnabled = enabled;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateSentientAiName(String? name) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.sentientAiName == name) return;
    _gameProvider.currentGame!.aiConfig.sentientAiName = name;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateSentientAiPersona(String? persona) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.sentientAiPersona == persona) return;
    _gameProvider.currentGame!.aiConfig.sentientAiPersona = persona;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateSentientAiImagePath(String? imagePath) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.sentientAiImagePath == imagePath) return;
    _gameProvider.currentGame!.aiConfig.sentientAiImagePath = imagePath;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  // ---------------------------------------------------------------------------
  // AI Image Generation methods
  // ---------------------------------------------------------------------------

  Future<void> updateAiImageGenerationEnabled(bool enabled) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.aiImageGenerationEnabled == enabled) return;
    _gameProvider.currentGame!.aiConfig.aiImageGenerationEnabled = enabled;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateAiImageProvider(String? provider) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.aiImageProvider == provider) return;
    _gameProvider.currentGame!.aiConfig.aiImageProvider = provider;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateOpenAiModel(String model) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.openaiModel == model) return;
    _gameProvider.currentGame!.aiConfig.openaiModel = model;
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateAiApiKey(String provider, String apiKey) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.getAiApiKey(provider) == apiKey) return;
    _gameProvider.currentGame!.aiConfig.setAiApiKey(provider, apiKey);
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> updateAiArtisticDirection(String provider, String artisticDirection) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (_gameProvider.currentGame!.aiConfig.getAiArtisticDirection(provider) == artisticDirection) return;
    _gameProvider.currentGame!.aiConfig.setAiArtisticDirection(provider, artisticDirection);
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  Future<void> removeAiApiKey(String provider) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    if (!_gameProvider.currentGame!.aiConfig.aiApiKeys.containsKey(provider)) return;
    _gameProvider.currentGame!.aiConfig.removeAiApiKey(provider);
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  /// Batch update AI config settings (reduces multiple save/notify cycles to one).
  Future<void> updateAiConfig({
    bool? aiImageGenerationEnabled,
    String? aiImageProvider,
    String? openaiModel,
    Map<String, String>? apiKeys,
    Map<String, String>? artisticDirections,
  }) async {
    if (_gameProvider.currentGame == null) throw Exception('No game selected');
    final config = _gameProvider.currentGame!.aiConfig;
    if (aiImageGenerationEnabled != null) config.aiImageGenerationEnabled = aiImageGenerationEnabled;
    if (aiImageProvider != null) config.aiImageProvider = aiImageProvider;
    if (openaiModel != null) config.openaiModel = openaiModel;
    if (apiKeys != null) {
      for (final e in apiKeys.entries) config.setAiApiKey(e.key, e.value);
    }
    if (artisticDirections != null) {
      for (final e in artisticDirections.entries) config.setAiArtisticDirection(e.key, e.value);
    }
    notifyListeners();
    _gameProvider.notifyListeners();
    await _gameProvider.saveGame();
  }

  bool isAiImageGenerationAvailable() {
    if (_gameProvider.currentGame == null) return false;
    return _gameProvider.currentGame!.aiConfig.isAiImageGenerationAvailable();
  }

  /// Get AI personas from the datasworn provider.
  List<Map<String, String>> getAiPersonas(DataswornProvider dataswornProvider) {
    final personaTable = OracleService.findOracleTableByKeyAnywhere('persona', dataswornProvider);
    if (personaTable == null) return [];

    return personaTable.rows.map((row) {
      final text = row.result;
      final parts = text.split(' - ');
      final name = parts[0];
      final description = parts.length > 1 ? parts[1] : '';

      return {
        'id': text,
        'name': name,
        'description': description,
      };
    }).toList();
  }

  /// Get a random AI persona.
  String? getRandomAiPersona(DataswornProvider dataswornProvider) {
    final personas = getAiPersonas(dataswornProvider);
    if (personas.isEmpty) return null;

    final random = math.Random();
    final randomIndex = random.nextInt(personas.length);
    return personas[randomIndex]['id'];
  }
}
