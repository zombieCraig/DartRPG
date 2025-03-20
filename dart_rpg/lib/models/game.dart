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
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastPlayedAt = lastPlayedAt ?? DateTime.now(),
        characters = characters ?? [],
        locations = locations ?? [],
        sessions = sessions ?? [];

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
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    final List<Character> characters = (json['characters'] as List)
        .map((c) => Character.fromJson(c))
        .toList();
    
    final String? mainCharacterId = json['mainCharacterId'];
    Character? mainChar;
    
    if (mainCharacterId != null && characters.isNotEmpty) {
      mainChar = characters.firstWhere(
        (c) => c.id == mainCharacterId,
        orElse: () => characters.first,
      );
    }

    return Game(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      lastPlayedAt: DateTime.parse(json['lastPlayedAt']),
      characters: characters,
      locations: (json['locations'] as List)
          .map((l) => Location.fromJson(l))
          .toList(),
      sessions: (json['sessions'] as List)
          .map((s) => Session.fromJson(s))
          .toList(),
      mainCharacter: mainChar,
      dataswornSource: json['dataswornSource'],
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
