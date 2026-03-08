import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;

import '../models/game.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../models/journal_entry.dart';
import '../utils/logging_service.dart';
import '../services/oracle_service.dart';
import 'datasworn_provider.dart';
import 'image_manager_provider.dart';
import 'clock_operations_mixin.dart';
import 'quest_operations_mixin.dart';

class GameProvider extends ChangeNotifier with ClockOperationsMixin, QuestOperationsMixin {
  
  List<Game> _games = [];
  Game? _currentGame;
  Session? _currentSession;
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  Game? get currentGame => _currentGame;
  Session? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Public method to save games
  Future<void> saveGame() async {
    await _saveGames();
  }

  // Mixin interface for ClockOperationsMixin and QuestOperationsMixin
  @override
  Game? get clockGame => _currentGame;
  @override
  Session? get clockSession => _currentSession;
  @override
  Game? get questGame => _currentGame;
  @override
  Session? get questSession => _currentSession;
  @override
  Future<void> persistAndNotify() async {
    notifyListeners();
    await _saveGames();
  }

  // Reference to the ImageManagerProvider
  ImageManagerProvider? _imageManagerProvider;

  // Set the ImageManagerProvider reference
  void setImageManagerProvider(ImageManagerProvider provider) {
    _imageManagerProvider = provider;
  }

  GameProvider() {
    _loadGames();
  }
  
  // Load images from the current game into the ImageManagerProvider
  Future<void> loadImagesFromGame() async {
    if (_currentGame == null || _imageManagerProvider == null) return;
    
    final loggingService = LoggingService();
    loggingService.info('Loading images from game: ${_currentGame!.name}', tag: 'GameProvider');
    
    // Load images from characters
    for (final character in _currentGame!.characters) {
      if (character.imageUrl != null && character.imageUrl!.isNotEmpty) {
        // Save the image from URL and get an imageId
        final image = await _imageManagerProvider!.addImageFromUrl(
          character.imageUrl!,
          metadata: {'usage': 'character', 'characterId': character.id},
        );
        
        if (image != null) {
          // Update the character with the imageId
          character.imageId = image.id;
          loggingService.debug(
            'Saved character image: ${character.name} (URL: ${character.imageUrl}, ID: ${image.id})',
            tag: 'GameProvider',
          );
        }
      }
    }
    
    // Load images from journal entries
    if (_currentSession != null) {
      for (final entry in _currentSession!.entries) {
        for (final imageUrl in entry.embeddedImages) {
          // Save the image from URL and get an imageId
          final image = await _imageManagerProvider!.addImageFromUrl(
            imageUrl,
            metadata: {'usage': 'journal', 'entryId': entry.id},
          );
          
          if (image != null) {
            // Add the imageId to the entry
            entry.addEmbeddedImageId(image.id);
            loggingService.debug(
              'Saved journal image: ${entry.id} (URL: $imageUrl, ID: ${image.id})',
              tag: 'GameProvider',
            );
          }
        }
      }
    }
    
    // Load Sentient AI image if available
    final ai = _currentGame!.aiConfig;
    if (ai.sentientAiEnabled &&
        ai.sentientAiImagePath != null &&
        ai.sentientAiImagePath!.isNotEmpty &&
        ai.sentientAiImagePath!.startsWith('http')) {

      final image = await _imageManagerProvider!.addImageFromUrl(
        ai.sentientAiImagePath!,
        metadata: {'usage': 'sentientAi', 'gameId': _currentGame!.id},
      );

      if (image != null) {
        ai.sentientAiImagePath = image.id;
        loggingService.debug(
          'Saved Sentient AI image: ${ai.sentientAiName ?? "AI"} (URL: ${ai.sentientAiImagePath}, ID: ${image.id})',
          tag: 'GameProvider',
        );
      }
    }
    
    // Load location images if they have imageUrl properties
    for (final location in _currentGame!.locations) {
      // Check if Location has an imageUrl property and it's not empty
      // Note: This is a placeholder - you'll need to add imageUrl to Location model if it doesn't exist
      if (location.imageUrl != null && location.imageUrl!.isNotEmpty) {
        // Save the image from URL and get an imageId
        final image = await _imageManagerProvider!.addImageFromUrl(
          location.imageUrl!,
          metadata: {'usage': 'location', 'locationId': location.id},
        );
        
        if (image != null) {
          // Update the location with the imageId
          // Note: You'll need to add imageId to Location model if it doesn't exist
          location.imageId = image.id;
          loggingService.debug(
            'Saved location image: ${location.name} (URL: ${location.imageUrl}, ID: ${image.id})',
            tag: 'GameProvider',
          );
        }
      }
    }
    
    // Save the game with updated imageIds
    await _saveGames();
  }

