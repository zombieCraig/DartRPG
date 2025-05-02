import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../utils/logging_service.dart';
import 'character.dart';
import 'clock.dart';
import 'location.dart';
import 'session.dart';
import 'quest.dart';

class Game {
  final String id;
  String name;
  DateTime createdAt;
  DateTime lastPlayedAt;
  List<Character> characters;
  List<Location> locations;
  List<Session> sessions;
  List<Quest> quests;
  List<Clock> clocks;
  Character? mainCharacter;
  String? dataswornSource;
  Location? rigLocation;
  bool tutorialsEnabled;
  
  // Sentient AI settings
  bool sentientAiEnabled;
  String? sentientAiName;
  String? sentientAiPersona;
  String? sentientAiImagePath;
  
  // AI Image Generation settings
  bool aiImageGenerationEnabled;
  String? aiImageProvider; // e.g., "minimax" or "openai"
  String? openaiModel; // e.g., "dall-e-2", "dall-e-3", or "gpt-image-1"
  Map<String, String> aiApiKeys = {}; // Store keys for different providers
  Map<String, String> aiArtisticDirections = {}; // Store artistic directions for different providers
  
  // World Truths settings
  Map<String, String?> selectedTruths = {}; // Maps truth ID to selected option ID (or null if none selected)

  Game({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    List<Character>? characters,
    List<Location>? locations,
    List<Session>? sessions,
    List<Quest>? quests,
    List<Clock>? clocks,
    this.mainCharacter,
    this.dataswornSource,
    this.rigLocation,
    this.tutorialsEnabled = true,
    this.sentientAiEnabled = false,
    this.sentientAiName,
    this.sentientAiPersona,
    this.sentientAiImagePath,
    this.aiImageGenerationEnabled = false,
    this.aiImageProvider,
    this.openaiModel = 'dall-e-2',
    Map<String, String>? aiApiKeys,
    Map<String, String>? aiArtisticDirections,
    Map<String, String?>? selectedTruths,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now(),
        characters = characters ?? [],
        locations = locations ?? [],
        sessions = sessions ?? [],
        quests = quests ?? [],
        clocks = clocks ?? [] {
    // Initialize aiApiKeys if provided
    if (aiApiKeys != null) {
      this.aiApiKeys = Map<String, String>.from(aiApiKeys);
      LoggingService().debug(
        'Initialized Game with API keys: ${this.aiApiKeys.keys.join(", ")}',
        tag: 'Game'
      );
    }
    
    // Initialize aiArtisticDirections if provided
    if (aiArtisticDirections != null) {
      this.aiArtisticDirections = Map<String, String>.from(aiArtisticDirections);
      LoggingService().debug(
        'Initialized Game with artistic directions: ${this.aiArtisticDirections.keys.join(", ")}',
        tag: 'Game'
      );
    }
    
    // Initialize selectedTruths if provided
    if (selectedTruths != null) {
      this.selectedTruths = Map<String, String?>.from(selectedTruths);
      LoggingService().debug(
        'Initialized Game with ${this.selectedTruths.length} selected truths',
        tag: 'Game'
      );
    }
    
    // Set default artistic direction for Minimax if not provided
    if (!this.aiArtisticDirections.containsKey('minimax')) {
      this.aiArtisticDirections['minimax'] = "cyberpunk scene, digital art, detailed illustration";
      LoggingService().debug(
        'Set default artistic direction for Minimax',
        tag: 'Game'
      );
    }
    
    // Create "Your Rig" location if it doesn't exist and no locations are provided
    if (locations == null || locations.isEmpty) {
      createRigLocation();
    }
  }
  
  void createRigLocation() {
    final rig = Location(
      name: 'Your Rig',
      description: 'Your personal computer system and starting point in the network.',
      segment: LocationSegment.core,
    );
    locations.add(rig);
    rigLocation = rig;
  }

  Map<String, dynamic> toJson() {
    // Log API keys information before serialization
    final loggingService = LoggingService();
    if (aiImageGenerationEnabled && aiImageProvider != null) {
      loggingService.debug(
        'Serializing game with API keys: ${aiApiKeys.keys.join(", ")}',
        tag: 'Game'
      );
      
      if (aiApiKeys.isEmpty) {
        loggingService.warning(
          'Game has AI image generation enabled but no API keys to serialize',
          tag: 'Game'
        );
      }
    }
    
    // Convert aiApiKeys to a Map<String, dynamic> for JSON serialization
    final Map<String, dynamic> apiKeysJson = {};
    aiApiKeys.forEach((key, value) {
      apiKeysJson[key] = value;
      loggingService.debug(
        'Adding API key for provider $key to JSON (length: ${value.length})',
        tag: 'Game'
      );
    });
    
    // Convert aiArtisticDirections to a Map<String, dynamic> for JSON serialization
    final Map<String, dynamic> artisticDirectionsJson = {};
    aiArtisticDirections.forEach((key, value) {
      artisticDirectionsJson[key] = value;
      loggingService.debug(
        'Adding artistic direction for provider $key to JSON',
        tag: 'Game'
      );
    });
    
    final json = {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'characters': characters.map((c) => c.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'mainCharacterId': mainCharacter?.id,
      'dataswornSource': dataswornSource,
      'rigLocationId': rigLocation?.id,
      'quests': quests.map((q) => q.toJson()).toList(),
      'clocks': clocks.map((c) => c.toJson()).toList(),
      'tutorialsEnabled': tutorialsEnabled,
      'sentientAiEnabled': sentientAiEnabled,
      'sentientAiName': sentientAiName,
      'sentientAiPersona': sentientAiPersona,
      'sentientAiImagePath': sentientAiImagePath,
      'aiImageGenerationEnabled': aiImageGenerationEnabled,
      'aiImageProvider': aiImageProvider,
      'openaiModel': openaiModel,
      'aiApiKeys': apiKeysJson,
      'aiArtisticDirections': artisticDirectionsJson,
      'selectedTruths': selectedTruths,
    };
    
    // Verify aiApiKeys is in the JSON
    if (aiImageGenerationEnabled && aiImageProvider != null) {
      if (json.containsKey('aiApiKeys')) {
        loggingService.debug(
          'JSON contains aiApiKeys field',
          tag: 'Game'
        );
      } else {
        loggingService.warning(
          'JSON does NOT contain aiApiKeys field',
          tag: 'Game'
        );
      }
    }
    
    return json;
  }

  // Helper method to properly parse artistic directions from JSON
  static Map<String, String> _parseArtisticDirections(dynamic artisticDirectionsJson) {
    final loggingService = LoggingService();
    
    if (artisticDirectionsJson == null) {
      loggingService.debug('No artistic directions found in JSON', tag: 'Game');
      return {};
    }
    
    try {
      // First, convert to a Map<String, dynamic>
      final Map<String, dynamic> dynamicMap = Map<String, dynamic>.from(artisticDirectionsJson);
      
      // Then, explicitly convert each value to a string
      final Map<String, String> stringMap = {};
      dynamicMap.forEach((key, value) {
        stringMap[key] = value.toString();
        loggingService.debug('Parsed artistic direction for provider: $key', tag: 'Game');
      });
      
      return stringMap;
    } catch (e) {
      loggingService.error(
        'Failed to parse artistic directions from JSON',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current
      );
      return {};
    }
  }
  
  // Helper method to parse selected truths from JSON
  static Map<String, String?> _parseSelectedTruths(dynamic selectedTruthsJson) {
    final loggingService = LoggingService();
    
    if (selectedTruthsJson == null) {
      loggingService.debug('No selected truths found in JSON', tag: 'Game');
      return {};
    }
    
    try {
      // First, convert to a Map<String, dynamic>
      final Map<String, dynamic> dynamicMap = Map<String, dynamic>.from(selectedTruthsJson);
      
      // Then, convert to a Map<String, String?>
      final Map<String, String?> truthsMap = {};
      dynamicMap.forEach((key, value) {
        truthsMap[key] = value as String?;
        loggingService.debug('Parsed selected truth: $key -> $value', tag: 'Game');
      });
      
      return truthsMap;
    } catch (e) {
      loggingService.error(
        'Failed to parse selected truths from JSON',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current
      );
      return {};
    }
  }
  
  factory Game.fromJson(Map<String, dynamic> json) {
    final List<Character> characters = (json['characters'] as List)
        .map((c) => Character.fromJson(c))
        .toList();
    
    final List<Location> locations = (json['locations'] as List)
        .map((l) => Location.fromJson(l))
        .toList();
    
    final String? mainCharacterId = json['mainCharacterId'];
    Character? mainChar;
    
    if (mainCharacterId != null && characters.isNotEmpty) {
      mainChar = characters.firstWhere(
        (c) => c.id == mainCharacterId,
        orElse: () => characters.first,
      );
    }
    
    final String? rigLocationId = json['rigLocationId'];
    Location? rigLoc;
    
    if (rigLocationId != null && locations.isNotEmpty) {
      try {
        rigLoc = locations.firstWhere(
          (l) => l.id == rigLocationId,
        );
      } catch (_) {
        // If rig location not found, don't set it
      }
    }

    return Game(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt']),
      characters: characters,
      locations: locations,
      sessions: (json['sessions'] as List)
          .map((s) => Session.fromJson(s))
          .toList(),
      quests: (json['quests'] as List?)
          ?.map((q) => Quest.fromJson(q))
          .toList() ?? [],
      clocks: (json['clocks'] as List?)
          ?.map((c) => Clock.fromJson(c))
          .toList() ?? [],
      mainCharacter: mainChar,
      dataswornSource: json['dataswornSource'],
      rigLocation: rigLoc,
      tutorialsEnabled: json['tutorialsEnabled'] ?? true,
      sentientAiEnabled: json['sentientAiEnabled'] ?? false,
      sentientAiName: json['sentientAiName'],
      sentientAiPersona: json['sentientAiPersona'],
      sentientAiImagePath: json['sentientAiImagePath'],
      aiImageGenerationEnabled: json['aiImageGenerationEnabled'] ?? false,
      aiImageProvider: json['aiImageProvider'],
      openaiModel: json['openaiModel'] ?? 'dall-e-2',
      aiApiKeys: _parseApiKeys(json['aiApiKeys']),
      aiArtisticDirections: _parseArtisticDirections(json['aiArtisticDirections']),
      selectedTruths: _parseSelectedTruths(json['selectedTruths']),
    );
  }

  // Helper method to properly parse API keys from JSON
  static Map<String, String> _parseApiKeys(dynamic apiKeysJson) {
    final loggingService = LoggingService();
    
    if (apiKeysJson == null) {
      loggingService.debug('No API keys found in JSON', tag: 'Game');
      return {};
    }
    
    try {
      // First, convert to a Map<String, dynamic>
      final Map<String, dynamic> dynamicMap = Map<String, dynamic>.from(apiKeysJson);
      
      // Then, explicitly convert each value to a string
      final Map<String, String> stringMap = {};
      dynamicMap.forEach((key, value) {
        stringMap[key] = value.toString();
        loggingService.debug('Parsed API key for provider: $key', tag: 'Game');
      });
      
      return stringMap;
    } catch (e) {
      loggingService.error(
        'Failed to parse API keys from JSON',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current
      );
      return {};
    }
  }

  String toJsonString() => jsonEncode(toJson());

  factory Game.fromJsonString(String jsonString) {
    final loggingService = LoggingService();
    
    try {
      // Check if the JSON string contains aiApiKeys
      if (jsonString.contains('"aiApiKeys":{')) {
        loggingService.debug(
          'JSON string contains aiApiKeys field',
          tag: 'Game'
        );
      } else if (jsonString.contains('"aiApiKeys":{}')) {
        loggingService.debug(
          'JSON string contains empty aiApiKeys field',
          tag: 'Game'
        );
      } else if (jsonString.contains('"aiApiKeys":null')) {
        loggingService.debug(
          'JSON string contains null aiApiKeys field',
          tag: 'Game'
        );
      } else if (jsonString.contains('"aiApiKeys"')) {
        loggingService.debug(
          'JSON string contains aiApiKeys field but in unknown format',
          tag: 'Game'
        );
      } else {
        loggingService.warning(
          'JSON string does NOT contain aiApiKeys field',
          tag: 'Game'
        );
      }
      
      // Decode the JSON string
      final jsonMap = jsonDecode(jsonString);
      
      // Check if the decoded JSON contains aiApiKeys
      if (jsonMap.containsKey('aiApiKeys')) {
        final apiKeys = jsonMap['aiApiKeys'];
        if (apiKeys != null) {
          if (apiKeys is Map) {
            loggingService.debug(
              'Decoded JSON contains aiApiKeys map with ${apiKeys.length} entries',
              tag: 'Game'
            );
          } else {
            loggingService.warning(
              'Decoded JSON contains aiApiKeys but it is not a map: ${apiKeys.runtimeType}',
              tag: 'Game'
            );
          }
        } else {
          loggingService.debug(
            'Decoded JSON contains null aiApiKeys',
            tag: 'Game'
          );
        }
      } else {
        loggingService.warning(
          'Decoded JSON does NOT contain aiApiKeys field',
          tag: 'Game'
        );
      }
      
      return Game.fromJson(jsonMap);
    } catch (e) {
      loggingService.error(
        'Failed to parse game JSON string',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current
      );
      rethrow;
    }
  }

  void updateLastPlayed() {
    lastPlayedAt = DateTime.now();
  }

  void addCharacter(Character character) {
    characters.add(character);
    mainCharacter ??= character;
  }

  void addLocation(Location location) {
    locations.add(location);
  }
  
  // Connect two locations by their IDs
  void connectLocations(String sourceId, String targetId) {
    if (sourceId == targetId) return; // Can't connect to self
    
    final sourceLocation = locations.firstWhere(
      (loc) => loc.id == sourceId,
      orElse: () => throw Exception('Source location not found'),
    );
    
    final targetLocation = locations.firstWhere(
      (loc) => loc.id == targetId,
      orElse: () => throw Exception('Target location not found'),
    );
    
    // Check if segments are adjacent
    if (!areSegmentsAdjacent(sourceLocation.segment, targetLocation.segment)) {
      throw Exception('Cannot connect locations in non-adjacent segments');
    }
    
    // Add bidirectional connection
    sourceLocation.addConnection(targetId);
    targetLocation.addConnection(sourceId);
  }
  
  // Disconnect two locations by their IDs
  void disconnectLocations(String sourceId, String targetId) {
    if (sourceId == targetId) return; // Can't disconnect from self
    
    final sourceLocation = locations.firstWhere(
      (loc) => loc.id == sourceId,
      orElse: () => throw Exception('Source location not found'),
    );
    
    final targetLocation = locations.firstWhere(
      (loc) => loc.id == targetId,
      orElse: () => throw Exception('Target location not found'),
    );
    
    // Remove bidirectional connection
    sourceLocation.removeConnection(targetId);
    targetLocation.removeConnection(sourceId);
  }
  
  // Check if two segments are adjacent in the progression
  bool areSegmentsAdjacent(LocationSegment a, LocationSegment b) {
    if (a == b) return true; // Same segment
    
    switch (a) {
      case LocationSegment.core:
        return b == LocationSegment.corpNet;
      case LocationSegment.corpNet:
        return b == LocationSegment.core || b == LocationSegment.govNet;
      case LocationSegment.govNet:
        return b == LocationSegment.corpNet || b == LocationSegment.darkNet;
      case LocationSegment.darkNet:
        return b == LocationSegment.govNet;
    }
  }
  
  // Get all locations that can be connected to the given location based on segment rules
  List<Location> getValidConnectionsForLocation(String locationId) {
    final location = locations.firstWhere(
      (loc) => loc.id == locationId,
      orElse: () => throw Exception('Location not found'),
    );
    
    return locations.where((loc) => 
      loc.id != locationId && // Not the same location
      areSegmentsAdjacent(location.segment, loc.segment) && // Segments are adjacent
      !location.isConnectedTo(loc.id) // Not already connected
    ).toList();
  }

  void addSession(Session session) {
    sessions.add(session);
  }
  
  // Quest-related methods
  
  // Add a quest
  void addQuest(Quest quest) {
    quests.add(quest);
  }
  
  // Clock-related methods
  
  // Add a clock
  void addClock(Clock clock) {
    clocks.add(clock);
  }
  
  // Get clocks by type
  List<Clock> getClocksByType(ClockType type) {
    return clocks.where((clock) => clock.type == type).toList();
  }
  
  // Get all clocks
  List<Clock> getAllClocks() {
    return List.from(clocks);
  }
  
  // Get quests for a specific character
  List<Quest> getQuestsForCharacter(String characterId) {
    return quests.where((quest) => quest.characterId == characterId).toList();
  }
  
  // Get all characters with stats (non-NPCs)
  List<Character> getCharactersWithStats() {
    return characters.where((character) => character.stats.isNotEmpty).toList();
  }

  Session createNewSession(String title) {
    final session = Session(
      title: title,
      gameId: id,
    );
    sessions.add(session);
    return session;
  }
  
  // AI Image Generation methods
  
  // Set the AI image generation enabled flag
  void setAiImageGenerationEnabled(bool enabled) {
    aiImageGenerationEnabled = enabled;
  }
  
  // Set the AI image provider
  void setAiImageProvider(String? provider) {
    aiImageProvider = provider;
  }
  
  // Set the OpenAI model
  void setOpenAiModel(String model) {
    openaiModel = model;
  }
  
  // Get the OpenAI model or default
  String getOpenAiModelOrDefault() {
    return openaiModel ?? 'dall-e-2';
  }
  
  // Set an API key for a specific provider
  void setAiApiKey(String provider, String apiKey) {
    final loggingService = LoggingService();
    loggingService.debug(
      'Setting API key for provider: $provider with length: ${apiKey.length}',
      tag: 'Game'
    );
    
    // Store the API key
    aiApiKeys[provider] = apiKey;
    
    // Verify the API key was set correctly
    if (aiApiKeys.containsKey(provider)) {
      final storedKey = aiApiKeys[provider];
      if (storedKey != null) {
        loggingService.debug(
          'API key for $provider was set successfully with length: ${storedKey.length}',
          tag: 'Game'
        );
      } else {
        loggingService.warning(
          'API key for $provider was set but is null',
          tag: 'Game'
        );
      }
    } else {
      loggingService.warning(
        'Failed to set API key for $provider',
        tag: 'Game'
      );
    }
  }
  
  // Get the API key for a specific provider
  String? getAiApiKey(String provider) {
    return aiApiKeys[provider];
  }
  
  // Remove an API key for a specific provider
  void removeAiApiKey(String provider) {
    aiApiKeys.remove(provider);
  }
  
  // Check if AI image generation is available
  bool isAiImageGenerationAvailable() {
    if (!aiImageGenerationEnabled) return false;
    if (aiImageProvider == null) return false;
    return aiApiKeys.containsKey(aiImageProvider!);
  }
  
  // Set an artistic direction for a specific provider
  void setAiArtisticDirection(String provider, String artisticDirection) {
    final loggingService = LoggingService();
    loggingService.debug(
      'Setting artistic direction for provider: $provider',
      tag: 'Game'
    );
    
    // Store the artistic direction
    aiArtisticDirections[provider] = artisticDirection;
    
    // Verify the artistic direction was set correctly
    if (aiArtisticDirections.containsKey(provider)) {
      final storedDirection = aiArtisticDirections[provider];
      if (storedDirection != null) {
        loggingService.debug(
          'Artistic direction for $provider was set successfully',
          tag: 'Game'
        );
      } else {
        loggingService.warning(
          'Artistic direction for $provider was set but is null',
          tag: 'Game'
        );
      }
    } else {
      loggingService.warning(
        'Failed to set artistic direction for $provider',
        tag: 'Game'
      );
    }
  }
  
  // Get the artistic direction for a specific provider
  String? getAiArtisticDirection(String provider) {
    return aiArtisticDirections[provider];
  }
  
  // Get the artistic direction for the current provider, or a default if not set
  String getAiArtisticDirectionOrDefault() {
    if (aiImageProvider != null && aiArtisticDirections.containsKey(aiImageProvider!)) {
      return aiArtisticDirections[aiImageProvider!]!;
    }
    return "cyberpunk scene, digital art, detailed illustration";
  }
  
  // Truth-related methods
  
  // Set a truth option
  void setTruth(String truthId, String? optionId) {
    final loggingService = LoggingService();
    loggingService.debug(
      'Setting truth $truthId to option $optionId',
      tag: 'Game'
    );
    
    selectedTruths[truthId] = optionId;
  }
  
  // Get the selected option for a truth
  String? getSelectedTruthOption(String truthId) {
    return selectedTruths[truthId];
  }
  
  // Clear all selected truths
  void clearAllTruths() {
    selectedTruths.clear();
  }
}
