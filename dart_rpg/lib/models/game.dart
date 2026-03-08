import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import '../utils/logging_service.dart';
import 'ai_config.dart';
import 'character.dart';
import 'clock.dart';
import 'location.dart';
import 'recent_move_entry.dart';
import 'session.dart';
import 'quest.dart';
import 'connection.dart';

class Game {
  final String id;
  String name;
  DateTime createdAt;
  DateTime lastPlayedAt;
  List<Character> characters;
  List<Location> locations;
  List<Session> sessions;
  List<Quest> quests;
  List<Connection> connections;
  List<Clock> clocks;
  Character? mainCharacter;
  String? dataswornSource;
  Location? rigLocation;
  bool tutorialsEnabled;

  // AI configuration (sentient AI + image generation)
  AiConfig aiConfig;

  // Recent moves for Quick Roll Panel
  List<RecentMoveEntry> recentMoves;

  // World Truths settings
  Map<String, String?> selectedTruths = {};

  Game({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    List<Character>? characters,
    List<Location>? locations,
    List<Session>? sessions,
    List<Quest>? quests,
    List<Connection>? connections,
    List<Clock>? clocks,
    this.mainCharacter,
    this.dataswornSource,
    this.rigLocation,
    this.tutorialsEnabled = true,
    List<RecentMoveEntry>? recentMoves,
    // AI config fields (passed through to AiConfig)
    bool sentientAiEnabled = false,
    String? sentientAiName,
    String? sentientAiPersona,
    String? sentientAiImagePath,
    bool aiImageGenerationEnabled = false,
    String? aiImageProvider,
    String? openaiModel = 'dall-e-2',
    Map<String, String>? aiApiKeys,
    Map<String, String>? aiArtisticDirections,
    Map<String, String?>? selectedTruths,
    AiConfig? aiConfig,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now(),
        characters = characters ?? [],
        locations = locations ?? [],
        sessions = sessions ?? [],
        quests = quests ?? [],
        connections = connections ?? [],
        clocks = clocks ?? [],
        recentMoves = recentMoves ?? [],
        aiConfig = aiConfig ?? AiConfig(
          sentientAiEnabled: sentientAiEnabled,
          sentientAiName: sentientAiName,
          sentientAiPersona: sentientAiPersona,
          sentientAiImagePath: sentientAiImagePath,
          aiImageGenerationEnabled: aiImageGenerationEnabled,
          aiImageProvider: aiImageProvider,
          openaiModel: openaiModel,
          aiApiKeys: aiApiKeys,
          aiArtisticDirections: aiArtisticDirections,
        ) {
    if (selectedTruths != null) {
      this.selectedTruths = Map<String, String?>.from(selectedTruths);
    }

    // Create "Your Rig" location if no locations are provided
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
      'connections': connections.map((c) => c.toJson()).toList(),
      'clocks': clocks.map((c) => c.toJson()).toList(),
      'tutorialsEnabled': tutorialsEnabled,
      'recentMoves': recentMoves.map((r) => r.toJson()).toList(),
      'selectedTruths': selectedTruths,
    };

    // Merge AI config fields at top level for backward compatibility
    json.addAll(aiConfig.toJson());

    return json;
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
      rigLoc = locations.firstWhereOrNull(
        (l) => l.id == rigLocationId,
      );
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
      connections: (json['connections'] as List?)
          ?.map((c) => Connection.fromJson(c))
          .toList() ?? [],
      clocks: (json['clocks'] as List?)
          ?.map((c) => Clock.fromJson(c))
          .toList() ?? [],
      mainCharacter: mainChar,
      dataswornSource: json['dataswornSource'],
      rigLocation: rigLoc,
      tutorialsEnabled: json['tutorialsEnabled'] ?? true,
      recentMoves: (json['recentMoves'] as List?)
          ?.map((r) => RecentMoveEntry.fromJson(r))
          .toList() ?? [],
      aiConfig: AiConfig.fromJson(json),
      selectedTruths: _parseSelectedTruths(json['selectedTruths']),
    );
  }

  static Map<String, String?> _parseSelectedTruths(dynamic value) {
    if (value == null) return {};
    try {
      final map = Map<String, dynamic>.from(value);
      return map.map((k, v) => MapEntry(k, v as String?));
    } catch (e) {
      LoggingService().error(
        'Failed to parse selected truths from JSON',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current,
      );
      return {};
    }
  }

  String toJsonString() => jsonEncode(toJson());