  // Load games from storage using SharedPreferences for all platforms
  Future<void> _loadGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Use SharedPreferences for all platforms
      final prefs = await SharedPreferences.getInstance();
      
      // Get game IDs
      final gameIds = prefs.getStringList('gameIds') ?? [];
      
      
      _games = [];
      for (final id in gameIds) {
        final gameJson = prefs.getString('game_$id');
        if (gameJson != null) {
          try {
            final game = Game.fromJsonString(gameJson);
            _games.add(game);
          } catch (e) {
            LoggingService().error(
              'Failed to parse game JSON',
              tag: 'GameProvider',
              error: e,
              stackTrace: StackTrace.current
            );
          }
        } else {
          LoggingService().warning(
            'Game data not found for ID: $id',
            tag: 'GameProvider'
          );
        }
      }
      
      // Log the loaded games
      for (final game in _games) {
        if (game.aiConfig.aiImageGenerationEnabled && game.aiConfig.aiImageProvider != null) {
          LoggingService().info(
            'Loaded game with AI image generation enabled: ${game.name} (Provider: ${game.aiConfig.aiImageProvider})',
            tag: 'GameProvider'
          );

          if (game.aiConfig.aiApiKeys.isNotEmpty) {
            LoggingService().debug(
              'Game has ${game.aiConfig.aiApiKeys.length} API key(s) for providers: ${game.aiConfig.aiApiKeys.keys.join(", ")}',
              tag: 'GameProvider'
            );
          } else {
            LoggingService().warning(
              'Game has AI image generation enabled but no API keys are set',
              tag: 'GameProvider'
            );
          }
        }
      }
      
