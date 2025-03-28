import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/game.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../models/journal_entry.dart';
import '../models/quest.dart';
import '../utils/logging_service.dart';
import '../utils/dice_roller.dart';

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

  GameProvider() {
    _loadGames();
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
  Future<Game> createGame(String name, {String? dataswornSource}) async {
    final game = Game(
      name: name,
      dataswornSource: dataswornSource,
    );
    
    _games.add(game);
    _currentGame = game;
    _currentSession = null;
    
    await _saveGames();
    notifyListeners();
    
    return game;
  }

  // Switch to a different game
  Future<void> switchGame(String gameId) async {
    final game = _games.firstWhere((g) => g.id == gameId);
    
    _currentGame = game;
    _currentGame!.updateLastPlayed();
    
    if (_currentGame!.sessions.isNotEmpty) {
      _currentSession = _currentGame!.sessions.first;
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
      _currentSession = _currentGame?.sessions.isNotEmpty ?? false
          ? _currentGame!.sessions.first
          : null;
    }
    
    await _saveGames();
    notifyListeners();
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
    final character = _currentGame!.characters.firstWhere(
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
  
  // Update quest progress
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
      
      _currentSession!.createNewEntry(
        'Quest "${quest.title}" completed by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );
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
      
      _currentSession!.createNewEntry(
        'Quest "${quest.title}" forsaken by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );
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
  
  // Make a progress roll for a quest
  Future<Map<String, dynamic>> makeQuestProgressRoll(String questId) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final quest = _currentGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );
    
    final result = DiceRoller.rollProgressMove(progressValue: quest.progress);
    
    // Create a journal entry for the roll result
    if (_currentSession != null) {
      final character = _currentGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );
      
      _currentSession!.createNewEntry(
        'Progress roll for quest "${quest.title}" by ${character.name}.\n'
        'Progress: ${quest.progress}/10\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );
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
