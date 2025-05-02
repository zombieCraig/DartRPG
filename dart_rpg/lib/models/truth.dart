import 'package:uuid/uuid.dart';

/// Represents a world truth category in the game
class Truth {
  final String id;
  final String name;
  final String question; // "your_character" field in JSON
  final List<TruthOption> options;
  final String dice; // For rolling

  Truth({
    required this.id,
    required this.name,
    required this.question,
    required this.options,
    required this.dice,
  });

  /// Factory method to create from JSON
  factory Truth.fromJson(String id, Map<String, dynamic> json) {
    return Truth(
      id: id,
      name: json['name'],
      question: json['your_character'],
      options: (json['options'] as List)
          .map((option) => TruthOption.fromJson(option))
          .toList(),
      dice: json['dice'],
    );
  }
}

/// Represents a single option within a truth category
class TruthOption {
  final String id;
  final int minRoll;
  final int maxRoll;
  final String summary;
  final String description;
  final String? questStarter;

  TruthOption({
    String? id,
    required this.minRoll,
    required this.maxRoll,
    required this.summary,
    required this.description,
    this.questStarter,
  }) : id = id ?? const Uuid().v4();

  /// Factory method to create from JSON
  factory TruthOption.fromJson(Map<String, dynamic> json) {
    return TruthOption(
      id: json['_id'] as String? ?? const Uuid().v4(),
      minRoll: json['roll']['min'],
      maxRoll: json['roll']['max'],
      summary: json['summary'],
      description: json['description'],
      questStarter: json['quest_starter'],
    );
  }
}
