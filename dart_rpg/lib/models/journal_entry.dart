import 'package:uuid/uuid.dart';

class MoveRoll {
  final String id;
  String moveName;
  String? moveDescription;
  String? stat;
  int? statValue;
  int actionDie;
  List<int> challengeDice;
  String outcome; // "strong hit", "weak hit", or "miss"
  DateTime timestamp;

  MoveRoll({
    String? id,
    required this.moveName,
    this.moveDescription,
    this.stat,
    this.statValue,
    required this.actionDie,
    required this.challengeDice,
    required this.outcome,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moveName': moveName,
      'moveDescription': moveDescription,
      'stat': stat,
      'statValue': statValue,
      'actionDie': actionDie,
      'challengeDice': challengeDice,
      'outcome': outcome,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MoveRoll.fromJson(Map<String, dynamic> json) {
    return MoveRoll(
      id: json['id'],
      moveName: json['moveName'],
      moveDescription: json['moveDescription'],
      stat: json['stat'],
      statValue: json['statValue'],
      actionDie: json['actionDie'],
      challengeDice: (json['challengeDice'] as List).cast<int>(),
      outcome: json['outcome'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class OracleRoll {
  final String id;
  String oracleName;
  String? oracleTable;
  List<int> dice;
  String result;
  DateTime timestamp;

  OracleRoll({
    String? id,
    required this.oracleName,
    this.oracleTable,
    required this.dice,
    required this.result,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oracleName': oracleName,
      'oracleTable': oracleTable,
      'dice': dice,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OracleRoll.fromJson(Map<String, dynamic> json) {
    return OracleRoll(
      id: json['id'],
      oracleName: json['oracleName'],
      oracleTable: json['oracleTable'],
      dice: (json['dice'] as List).cast<int>(),
      result: json['result'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class JournalEntry {
  final String id;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> linkedCharacterIds;
  List<String> linkedLocationIds;
  MoveRoll? moveRoll;
  OracleRoll? oracleRoll;

  JournalEntry({
    String? id,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
    this.moveRoll,
    this.oracleRoll,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        linkedCharacterIds = linkedCharacterIds ?? [],
        linkedLocationIds = linkedLocationIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'linkedCharacterIds': linkedCharacterIds,
      'linkedLocationIds': linkedLocationIds,
      'moveRoll': moveRoll?.toJson(),
      'oracleRoll': oracleRoll?.toJson(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      linkedCharacterIds: (json['linkedCharacterIds'] as List?)?.cast<String>() ?? [],
      linkedLocationIds: (json['linkedLocationIds'] as List?)?.cast<String>() ?? [],
      moveRoll: json['moveRoll'] != null
          ? MoveRoll.fromJson(json['moveRoll'])
          : null,
      oracleRoll: json['oracleRoll'] != null
          ? OracleRoll.fromJson(json['oracleRoll'])
          : null,
    );
  }

  void update(String newContent) {
    content = newContent;
    updatedAt = DateTime.now();
  }

  void linkCharacter(String characterId) {
    if (!linkedCharacterIds.contains(characterId)) {
      linkedCharacterIds.add(characterId);
    }
  }

  void unlinkCharacter(String characterId) {
    linkedCharacterIds.remove(characterId);
  }

  void linkLocation(String locationId) {
    if (!linkedLocationIds.contains(locationId)) {
      linkedLocationIds.add(locationId);
    }
  }

  void unlinkLocation(String locationId) {
    linkedLocationIds.remove(locationId);
  }

  void attachMoveRoll(MoveRoll roll) {
    moveRoll = roll;
  }

  void attachOracleRoll(OracleRoll roll) {
    oracleRoll = roll;
  }
}