      // Load last played game
      final lastPlayedId = prefs.getString('lastPlayedGameId');
      if (lastPlayedId != null) {
        _currentGame = _games.firstWhereOrNull(
          (game) => game.id == lastPlayedId,
        );
        if (_currentGame == null && _games.isNotEmpty) {
          _currentGame = _games.first;
        }
        
        // Load last played session
        if (_currentGame != null) {
          final lastSessionId = prefs.getString('lastSessionId_${_currentGame!.id}');
          if (lastSessionId != null && _currentGame!.sessions.isNotEmpty) {
            _currentSession = _currentGame!.sessions.firstWhere(
              (session) => session.id == lastSessionId,
              orElse: () => _currentGame!.sessions.first,
            );
          } else if (_currentGame!.sessions.isNotEmpty) {
            _currentSession = _currentGame!.sessions.first;
          }
        }
      } else if (_games.isNotEmpty) {
        _currentGame = _games.first;
        if (_currentGame!.sessions.isNotEmpty) {
          _currentSession = _currentGame!.sessions.first;
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load games: ${e.toString()}';
      LoggingService().error(
        'Failed to load games',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      notifyListeners();
    }
  }

  // Save games to storage using SharedPreferences for all platforms
  Future<void> _saveGames() async {
    try {
      // Use SharedPreferences for all platforms
      final prefs = await SharedPreferences.getInstance();
      
      // Save game IDs
      final gameIds = _games.map((game) => game.id).toList();
      await prefs.setStringList('gameIds', gameIds);
      LoggingService().info('Saving games to SharedPreferences: ${gameIds.length} game IDs', tag: 'GameProvider');
      
      // Save each game
      for (final game in _games) {
        final jsonString = game.toJsonString();
        
        // Log API keys information before saving
        if (game.aiConfig.aiImageGenerationEnabled && game.aiConfig.aiImageProvider != null) {
          LoggingService().debug(
            'Saving game with API keys: ${game.aiConfig.aiApiKeys.keys.join(", ")}',
            tag: 'GameProvider'
          );
          
          // Check if aiApiKeys is in the JSON string (without logging the actual keys)
          if (jsonString.contains('"aiApiKeys":{')) {
            LoggingService().debug(
              'JSON contains aiApiKeys field',
              tag: 'GameProvider'
            );
          } else {
            LoggingService().warning(
              'JSON does NOT contain aiApiKeys field',
              tag: 'GameProvider'
            );
          }
        }
        
        await prefs.setString('game_${game.id}', jsonString);
        LoggingService().debug(
          'Saved game to SharedPreferences: ${game.name} (ID: ${game.id}) - JSON length: ${jsonString.length}',
          tag: 'GameProvider'
        );
      }
      
      // Save last played game and session
      if (_currentGame != null) {
        await prefs.setString('lastPlayedGameId', _currentGame!.id);
        LoggingService().debug(
          'Saved last played game ID to SharedPreferences: ${_currentGame!.id}',
          tag: 'GameProvider'
        );
        
        if (_currentSession != null) {
          await prefs.setString('lastSessionId_${_currentGame!.id}', _currentSession!.id);
          LoggingService().debug(
            'Saved last session ID to SharedPreferences: ${_currentSession!.id}',
            tag: 'GameProvider'
          );
        }
      }
    } catch (e) {
      _error = 'Failed to save games: ${e.toString()}';
      LoggingService().error(
        'Failed to save games',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      notifyListeners();
    }
  }
  
  // Create a new game
  Future<Game> createGame(
    String name, {
    String? dataswornSource,
    bool tutorialsEnabled = true,
    bool sentientAiEnabled = false,
    String? sentientAiName,
    String? sentientAiPersona,
    String? sentientAiImagePath,
  }) async {
    final game = Game(
      name: name,
      dataswornSource: dataswornSource,
      tutorialsEnabled: tutorialsEnabled,
      sentientAiEnabled: sentientAiEnabled,
      sentientAiName: sentientAiName,
      sentientAiPersona: sentientAiPersona,
      sentientAiImagePath: sentientAiImagePath,
    );
    
    _games.add(game);
    _currentGame = game;
    _currentSession = null;

    notifyListeners();

    await _saveGames();

    // Load images from the game
    await loadImagesFromGame();

    return game;
  }

  // Switch to a different game
  Future<void> switchGame(String gameId) async {
    final game = _games.firstWhereOrNull((g) => g.id == gameId);
    if (game == null) {
      LoggingService().warning('Game not found: $gameId', tag: 'GameProvider');
      return;
    }

    _currentGame = game;
    _currentGame!.updateLastPlayed();
    
    // Try to load the last selected session for this game
    if (_currentGame!.sessions.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final lastSessionId = prefs.getString('lastSessionId_${_currentGame!.id}');
      
      if (lastSessionId != null) {
        _currentSession = _currentGame!.sessions.firstWhereOrNull(
          (session) => session.id == lastSessionId,
        ) ?? _currentGame!.sessions.first;
      } else {
        _currentSession = _currentGame!.sessions.first;
      }
    } else {
      _currentSession = null;
    }

    notifyListeners();
    await _saveGames();
  }

  // Delete a game
  Future<void> deleteGame(String gameId) async {
    _games.removeWhere((g) => g.id == gameId);

    if (_currentGame?.id == gameId) {
      _currentGame = _games.isNotEmpty ? _games.first : null;

      // Try to load the last selected session for the new current game
      if (_currentGame != null && _currentGame!.sessions.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final lastSessionId = prefs.getString('lastSessionId_${_currentGame!.id}');

        if (lastSessionId != null) {
          _currentSession = _currentGame!.sessions.firstWhereOrNull(
            (session) => session.id == lastSessionId,
          ) ?? _currentGame!.sessions.first;
        } else {
          _currentSession = _currentGame!.sessions.first;
        }
      } else {
        _currentSession = null;
      }
    }

    notifyListeners();
    await _saveGames();
  }

  // Update Base Rig assets for existing characters
  Future<void> updateBaseRigAssets(DataswornProvider dataswornProvider) async {
    final loggingService = LoggingService();
    
    // Skip if no game is loaded
    if (_currentGame == null) return;
    
    bool assetsUpdated = false;
    
    // Process all characters
    for (final character in _currentGame!.characters) {
      // Find any Base Rig assets
      for (int i = 0; i < character.assets.length; i++) {
        final asset = character.assets[i];
        
        // Check if this is a Base Rig asset without options (factory-created)
        if (asset.category == 'Base Rig' && asset.options.isEmpty) {
          loggingService.debug(
            'Found factory-created Base Rig asset for character: ${character.name}',
            tag: 'GameProvider',
          );
          
          // Try to find the Base Rig asset in the DataswornProvider by ID
          Asset? baseRig = dataswornProvider.findAssetById("base_rig");
          
          // If not found by ID, try to find it in the rig asset collection
          if (baseRig == null) {
            final assetsByCategory = dataswornProvider.getAssetsByCategory();
            if (assetsByCategory.containsKey('rig')) {
              final rigAssets = assetsByCategory['rig'];
              if (rigAssets != null && rigAssets.isNotEmpty) {
                baseRig = rigAssets.firstWhereOrNull(
                  (a) => a.id == "base_rig"
                );
                if (baseRig != null) {
                  loggingService.debug(
                    'Found Base Rig asset in rig category: ${baseRig.name} (ID: ${baseRig.id})',
                    tag: 'GameProvider',
                  );
                } else {
                  loggingService.warning(
                    'Base Rig asset not found in rig category',
                    tag: 'GameProvider',
                  );
                }
              }
            }
          } else {
            loggingService.debug(
              'Found Base Rig asset by ID: ${baseRig.name} (ID: ${baseRig.id})',
              tag: 'GameProvider',
            );
          }
          
          // If we found a proper Base Rig asset, replace the factory-created one
          if (baseRig != null) {
            loggingService.debug(
              'Replacing factory-created Base Rig with Datasworn version for character: ${character.name}',
              tag: 'GameProvider',
            );
            
            // Preserve enabled state of abilities if any
            if (asset.abilities.isNotEmpty && baseRig.abilities.isNotEmpty) {
              for (int j = 0; j < math.min(asset.abilities.length, baseRig.abilities.length); j++) {
                baseRig.abilities[j].enabled = asset.abilities[j].enabled;
              }
            }
            
            // Replace the asset
            character.assets[i] = baseRig;
            assetsUpdated = true;
          }
        }
      }
    }
    
    // Save changes if any assets were updated
    if (assetsUpdated) {
      await saveGame();
    }
  }

  // Create a new character
  Future<Character> createCharacter(String name, {bool isMainCharacter = false, String? handle}) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final character = isMainCharacter
        ? Character.createMainCharacter(name, handle: handle)
        : Character(name: name, handle: handle);
    
    _currentGame!.addCharacter(character);

    notifyListeners();
    await _saveGames();

    return character;
  }

  // Create a new location
  Future<Location> createLocation(
    String name, {
    String? description,
    LocationSegment segment = LocationSegment.core,
    String? nodeType,
    String? connectToLocationId,
    double? x,
    double? y,
  }) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final location = Location(
      name: name,
      description: description,
      segment: segment,
      nodeType: nodeType,
      x: x,
      y: y,
    );
    
    _currentGame!.addLocation(location);
    
    // If connectToLocationId is provided, create a connection
    if (connectToLocationId != null) {
      try {
        _currentGame!.connectLocations(connectToLocationId, location.id);
      } catch (e) {
        LoggingService().warning(
          'Failed to connect locations: ${e.toString()}',
          tag: 'GameProvider'
        );
      }
    }

    notifyListeners();
    await _saveGames();

    return location;
  }
  
