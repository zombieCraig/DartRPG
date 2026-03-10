import 'dart:convert';
import 'game.dart';

/// Lightweight summary of a Game for the game list UI.
///
/// Avoids deserializing the full game (sessions, journal entries, etc.)
/// just to display the game selection screen.
class GameSummary {
  final String id;
  String name;
  DateTime lastPlayedAt;
  int sessionCount;
  int characterCount;
  String? dataswornSource;
  bool hasMainCharacter;

  GameSummary({
    required this.id,
    required this.name,
    required this.lastPlayedAt,
    this.sessionCount = 0,
    this.characterCount = 0,
    this.dataswornSource,
    this.hasMainCharacter = false,
  });

  /// Extract a summary from a full Game object.
  factory GameSummary.fromGame(Game game) {
    return GameSummary(
      id: game.id,
      name: game.name,
      lastPlayedAt: game.lastPlayedAt,
      sessionCount: game.sessions.length,
      characterCount: game.characters.length,
      dataswornSource: game.dataswornSource,
      hasMainCharacter: game.mainCharacter != null,
    );
  }

  /// Parse summary fields directly from game JSON without constructing
  /// the full Game object (migration path).
  factory GameSummary.fromGameJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
      sessionCount: (json['sessions'] as List?)?.length ?? 0,
      characterCount: (json['characters'] as List?)?.length ?? 0,
      dataswornSource: json['dataswornSource'] as String?,
      hasMainCharacter: json['mainCharacterId'] != null,
    );
  }

  factory GameSummary.fromJson(Map<String, dynamic> json) {
    return GameSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      lastPlayedAt: DateTime.parse(json['lastPlayedAt'] as String),
      sessionCount: json['sessionCount'] as int? ?? 0,
      characterCount: json['characterCount'] as int? ?? 0,
      dataswornSource: json['dataswornSource'] as String?,
      hasMainCharacter: json['hasMainCharacter'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lastPlayedAt': lastPlayedAt.toIso8601String(),
      'sessionCount': sessionCount,
      'characterCount': characterCount,
      'dataswornSource': dataswornSource,
      'hasMainCharacter': hasMainCharacter,
    };
  }

  static List<GameSummary> listFromJsonString(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    return list.map((e) => GameSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJsonString(List<GameSummary> summaries) {
    return jsonEncode(summaries.map((s) => s.toJson()).toList());
  }
}