  factory Game.fromJsonString(String jsonString) {
    try {
      return Game.fromJson(jsonDecode(jsonString));
    } catch (e) {
      LoggingService().error(
        'Failed to parse game JSON string',
        tag: 'Game',
        error: e,
        stackTrace: StackTrace.current,
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

  void connectLocations(String sourceId, String targetId) {
    if (sourceId == targetId) return;

    final sourceLocation = locations.firstWhereOrNull((loc) => loc.id == sourceId);
    if (sourceLocation == null) throw Exception('Source location not found');

    final targetLocation = locations.firstWhereOrNull((loc) => loc.id == targetId);
    if (targetLocation == null) throw Exception('Target location not found');

    if (!areSegmentsAdjacent(sourceLocation.segment, targetLocation.segment)) {
      throw Exception('Cannot connect locations in non-adjacent segments');
    }

    sourceLocation.addConnection(targetId);
    targetLocation.addConnection(sourceId);
  }

  void disconnectLocations(String sourceId, String targetId) {
    if (sourceId == targetId) return;

    final sourceLocation = locations.firstWhereOrNull((loc) => loc.id == sourceId);
    if (sourceLocation == null) throw Exception('Source location not found');

    final targetLocation = locations.firstWhereOrNull((loc) => loc.id == targetId);
    if (targetLocation == null) throw Exception('Target location not found');

    sourceLocation.removeConnection(targetId);
    targetLocation.removeConnection(sourceId);
  }

  bool areSegmentsAdjacent(LocationSegment a, LocationSegment b) {
    if (a == b) return true;

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

  List<Location> getValidConnectionsForLocation(String locationId) {
    final location = locations.firstWhereOrNull((loc) => loc.id == locationId);
    if (location == null) throw Exception('Location not found');

    return locations.where((loc) =>
      loc.id != locationId &&
      areSegmentsAdjacent(location.segment, loc.segment) &&
      !location.isConnectedTo(loc.id)
    ).toList();
  }

  void addSession(Session session) {
    sessions.add(session);
  }

  void addQuest(Quest quest) {
    quests.add(quest);
  }

  void addClock(Clock clock) {
    clocks.add(clock);
  }

  List<Clock> getClocksByType(ClockType type) {
    return clocks.where((clock) => clock.type == type).toList();
  }

  List<Clock> getAllClocks() {
    return List.from(clocks);
  }

  List<Quest> getQuestsForCharacter(String characterId) {
    return quests.where((quest) => quest.characterId == characterId).toList();
  }

  List<Connection> getConnectionsForCharacter(String characterId) {
    return connections.where((c) => c.characterId == characterId).toList();
  }

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

  // Recent moves methods

  static const int maxRecentMoves = 10;

  void recordMoveUse(String moveId, String moveName, String? stat) {
    final existing = recentMoves.firstWhereOrNull((r) => r.moveId == moveId);
    if (existing != null) {
      existing.useCount++;
      existing.lastUsed = DateTime.now();
      if (stat != null) existing.lastStat = stat;
    } else {
      recentMoves.add(RecentMoveEntry(
        moveId: moveId,
        moveName: moveName,
        lastStat: stat,
      ));
      // Trim non-favorites if over limit
      final nonFavorites = recentMoves.where((r) => !r.isFavorite).toList()
        ..sort((a, b) => a.lastUsed.compareTo(b.lastUsed));
      while (recentMoves.length > maxRecentMoves && nonFavorites.isNotEmpty) {
        recentMoves.remove(nonFavorites.removeAt(0));
      }
    }
  }

  void toggleMoveFavorite(String moveId) {
    final entry = recentMoves.firstWhereOrNull((r) => r.moveId == moveId);
    if (entry != null) {
      entry.isFavorite = !entry.isFavorite;
    }
  }

  List<RecentMoveEntry> get favoriteRecentMoves =>
      recentMoves.where((r) => r.isFavorite).toList()
        ..sort((a, b) => b.useCount.compareTo(a.useCount));

  List<RecentMoveEntry> get nonFavoriteRecentMoves =>
      recentMoves.where((r) => !r.isFavorite).toList()
        ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

  // Truth-related methods

  void setTruth(String truthId, String? optionId) {
    selectedTruths[truthId] = optionId;
  }

  String? getSelectedTruthOption(String truthId) {
    return selectedTruths[truthId];
  }

  void clearAllTruths() {
    selectedTruths.clear();
  }
}
