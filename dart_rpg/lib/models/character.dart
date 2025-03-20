import 'dart:convert';
import 'package:uuid/uuid.dart';

class CharacterStat {
  String name;
  int value;

  CharacterStat({
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory CharacterStat.fromJson(Map<String, dynamic> json) {
    return CharacterStat(
      name: json['name'],
      value: json['value'],
    );
  }
}

class Asset {
  final String id;
  String name;
  String category;
  String? description;
  bool enabled;

  Asset({
    String? id,
    required this.name,
    required this.category,
    required this.description,
    this.enabled = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'enabled': enabled,
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      enabled: json['enabled'] ?? false,
    );
  }
}

class Character {
  final String id;
  String name;
  String? bio;
  String? imageUrl;
  List<CharacterStat> stats;
  List<Asset> assets;
  List<String> notes;
  bool isMainCharacter;

  Character({
    String? id,
    required this.name,
    this.bio,
    this.imageUrl,
    List<CharacterStat>? stats,
    List<Asset>? assets,
    List<String>? notes,
    this.isMainCharacter = false,
  })  : id = id ?? const Uuid().v4(),
        stats = stats ?? [],
        assets = assets ?? [],
        notes = notes ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'imageUrl': imageUrl,
      'stats': stats.map((s) => s.toJson()).toList(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'notes': notes,
      'isMainCharacter': isMainCharacter,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      bio: json['bio'],
      imageUrl: json['imageUrl'],
      stats: (json['stats'] as List?)
          ?.map((s) => CharacterStat.fromJson(s))
          .toList() ?? [],
      assets: (json['assets'] as List?)
          ?.map((a) => Asset.fromJson(a))
          .toList() ?? [],
      notes: (json['notes'] as List?)?.cast<String>() ?? [],
      isMainCharacter: json['isMainCharacter'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Character.fromJsonString(String jsonString) {
    return Character.fromJson(jsonDecode(jsonString));
  }

  void addStat(String name, int value) {
    stats.add(CharacterStat(name: name, value: value));
  }

  void updateStat(String name, int value) {
    final index = stats.indexWhere((s) => s.name == name);
    if (index != -1) {
      stats[index].value = value;
    } else {
      addStat(name, value);
    }
  }

  void addAsset(Asset asset) {
    assets.add(asset);
  }

  void removeAsset(String assetId) {
    assets.removeWhere((a) => a.id == assetId);
  }

  void addNote(String note) {
    notes.add(note);
  }

  void removeNote(int index) {
    if (index >= 0 && index < notes.length) {
      notes.removeAt(index);
    }
  }

  // Create a main character with default IronSworn stats
  factory Character.createMainCharacter(String name) {
    return Character(
      name: name,
      isMainCharacter: true,
      stats: [
        CharacterStat(name: 'Edge', value: 1),
        CharacterStat(name: 'Heart', value: 1),
        CharacterStat(name: 'Iron', value: 1),
        CharacterStat(name: 'Shadow', value: 1),
        CharacterStat(name: 'Wits', value: 1),
      ],
    );
  }
}
