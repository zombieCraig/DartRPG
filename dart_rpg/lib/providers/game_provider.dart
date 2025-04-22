import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;

import '../models/game.dart';
import '../models/character.dart';
import '../models/clock.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../models/journal_entry.dart';
import '../models/quest.dart';
import '../utils/logging_service.dart';
import '../utils/dice_roller.dart';
import '../services/oracle_service.dart';
import 'datasworn_provider.dart';
import 'image_manager_provider.dart';

class GameProvider extends ChangeNotifier {
  
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
      
      // Load last played game
      final lastPlayedId = prefs.getString('lastPlayedGameId');
      if (lastPlayedId != null) {
        try {
          _currentGame = _games.firstWhere(
            (game) => game.id == lastPlayedId,
          );
        } catch (e) {
          if (_games.isNotEmpty) {
            _currentGame = _games.first;
          }
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
    
    await _saveGames();
    
    // Load images from the game
    await loadImagesFromGame();
    
    notifyListeners();
    
    return game;
  }

  // Switch to a different game
  Future<void> switchGame(String gameId) async {
    final game = _games.firstWhere((g) => g.id == gameId);
    
    _currentGame = game;
    _currentGame!.updateLastPlayed();
    
    // Try to load the last selected session for this game
    if (_currentGame!.sessions.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final lastSessionId = prefs.getString('lastSessionId_${_currentGame!.id}');
      
      if (lastSessionId != null) {
        // Try to find the last selected session
        try {
          _currentSession = _currentGame!.sessions.firstWhere(
            (session) => session.id == lastSessionId,
          );
        } catch (_) {
          // If the last session can't be found, use the first session
          _currentSession = _currentGame!.sessions.first;
        }
      } else {
        // If no last session is saved, use the first session
        _currentSession = _currentGame!.sessions.first;
      }
    } else {
      _currentSession = null;
    }
    
    await _saveGames();
    notifyListeners();
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
          // Try to find the last selected session
          try {
            _currentSession = _currentGame!.sessions.firstWhere(
              (session) => session.id == lastSessionId,
            );
          } catch (_) {
            // If the last session can't be found, use the first session
            _currentSession = _currentGame!.sessions.first;
          }
        } else {
          // If no last session is saved, use the first session
          _currentSession = _currentGame!.sessions.first;
        }
      } else {
        _currentSession = null;
      }
    }
    
    await _saveGames();
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
                try {
                  baseRig = rigAssets.firstWhere(
                    (a) => a.id == "base_rig"
                  );
                  loggingService.debug(
                    'Found Base Rig asset in rig category: ${baseRig.name} (ID: ${baseRig.id})',
                    tag: 'GameProvider',
                  );
                } catch (e) {
                  loggingService.warning(
                    'Base Rig asset not found in rig category: ${e.toString()}',
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
    
    await _saveGames();
    notifyListeners();
    
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
    
    await _saveGames();
    notifyListeners();
    
    return location;
  }
  
  // Connect two locations
  Future<void> connectLocations(String sourceId, String targetId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    try {
      _currentGame!.connectLocations(sourceId, targetId);
      await _saveGames();
      notifyListeners();
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
      await _saveGames();
      notifyListeners();
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
      await _saveGames();
      notifyListeners();
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
      await _saveGames();
      notifyListeners();
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
      await _saveGames();
      notifyListeners();
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
    
    await _saveGames();
    notifyListeners();
    
    return session;
  }

  // Switch to a different session
  Future<void> switchSession(String sessionId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentSession = _currentGame!.sessions.firstWhere((s) => s.id == sessionId);
    
    await _saveGames();
    notifyListeners();
  }

  // Create a new journal entry
  Future<JournalEntry> createJournalEntry(String content) async {
    if (_currentGame == null || _currentSession == null) {
      throw Exception('No game or session selected');
    }
    
    final entry = _currentSession!.createNewEntry(content);
    
    await _saveGames();
    notifyListeners();
    
    return entry;
  }

  // Update a journal entry
  Future<void> updateJournalEntry(String entryId, String content) async {
    if (_currentGame == null || _currentSession == null) {
      throw Exception('No game or session selected');
    }
    
    final entry = _currentSession!.entries.firstWhere((e) => e.id == entryId);
    entry.update(content);
    
    await _saveGames();
    notifyListeners();
  }
  
  // Quest-related methods
  
  // Create a new quest
  Future<Quest> createQuest(
    String title,
    String characterId,
    QuestRank rank, {
    String notes = '',
  }) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    // Verify the character exists
    _currentGame!.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => throw Exception('Character not found'),
    );
    
    final quest = Quest(
      title: title,
      characterId: characterId,
      rank: rank,
      notes: notes,
    );
    
    _currentGame!.quests.add(quest);
    
    await _saveGames();
    notifyListeners();
    
    return quest;
  }
  
  // Update quest progress in boxes (0-10)
  Future<void> updateQuestProgress(String questId, int progress) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    // Ensure progress is within bounds
    final newProgress = progress.clamp(0, 10);
    quest.updateProgress(newProgress);
    
    await _saveGames();
    notifyListeners();
  }
  
  
  // Update quest progress in ticks (0-40)
  Future<void> updateQuestProgressTicks(String questId, int ticks) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.updateProgressTicks(ticks);
    
    await _saveGames();
    notifyListeners();
  }
  
  // Add a single tick to quest progress
  Future<void> addQuestTick(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.addTick();
    
    await _saveGames();
    notifyListeners();
  }
  
  // Remove a single tick from quest progress
  Future<void> removeQuestTick(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.removeTick();
    
    await _saveGames();
    notifyListeners();
  }
  
  // Add ticks based on quest rank
  Future<void> addQuestTicksForRank(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.addTicksForRank();
    
    await _saveGames();
    notifyListeners();
  }
  
  // Remove ticks based on quest rank
  Future<void> removeQuestTicksForRank(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.removeTicksForRank();
    
    await _saveGames();
    notifyListeners();
  }
  
  // Update quest notes
  Future<void> updateQuestNotes(String questId, String notes) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.notes = notes;
    
    await _saveGames();
    notifyListeners();
  }
  
  // Complete a quest
  Future<void> completeQuest(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.complete();
    
    // Create a journal entry for the completed quest
    if (_currentSession != null) {
      final character = _currentGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );
      
      final entry = _currentSession!.createNewEntry(
        'Quest "${quest.title}" completed by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );
      
      // Add metadata to indicate this entry was created from a quest
      entry.metadata = {'sourceScreen': 'quests'};
    }
    
    await _saveGames();
    notifyListeners();
  }
  
  // Forsake a quest
  Future<void> forsakeQuest(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    quest.forsake();
    
    // Create a journal entry for the forsaken quest
    if (_currentSession != null) {
      final character = _currentGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );
      
      final entry = _currentSession!.createNewEntry(
        'Quest "${quest.title}" forsaken by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );
      
      // Add metadata to indicate this entry was created from a quest
      entry.metadata = {'sourceScreen': 'quests'};
    }
    
    await _saveGames();
    notifyListeners();
  }
  
  // Delete a quest
  Future<void> deleteQuest(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.quests.removeWhere((q) => q.id == questId);
    
    await _saveGames();
    notifyListeners();
  }
  
  // Sentient AI-related methods
  
  // Update sentientAiEnabled setting
  Future<void> updateSentientAiEnabled(bool enabled) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.sentientAiEnabled = enabled;
    
    await _saveGames();
    notifyListeners();
  }
  
  // Update sentientAiName setting
  Future<void> updateSentientAiName(String? name) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.sentientAiName = name;
    
    await _saveGames();
    notifyListeners();
  }
  
  // Update sentientAiPersona setting
  Future<void> updateSentientAiPersona(String? persona) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.sentientAiPersona = persona;
    
    await _saveGames();
    notifyListeners();
  }
  
  // Update sentientAiImagePath setting
  Future<void> updateSentientAiImagePath(String? imagePath) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.sentientAiImagePath = imagePath;
    
    await _saveGames();
    notifyListeners();
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
  
  // Clock-related methods
  
  // Create a new clock
  Future<Clock> createClock(
    String title,
    int segments,
    ClockType type,
  ) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    // Validate segments (must be 4, 6, 8, or 10)
    if (![4, 6, 8, 10].contains(segments)) {
      throw Exception('Invalid number of segments. Must be 4, 6, 8, or 10.');
    }
    
    final clock = Clock(
      title: title,
      segments: segments,
      type: type,
    );
    
    _currentGame!.addClock(clock);
    
    await _saveGames();
    notifyListeners();
    
    return clock;
  }
  
  // Update a clock's title
  Future<void> updateClockTitle(String clockId, String title) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final clock = _currentGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );
    
    clock.title = title;
    
    await _saveGames();
    notifyListeners();
  }
  
  // Advance a clock by one segment
  Future<void> advanceClock(String clockId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final clock = _currentGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );
    
    // Advance the clock
    clock.advance();
    
    // Create a journal entry if the clock is now complete
    if (clock.isComplete && _currentSession != null) {
      _currentSession!.createNewEntry(
        'Clock "${clock.title}" has filled completely.\n'
        'Type: ${clock.type.displayName}\n'
        'Segments: ${clock.progress}/${clock.segments}'
      );
    }
    
    await _saveGames();
    notifyListeners();
  }
  
  // Reset a clock's progress
  Future<void> resetClock(String clockId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final clock = _currentGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );
    
    clock.reset();
    
    await _saveGames();
    notifyListeners();
  }
  
  // Delete a clock
  Future<void> deleteClock(String clockId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    _currentGame!.clocks.removeWhere((c) => c.id == clockId);
    
    await _saveGames();
    notifyListeners();
  }
  
  // Advance all clocks of a specific type
  Future<void> advanceAllClocksOfType(ClockType type) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final clocks = _currentGame!.getClocksByType(type);
    bool anyCompleted = false;
    
    for (final clock in clocks) {
      if (!clock.isComplete) {
        clock.advance();
        
        if (clock.isComplete) {
          anyCompleted = true;
        }
      }
    }
    
    // Create a journal entry if any clocks were completed
    if (anyCompleted && _currentSession != null) {
      final completedClocks = clocks.where((c) => c.isComplete && c.completedAt != null);
      
      if (completedClocks.isNotEmpty) {
        final clockNames = completedClocks.map((c) => '"${c.title}"').join(', ');
        _currentSession!.createNewEntry(
          'The following ${type.displayName} clocks have filled completely: $clockNames'
        );
      }
    }
    
    await _saveGames();
    notifyListeners();
  }
  
  // Make a progress roll for a quest
  Future<Map<String, dynamic>> makeQuestProgressRoll(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    // Only full boxes (progress) count for progress rolls
    final result = DiceRoller.rollProgressMove(progressValue: quest.progress);
    
    // Create a journal entry for the roll result
    if (_currentSession != null) {
      final character = _currentGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );
      
      final entry = _currentSession!.createNewEntry(
        'Progress roll for quest "${quest.title}" by ${character.name}.\n'
        'Progress: ${quest.progress}/10 (${quest.progressTicks} ticks)\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );
      
      // Add metadata to indicate this entry was created from a quest
      entry.metadata = {'sourceScreen': 'quests'};
    }
    
    await _saveGames();
    notifyListeners();
    
    return result;
  }

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
      
      await _saveGames();
      notifyListeners();
      
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
