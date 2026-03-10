import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;

import '../models/game.dart';
import '../models/game_summary.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../models/journal_entry.dart';
import '../utils/logging_service.dart';
import 'datasworn_provider.dart';
import 'image_manager_provider.dart';
import 'clock_operations_mixin.dart';
import 'quest_operations_mixin.dart';
import 'connection_operations_mixin.dart';
import 'faction_operations_mixin.dart';
import 'route_operations_mixin.dart';

class GameProvider extends ChangeNotifier with ClockOperationsMixin, QuestOperationsMixin, ConnectionOperationsMixin, FactionOperationsMixin, RouteOperationsMixin {

  List<GameSummary> _gameSummaries = [];
  Game? _currentGame;
  Session? _currentSession;
  bool _isLoading = false;
  String? _error;

  List<GameSummary> get gameSummaries => _gameSummaries;

  /// Backward-compatible getter. Returns only the current game (if loaded).
  List<Game> get games => _currentGame != null ? [_currentGame!] : [];

  Game? get currentGame => _currentGame;
  Session? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public method to save games
  Future<void> saveGame() async {
    await _saveCurrentGame();
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
    await _saveCurrentGame();
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

  @override
  void dispose() {
    if (_currentGame != null) {
      _saveCurrentGame();
    }
    _currentGame = null;
    _currentSession = null;
    _gameSummaries.clear();
    _imageManagerProvider = null;
    super.dispose();
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
      if (location.imageUrl != null && location.imageUrl!.isNotEmpty) {
        // Save the image from URL and get an imageId
        final image = await _imageManagerProvider!.addImageFromUrl(
          location.imageUrl!,
          metadata: {'usage': 'location', 'locationId': location.id},
        );

        if (image != null) {
          location.imageId = image.id;
          loggingService.debug(
            'Saved location image: ${location.name} (URL: ${location.imageUrl}, ID: ${image.id})',
            tag: 'GameProvider',
          );
        }
      }
    }

    // Save the game with updated imageIds
    await _saveCurrentGame();
  }

  // Load games from storage — only summaries at startup, full game for last-played
  Future<void> _loadGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Try loading cached summaries first (fast path)
      final summariesJson = prefs.getString('gameSummaries');
      if (summariesJson != null) {
        try {
          _gameSummaries = GameSummary.listFromJsonString(summariesJson);
          LoggingService().info(
            'Loaded ${_gameSummaries.length} game summaries from cache',
            tag: 'GameProvider',
          );
        } catch (e) {
          LoggingService().warning(
            'Failed to parse cached summaries, will rebuild from game data',
            tag: 'GameProvider',
          );
          _gameSummaries = [];
        }
      }

      // If no cached summaries, build them from individual game JSON (migration)
      if (_gameSummaries.isEmpty) {
        final gameIds = prefs.getStringList('gameIds') ?? [];
        for (final id in gameIds) {
          final gameJson = prefs.getString('game_$id');
          if (gameJson != null) {
            try {
              final json = jsonDecode(gameJson) as Map<String, dynamic>;
              _gameSummaries.add(GameSummary.fromGameJson(json));
            } catch (e) {
              LoggingService().error(
                'Failed to parse game JSON for summary (ID: $id)',
                tag: 'GameProvider',
                error: e,
                stackTrace: StackTrace.current,
              );
            }
          } else {
            LoggingService().warning(
              'Game data not found for ID: $id',
              tag: 'GameProvider',
            );
          }
        }
        // Save the newly built summaries
        if (_gameSummaries.isNotEmpty) {
          await _saveSummaries(prefs);
        }
      }

      // Load the last-played game fully
      final lastPlayedId = prefs.getString('lastPlayedGameId');
      String? gameIdToLoad;

      if (lastPlayedId != null &&
          _gameSummaries.any((s) => s.id == lastPlayedId)) {
        gameIdToLoad = lastPlayedId;
      } else if (_gameSummaries.isNotEmpty) {
        gameIdToLoad = _gameSummaries.first.id;
      }

