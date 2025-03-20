import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../models/game.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../models/journal_entry.dart';

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
      
      print('Loading games from SharedPreferences: Found ${gameIds.length} game IDs');
      
      _games = [];
      for (final id in gameIds) {
        final gameJson = prefs.getString('game_$id');
        if (gameJson != null) {
          try {
            final game = Game.fromJsonString(gameJson);
            _games.add(game);
            print('Loaded game from SharedPreferences: ${game.name} (ID: ${game.id})');
          } catch (e) {
            print('Error loading game $id from SharedPreferences: $e');
          }
        } else {
          print('Game JSON not found in SharedPreferences for ID: $id');
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
      print('Saving games to SharedPreferences: ${gameIds.length} game IDs');
      
      // Save each game
      for (final game in _games) {
        final jsonString = game.toJsonString();
        await prefs.setString('game_${game.id}', jsonString);
        print('Saved game to SharedPreferences: ${game.name} (ID: ${game.id}) - JSON length: ${jsonString.length}');
      }
      
      // Save last played game and session
      if (_currentGame != null) {
        await prefs.setString('lastPlayedGameId', _currentGame!.id);
        print('Saved last played game ID to SharedPreferences: ${_currentGame!.id}');
        
        if (_currentSession != null) {
          await prefs.setString('lastSessionId_${_currentGame!.id}', _currentSession!.id);
          print('Saved last session ID to SharedPreferences: ${_currentSession!.id}');
        }
      }
    } catch (e) {
      _error = 'Failed to save games: ${e.toString()}';
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
  Future<Character> createCharacter(String name, {bool isMainCharacter = false}) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final character = isMainCharacter
        ? Character.createMainCharacter(name)
        : Character(name: name);
    
    _currentGame!.addCharacter(character);
    
    await _saveGames();
    notifyListeners();
    
    return character;
  }

  // Create a new location
  Future<Location> createLocation(String name, {String? description}) async {
    if (_currentGame == null) {
      throw Exception('No game selected');
    }
    
    final location = Location(
      name: name,
      description: description,
    );
    
    _currentGame!.addLocation(location);
    
    await _saveGames();
    notifyListeners();
    
    return location;
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
      notifyListeners();
      return null;
    }
  }
}
