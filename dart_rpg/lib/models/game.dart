import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'character.dart';
import 'location.dart';
import 'session.dart';

class Game {
  final String id;
  String name;
  DateTime createdAt;
  DateTime lastPlayedAt;
  List<Character> characters;
  List<Location> locations;
  List<Session> sessions;
  Character? mainCharacter;
  String? dataswornSource;
  Location? rigLocation;

  Game({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
    List<Character>? characters,
    List<Location>? locations,
    List<Session>? sessions,
    this.mainCharacter,
    this.dataswornSource,
    this.rigLocation,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now(),
        characters = characters ?? [],
        locations = locations ?? [],
        sessions = sessions ?? [] {
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
    return {
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
    };
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
      mainCharacter: mainChar,
      dataswornSource: json['dataswornSource'],
      rigLocation: rigLoc,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Game.fromJsonString(String jsonString) {
    return Game.fromJson(jsonDecode(jsonString));
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

  Session createNewSession(String title) {
    final session = Session(
      title: title,
      gameId: id,
    );
    sessions.add(session);
    return session;
  }
}
