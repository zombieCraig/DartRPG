import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Enum representing the type of a faction
enum FactionType {
  corporate,
  political,
  underground;

  String get displayName {
    switch (this) {
      case FactionType.corporate:
        return 'Corporate';
      case FactionType.political:
        return 'Political';
      case FactionType.underground:
        return 'Underground';
    }
  }

  IconData get icon {
    switch (this) {
      case FactionType.corporate:
        return Icons.business;
      case FactionType.political:
        return Icons.account_balance;
      case FactionType.underground:
        return Icons.visibility_off;
    }
  }

  Color get color {
    switch (this) {
      case FactionType.corporate:
        return Colors.blue;
      case FactionType.political:
        return Colors.amber;
      case FactionType.underground:
        return Colors.deepPurple;
    }
  }
}

/// Enum representing the influence level of a faction
enum FactionInfluence {
  forsaken,
  isolated,
  localized,
  established,
  notable,
  dominant,
  inescapable;

  String get displayName {
    switch (this) {
      case FactionInfluence.forsaken:
        return 'Forsaken';
      case FactionInfluence.isolated:
        return 'Isolated';
      case FactionInfluence.localized:
        return 'Localized';
      case FactionInfluence.established:
        return 'Established';
      case FactionInfluence.notable:
        return 'Notable';
      case FactionInfluence.dominant:
        return 'Dominant';
      case FactionInfluence.inescapable:
        return 'Inescapable';
    }
  }
}

/// Class representing a faction in the game world.
class Faction {
  final String id;
  String name;
  FactionType type;
  FactionInfluence influence;
  String description;
  String leadershipStyle;
  List<String> subtypes;
  String projects;
  String quirks;
  String rumors;
  Map<String, String> relationships;
  List<String> clockIds;
  final DateTime createdAt;

  Faction({
    String? id,
    required this.name,
    this.type = FactionType.corporate,
    this.influence = FactionInfluence.established,
    this.description = '',
    this.leadershipStyle = '',
    List<String>? subtypes,
    this.projects = '',
    this.quirks = '',
    this.rumors = '',
    Map<String, String>? relationships,
    List<String>? clockIds,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        subtypes = subtypes ?? [],
        relationships = relationships ?? {},
        clockIds = clockIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  factory Faction.fromJson(Map<String, dynamic> json) {
    return Faction(
      id: json['id'],
      name: json['name'],
      type: FactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FactionType.corporate,
      ),
      influence: FactionInfluence.values.firstWhere(
        (i) => i.name == json['influence'],
        orElse: () => FactionInfluence.established,
      ),
      description: json['description'] ?? '',
      leadershipStyle: json['leadershipStyle'] ?? '',
      subtypes: (json['subtypes'] as List?)?.cast<String>() ?? [],
      projects: json['projects'] ?? '',
      quirks: json['quirks'] ?? '',
      rumors: json['rumors'] ?? '',
      relationships: (json['relationships'] as Map?)?.cast<String, String>() ?? {},
      clockIds: (json['clockIds'] as List?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'influence': influence.name,
      'description': description,
      'leadershipStyle': leadershipStyle,
      'subtypes': subtypes,
      'projects': projects,
      'quirks': quirks,
      'rumors': rumors,
      'relationships': relationships,
      'clockIds': clockIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Faction clone() {
    return Faction(
      id: id,
      name: name,
      type: type,
      influence: influence,
      description: description,
      leadershipStyle: leadershipStyle,
      subtypes: List<String>.from(subtypes),
      projects: projects,
      quirks: quirks,
      rumors: rumors,
      relationships: Map<String, String>.from(relationships),
      clockIds: List<String>.from(clockIds),
      createdAt: createdAt,
    );
  }
}
