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
  
  // New properties for enhanced move functionality
  String rollType; // "action_roll", "progress_roll", or "no_roll"
  int? progressValue; // For progress rolls
  int? modifier; // For action rolls with modifiers
  Map<String, dynamic>? moveData; // Store original move data for reference

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
    String? rollType,
    this.progressValue,
    this.modifier,
    this.moveData,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now(),
        rollType = rollType ?? 'action_roll';

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
      'rollType': rollType,
      'progressValue': progressValue,
      'modifier': modifier,
      'moveData': moveData,
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
      rollType: json['rollType'],
      progressValue: json['progressValue'],
      modifier: json['modifier'],
      moveData: json['moveData'],
    );
  }
  
  // Helper method to get formatted text for journal entry
  String getFormattedText() {
    if (rollType == 'no_roll') {
      return '[$moveName]';
    } else {
      return '[$moveName - ${outcome.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}]';
    }
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
  String? richContent; // JSON string for rich text content
  DateTime createdAt;
  DateTime updatedAt;
  List<String> linkedCharacterIds;
  List<String> linkedLocationIds;
  List<MoveRoll> moveRolls; // Changed from single moveRoll to list
  List<OracleRoll> oracleRolls; // Changed from single oracleRoll to list
  List<String> embeddedImages; // URLs of embedded images

  JournalEntry({
    String? id,
    required this.content,
    this.richContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
    List<MoveRoll>? moveRolls,
    List<OracleRoll>? oracleRolls,
    List<String>? embeddedImages,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        linkedCharacterIds = linkedCharacterIds ?? [],
        linkedLocationIds = linkedLocationIds ?? [],
        moveRolls = moveRolls ?? [],
        oracleRolls = oracleRolls ?? [],
        embeddedImages = embeddedImages ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'richContent': richContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'linkedCharacterIds': linkedCharacterIds,
      'linkedLocationIds': linkedLocationIds,
      'moveRolls': moveRolls.map((roll) => roll.toJson()).toList(),
      'oracleRolls': oracleRolls.map((roll) => roll.toJson()).toList(),
      'embeddedImages': embeddedImages,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    // Handle both old and new formats
    List<MoveRoll> moveRollsList = [];
    List<OracleRoll> oracleRollsList = [];
    
    // Check for new format (moveRolls list)
    if (json['moveRolls'] != null) {
      moveRollsList = (json['moveRolls'] as List)
          .map((roll) => MoveRoll.fromJson(roll))
          .toList()
          .cast<MoveRoll>();
    } 
    // Check for old format (single moveRoll)
    else if (json['moveRoll'] != null) {
      moveRollsList.add(MoveRoll.fromJson(json['moveRoll']));
    }
    
    // Check for new format (oracleRolls list)
    if (json['oracleRolls'] != null) {
      oracleRollsList = (json['oracleRolls'] as List)
          .map((roll) => OracleRoll.fromJson(roll))
          .toList()
          .cast<OracleRoll>();
    } 
    // Check for old format (single oracleRoll)
    else if (json['oracleRoll'] != null) {
      oracleRollsList.add(OracleRoll.fromJson(json['oracleRoll']));
    }
    
    return JournalEntry(
      id: json['id'],
      content: json['content'],
      richContent: json['richContent'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      linkedCharacterIds: (json['linkedCharacterIds'] as List?)?.cast<String>() ?? [],
      linkedLocationIds: (json['linkedLocationIds'] as List?)?.cast<String>() ?? [],
      moveRolls: moveRollsList,
      oracleRolls: oracleRollsList,
      embeddedImages: (json['embeddedImages'] as List?)?.cast<String>() ?? [],
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

  // Backward compatibility getters and setters for single moveRoll/oracleRoll
  MoveRoll? get moveRoll => moveRolls.isNotEmpty ? moveRolls.first : null;
  set moveRoll(MoveRoll? roll) {
    if (roll != null) {
      if (moveRolls.isEmpty) {
        moveRolls.add(roll);
      } else {
        moveRolls[0] = roll;
      }
    } else {
      moveRolls.clear();
    }
  }
  
  OracleRoll? get oracleRoll => oracleRolls.isNotEmpty ? oracleRolls.first : null;
  set oracleRoll(OracleRoll? roll) {
    if (roll != null) {
      if (oracleRolls.isEmpty) {
        oracleRolls.add(roll);
      } else {
        oracleRolls[0] = roll;
      }
    } else {
      oracleRolls.clear();
    }
  }

  void attachMoveRoll(MoveRoll roll) {
    moveRolls.add(roll);
  }

  void attachOracleRoll(OracleRoll roll) {
    oracleRolls.add(roll);
  }
  
  void addEmbeddedImage(String imageUrl) {
    if (!embeddedImages.contains(imageUrl)) {
      embeddedImages.add(imageUrl);
    }
  }
  
  void removeEmbeddedImage(String imageUrl) {
    embeddedImages.remove(imageUrl);
  }
}