  // Connect two locations
  Future<void> connectLocations(String sourceId, String targetId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      _currentGame!.connectLocations(sourceId, targetId);
      notifyListeners();
      await _saveGames();
    } catch (e) {
      LoggingService().error(
        'Failed to connect locations',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }
  
  // Disconnect two locations
  Future<void> disconnectLocations(String sourceId, String targetId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      _currentGame!.disconnectLocations(sourceId, targetId);
      notifyListeners();
      await _saveGames();
    } catch (e) {
      LoggingService().error(
        'Failed to disconnect locations',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }
  
  // Update location segment
  Future<void> updateLocationSegment(String locationId, LocationSegment segment) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      final location = _currentGame!.locations.firstWhere(
        (loc) => loc.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      
      // Check if changing segment would violate connection rules
      for (final connectedId in location.connectedLocationIds) {
        final connectedLocation = _currentGame!.locations.firstWhere(
          (loc) => loc.id == connectedId,
          orElse: () => throw Exception('Connected location not found'),
        );
        
        if (!_currentGame!.areSegmentsAdjacent(segment, connectedLocation.segment)) {
          throw Exception('Cannot change segment: would violate connection rules with ${connectedLocation.name}');
        }
      }
      
      location.segment = segment;
      notifyListeners();
      await _saveGames();
    } catch (e) {
      LoggingService().error(
        'Failed to update location segment',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }
  
  // Update location position
  Future<void> updateLocationPosition(String locationId, double x, double y) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      final location = _currentGame!.locations.firstWhere(
        (loc) => loc.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      
      location.updatePosition(x, y);
      notifyListeners();
      await _saveGames();
    } catch (e) {
      LoggingService().error(
        'Failed to update location position',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }
  
  // Update location scale
  Future<void> updateLocationScale(String locationId, double scale) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      final location = _currentGame!.locations.firstWhere(
        (loc) => loc.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      
      location.updateScale(scale);
      notifyListeners();
      await _saveGames();
    } catch (e) {
      LoggingService().error(
        'Failed to update location scale',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }
  
  // Get valid connections for a location
  List<Location> getValidConnectionsForLocation(String locationId) {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      return _currentGame!.getValidConnectionsForLocation(locationId);
    } catch (e) {
      LoggingService().error(
        'Failed to get valid connections',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      return [];
    }
  }

  // Create a new session
  Future<Session> createSession(String title) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final session = _currentGame!.createNewSession(title);
    _currentSession = session;

    notifyListeners();
    await _saveGames();

    return session;
  }

  // Switch to a different session
  Future<void> switchSession(String sessionId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final session = _currentGame!.sessions.firstWhereOrNull((s) => s.id == sessionId);
    if (session == null) {
      LoggingService().warning('Session not found: $sessionId', tag: 'GameProvider');
      return;
    }
    _currentSession = session;

    notifyListeners();
    await _saveGames();
  }

  // Create a new journal entry
  Future<JournalEntry> createJournalEntry(String content) async {
    if (_currentGame == null || _currentSession == null) {
      throw Exception('No game or session selected');
    }
    
    final entry = _currentSession!.createNewEntry(content);

    notifyListeners();
    await _saveGames();

    return entry;
  }

  // Update a journal entry
  Future<void> updateJournalEntry(String entryId, String content) async {
    if (_currentGame == null || _currentSession == null) {
      throw Exception('No game or session selected');
    }
    
    final entry = _currentSession!.entries.firstWhereOrNull((e) => e.id == entryId);
    if (entry == null) {
      LoggingService().warning('Journal entry not found: $entryId', tag: 'GameProvider');
      return;
    }
    entry.update(content);

    notifyListeners();
    await _saveGames();
  }

  // Quest-related methods are provided by QuestOperationsMixin

  // Sentient AI-related methods
  
  // Update sentientAiEnabled setting
  Future<void> updateSentientAiEnabled(bool enabled) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.sentientAiEnabled == enabled) return;
    _currentGame!.aiConfig.sentientAiEnabled = enabled;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateSentientAiName(String? name) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.sentientAiName == name) return;
    _currentGame!.aiConfig.sentientAiName = name;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateSentientAiPersona(String? persona) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.sentientAiPersona == persona) return;
    _currentGame!.aiConfig.sentientAiPersona = persona;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateSentientAiImagePath(String? imagePath) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.sentientAiImagePath == imagePath) return;
    _currentGame!.aiConfig.sentientAiImagePath = imagePath;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateAiImageGenerationEnabled(bool enabled) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.aiImageGenerationEnabled == enabled) return;
    _currentGame!.aiConfig.aiImageGenerationEnabled = enabled;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateAiImageProvider(String? provider) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.aiImageProvider == provider) return;
    _currentGame!.aiConfig.aiImageProvider = provider;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateOpenAiModel(String model) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.openaiModel == model) return;
    _currentGame!.aiConfig.openaiModel = model;
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateAiApiKey(String provider, String apiKey) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.getAiApiKey(provider) == apiKey) return;
    _currentGame!.aiConfig.setAiApiKey(provider, apiKey);
    notifyListeners();
    await _saveGames();
  }

  Future<void> updateAiArtisticDirection(String provider, String artisticDirection) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (_currentGame!.aiConfig.getAiArtisticDirection(provider) == artisticDirection) return;
    _currentGame!.aiConfig.setAiArtisticDirection(provider, artisticDirection);
    notifyListeners();
    await _saveGames();
  }

  Future<void> removeAiApiKey(String provider) async {
    if (_currentGame == null) throw Exception('No game selected');
    if (!_currentGame!.aiConfig.aiApiKeys.containsKey(provider)) return;
    _currentGame!.aiConfig.removeAiApiKey(provider);
    notifyListeners();
    await _saveGames();
  }

  // Batch update AI config settings (reduces multiple save/notify cycles to one)
  Future<void> updateAiConfig({
    bool? aiImageGenerationEnabled,
    String? aiImageProvider,
    String? openaiModel,
    Map<String, String>? apiKeys,
    Map<String, String>? artisticDirections,
  }) async {
    if (_currentGame == null) throw Exception('No game selected');
    final config = _currentGame!.aiConfig;
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
    await _saveGames();
  }

  bool isAiImageGenerationAvailable() {
    if (_currentGame == null) return false;
    return _currentGame!.aiConfig.isAiImageGenerationAvailable();
  }
  
  // Get AI personas from the datasworn provider
  List<Map<String, String>> getAiPersonas(DataswornProvider dataswornProvider) {
    // Use the recursive search function from OracleService with just "persona" as the key
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
  
  // Get a random AI persona
  String? getRandomAiPersona(DataswornProvider dataswornProvider) {
    final personas = getAiPersonas(dataswornProvider);
    if (personas.isEmpty) return null;
    
    final random = math.Random();
    final randomIndex = random.nextInt(personas.length);
    return personas[randomIndex]['id'];
  }
  
  // Clock-related methods are provided by ClockOperationsMixin

  // Export game to JSON file
  Future<String?> exportGame(String gameId) async {
    try {
      final game = _games.firstWhere((g) => g.id == gameId);
      final jsonString = game.toJsonString();
      
      if (kIsWeb) {
        // For web, we'll use a workaround with FilePicker
        // This is a limitation since we're not using dart:html directly
        // In a real app, you'd want to add a web-specific implementation
        return 'Export not supported in web version';
      } else {
        // For mobile, use FilePicker
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Game',
          fileName: '${game.name.replaceAll(' ', '_')}.json',
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsString(jsonString);
          return result;
        }
      }
      
      return null;
    } catch (e) {
      _error = 'Failed to export game: ${e.toString()}';
      LoggingService().error(
        'Failed to export game',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      notifyListeners();
      return null;
    }
  }
  
  // Import game from JSON file
  Future<Game?> importGame() async {
    try {
      String? jsonString;
      
      // Use FilePicker for both web and mobile
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null) {
        return null;
      }
      
      if (kIsWeb) {
        // In web, we get the file content directly from bytes
        if (result.files.first.bytes != null) {
          jsonString = String.fromCharCodes(result.files.first.bytes!);
        } else {
          return null;
        }
      } else {
        // For mobile, read the file
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      }
      
      // Process the JSON string
      final game = Game.fromJsonString(jsonString);
      
      // Check if a game with this ID already exists
      final existingIndex = _games.indexWhere((g) => g.id == game.id);
      if (existingIndex != -1) {
        // Generate a new ID for the imported game
        final importedGame = Game(
          name: '${game.name} (Imported)',
          createdAt: game.createdAt,
          lastPlayedAt: game.lastPlayedAt,
          characters: game.characters,
          locations: game.locations,
          sessions: game.sessions,
          mainCharacter: game.mainCharacter,
          dataswornSource: game.dataswornSource,
        );
        
        _games.add(importedGame);
        _currentGame = importedGame;
        
        if (importedGame.sessions.isNotEmpty) {
          _currentSession = importedGame.sessions.first;
        } else {
          _currentSession = null;
        }
      } else {
        _games.add(game);
        _currentGame = game;
        
        if (game.sessions.isNotEmpty) {
          _currentSession = game.sessions.first;
        } else {
          _currentSession = null;
        }
      }
      
      notifyListeners();
      await _saveGames();

      return _currentGame;
    } catch (e) {
      _error = 'Failed to import game: ${e.toString()}';
      LoggingService().error(
        'Failed to import game',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current
      );
      notifyListeners();
      return null;
    }
  }
}