      if (gameIdToLoad != null) {
        await _loadFullGame(gameIdToLoad, prefs);
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

  // Load a full game from SharedPreferences by ID
  Future<void> _loadFullGame(String gameId, [SharedPreferences? prefsArg]) async {
    final prefs = prefsArg ?? await SharedPreferences.getInstance();
    final gameJson = prefs.getString('game_$gameId');

    if (gameJson == null) {
      LoggingService().warning(
        'Game data not found for ID: $gameId',
        tag: 'GameProvider',
      );
      return;
    }

    try {
      _currentGame = Game.fromJsonString(gameJson);

      // Log AI config info
      if (_currentGame!.aiConfig.aiImageGenerationEnabled &&
          _currentGame!.aiConfig.aiImageProvider != null) {
        LoggingService().info(
          'Loaded game with AI image generation enabled: ${_currentGame!.name} (Provider: ${_currentGame!.aiConfig.aiImageProvider})',
          tag: 'GameProvider',
        );
      }

      // Restore last session
      final lastSessionId = prefs.getString('lastSessionId_$gameId');
      if (lastSessionId != null && _currentGame!.sessions.isNotEmpty) {
        _currentSession = _currentGame!.sessions.firstWhere(
          (session) => session.id == lastSessionId,
          orElse: () => _currentGame!.sessions.first,
        );
      } else if (_currentGame!.sessions.isNotEmpty) {
        _currentSession = _currentGame!.sessions.first;
      } else {
        _currentSession = null;
      }
    } catch (e) {
      LoggingService().error(
        'Failed to parse game JSON',
        tag: 'GameProvider',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  // Unload the current game from memory
  void _unloadCurrentGame() {
    _currentGame = null;
    _currentSession = null;
  }

  // Save only the current game (not all games)
  Future<void> _saveCurrentGame() async {
    if (_currentGame == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save the current game's JSON
      final jsonString = _currentGame!.toJsonString();

      // Log API keys information before saving
      if (_currentGame!.aiConfig.aiImageGenerationEnabled &&
          _currentGame!.aiConfig.aiImageProvider != null) {
        LoggingService().debug(
          'Saving game with API keys: ${_currentGame!.aiConfig.aiApiKeys.keys.join(", ")}',
          tag: 'GameProvider',
        );
      }

      await prefs.setString('game_${_currentGame!.id}', jsonString);
      LoggingService().debug(
        'Saved game to SharedPreferences: ${_currentGame!.name} (ID: ${_currentGame!.id}) - JSON length: ${jsonString.length}',
        tag: 'GameProvider',
      );

      // Update the corresponding summary
      final summaryIndex = _gameSummaries.indexWhere(
        (s) => s.id == _currentGame!.id,
      );
      final updatedSummary = GameSummary.fromGame(_currentGame!);
      if (summaryIndex != -1) {
        _gameSummaries[summaryIndex] = updatedSummary;
      }

      // Save summaries and metadata
      await _saveSummaries(prefs);

      // Save last played game and session
      await prefs.setString('lastPlayedGameId', _currentGame!.id);
      if (_currentSession != null) {
        await prefs.setString(
          'lastSessionId_${_currentGame!.id}',
          _currentSession!.id,
        );
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

  // Save the summaries list and gameIds
  Future<void> _saveSummaries([SharedPreferences? prefsArg]) async {
    final prefs = prefsArg ?? await SharedPreferences.getInstance();
    final gameIds = _gameSummaries.map((s) => s.id).toList();
    await prefs.setStringList('gameIds', gameIds);
    await prefs.setString(
      'gameSummaries',
      GameSummary.listToJsonString(_gameSummaries),
    );
    LoggingService().debug(
      'Saved ${_gameSummaries.length} game summaries',
      tag: 'GameProvider',
    );
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
    // Save current game before switching
    if (_currentGame != null) {
      await _saveCurrentGame();
    }

    final game = Game(
      name: name,
      dataswornSource: dataswornSource,
      tutorialsEnabled: tutorialsEnabled,
      sentientAiEnabled: sentientAiEnabled,
      sentientAiName: sentientAiName,
      sentientAiPersona: sentientAiPersona,
      sentientAiImagePath: sentientAiImagePath,
    );

    _gameSummaries.add(GameSummary.fromGame(game));
    _currentGame = game;
    _currentSession = null;

    notifyListeners();

    await _saveCurrentGame();

    // Load images from the game
    await loadImagesFromGame();

    return game;
  }

  // Switch to a different game
  Future<void> switchGame(String gameId) async {
    // Don't switch if already on this game
    if (_currentGame?.id == gameId) return;

    // Save and unload the current game
    if (_currentGame != null) {
      await _saveCurrentGame();
      _unloadCurrentGame();
    }

    // Load the new game
    await _loadFullGame(gameId);

    if (_currentGame == null) {
      LoggingService().warning('Game not found: $gameId', tag: 'GameProvider');
      return;
    }

    _currentGame!.updateLastPlayed();

    // Update the summary's lastPlayedAt
    final summaryIndex = _gameSummaries.indexWhere((s) => s.id == gameId);
    if (summaryIndex != -1) {
      _gameSummaries[summaryIndex].lastPlayedAt = _currentGame!.lastPlayedAt;
    }

    notifyListeners();
    await _saveCurrentGame();
  }

  // Delete a game
  Future<void> deleteGame(String gameId) async {
    _gameSummaries.removeWhere((s) => s.id == gameId);

    // Remove the game data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_$gameId');
    await prefs.remove('lastSessionId_$gameId');

    if (_currentGame?.id == gameId) {
      _unloadCurrentGame();

      // Load the next available game
      if (_gameSummaries.isNotEmpty) {
        await _loadFullGame(_gameSummaries.first.id, prefs);
      }
    }

    await _saveSummaries(prefs);
    notifyListeners();
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
    await _saveCurrentGame();

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
    await _saveCurrentGame();

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
      await _saveCurrentGame();
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
      await _saveCurrentGame();
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
      await _saveCurrentGame();
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
      await _saveCurrentGame();
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
      await _saveCurrentGame();
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
    await _saveCurrentGame();

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
    await _saveCurrentGame();
  }

  // Create a new journal entry
  Future<JournalEntry> createJournalEntry(String content) async {
    if (_currentGame == null || _currentSession == null) {
      throw Exception('No game or session selected');
    }

    final entry = _currentSession!.createNewEntry(content);

    notifyListeners();
    await _saveCurrentGame();

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
    await _saveCurrentGame();
  }

  // Quest-related methods are provided by QuestOperationsMixin

  // Sentient AI and AI Image Generation methods are provided by AiConfigProvider

  // Clock-related methods are provided by ClockOperationsMixin

  // Export game to JSON file
  Future<String?> exportGame(String gameId) async {
    try {
      // If exporting the current game, use the in-memory version
      // Otherwise, load from SharedPreferences
      String jsonString;
      String gameName;

      if (_currentGame != null && _currentGame!.id == gameId) {
        jsonString = _currentGame!.toJsonString();
        gameName = _currentGame!.name;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('game_$gameId');
        if (stored == null) {
          throw Exception('Game data not found for ID: $gameId');
        }
        jsonString = stored;
        final summary = _gameSummaries.firstWhereOrNull((s) => s.id == gameId);
        gameName = summary?.name ?? 'game';
      }

      if (kIsWeb) {
        return 'Export not supported in web version';
      } else {
        // For mobile, use FilePicker
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Game',
          fileName: '${gameName.replaceAll(' ', '_')}.json',
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

      // Save current game before switching
      if (_currentGame != null) {
        await _saveCurrentGame();
      }

      // Process the JSON string
      final game = Game.fromJsonString(jsonString);

      // Check if a game with this ID already exists
      final existingIndex = _gameSummaries.indexWhere((s) => s.id == game.id);
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

        _gameSummaries.add(GameSummary.fromGame(importedGame));
        _currentGame = importedGame;

        if (importedGame.sessions.isNotEmpty) {
          _currentSession = importedGame.sessions.first;
        } else {
          _currentSession = null;
        }
      } else {
        _gameSummaries.add(GameSummary.fromGame(game));
        _currentGame = game;

        if (game.sessions.isNotEmpty) {
          _currentSession = game.sessions.first;
        } else {
          _currentSession = null;
        }
      }

      notifyListeners();
      await _saveCurrentGame();

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
