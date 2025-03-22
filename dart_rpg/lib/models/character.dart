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
  
  // Factory method for creating a Base Rig asset
  factory Asset.baseRig() {
    return Asset(
      name: 'Base Rig',
      category: 'Base Rig',
      description: 'Your personal computer system and starting point in the network.',
      enabled: true,
    );
  }
}

class Character {
  final String id;
  String name;
  String? handle; // Short name or nickname for the character
  String? bio;
  String? imageUrl;
  List<CharacterStat> stats;
  List<Asset> assets;
  List<String> notes;
  bool isMainCharacter;
  
  // New properties for Fe-Runners
  int momentum;
  int momentumReset;
  int health;
  int spirit;
  int supply;
  
  // Impacts as boolean flags
  bool impactWounded;
  bool impactShaken;
  bool impactUnregulated;
  bool impactPermanentlyHarmed;
  bool impactTraumatized;
  bool impactDoomed;
  bool impactTormented;
  bool impactIndebted;
  bool impactOverheated;
  bool impactInfected;
  
  // Legacies as progress tracks (0-10)
  int legacyQuests;
  int legacyBonds;
  int legacyDiscoveries;
  
  // Additional notes separate from bio
  String? gameNotes;

  Character({
    String? id,
    required this.name,
    this.handle,
    this.bio,
    this.imageUrl,
    List<CharacterStat>? stats,
    List<Asset>? assets,
    List<String>? notes,
    this.isMainCharacter = false,
    this.momentum = 2,
    this.momentumReset = 2,
    this.health = 5,
    this.spirit = 5,
    this.supply = 5,
    this.impactWounded = false,
    this.impactShaken = false,
    this.impactUnregulated = false,
    this.impactPermanentlyHarmed = false,
    this.impactTraumatized = false,
    this.impactDoomed = false,
    this.impactTormented = false,
    this.impactIndebted = false,
    this.impactOverheated = false,
    this.impactInfected = false,
    this.legacyQuests = 0,
    this.legacyBonds = 0,
    this.legacyDiscoveries = 0,
    this.gameNotes,
  })  : id = id ?? const Uuid().v4(),
        stats = stats ?? [],
        assets = assets ?? [],
        notes = notes ?? [];

  // Helper methods for impacts and momentum
  int get totalImpacts => [
    impactWounded, impactShaken, impactUnregulated,
    impactPermanentlyHarmed, impactTraumatized,
    impactDoomed, impactTormented, impactIndebted,
    impactOverheated, impactInfected
  ].where((impact) => impact).length;
  
  int get maxMomentum => 10 - totalImpacts;
  
  void burnMomentum() {
    momentumReset = momentum > 0 ? 2 : momentumReset;
    momentum = momentumReset;
  }
  
  List<String> get activeImpacts {
    final impacts = <String>[];
    if (impactWounded) impacts.add('Wounded');
    if (impactShaken) impacts.add('Shaken');
    if (impactUnregulated) impacts.add('Unregulated');
    if (impactPermanentlyHarmed) impacts.add('Permanently Harmed');
    if (impactTraumatized) impacts.add('Traumatized');
    if (impactDoomed) impacts.add('Doomed');
    if (impactTormented) impacts.add('Tormented');
    if (impactIndebted) impacts.add('Indebted');
    if (impactOverheated) impacts.add('Overheated');
    if (impactInfected) impacts.add('Infected');
    return impacts;
  }

  // Generate a handle from the name if not provided
  String getHandle() {
    if (handle != null && handle!.isNotEmpty) {
      return handle!;
    }
    
    // Extract first name and remove special characters
    final firstName = name.split(' ').first;
    return firstName.replaceAll(RegExp(r'[@#\[\]\(\)]'), '');
  }
  
  // Validate and set handle
  void setHandle(String? newHandle) {
    if (newHandle == null || newHandle.isEmpty) {
      handle = null;
      return;
    }
    
    // Remove spaces and special characters
    handle = newHandle.replaceAll(RegExp(r'[\s@#\[\]\(\)]'), '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'bio': bio,
      'imageUrl': imageUrl,
      'stats': stats.map((s) => s.toJson()).toList(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'notes': notes,
      'isMainCharacter': isMainCharacter,
      'momentum': momentum,
      'momentumReset': momentumReset,
      'health': health,
      'spirit': spirit,
      'supply': supply,
      'impactWounded': impactWounded,
      'impactShaken': impactShaken,
      'impactUnregulated': impactUnregulated,
      'impactPermanentlyHarmed': impactPermanentlyHarmed,
      'impactTraumatized': impactTraumatized,
      'impactDoomed': impactDoomed,
      'impactTormented': impactTormented,
      'impactIndebted': impactIndebted,
      'impactOverheated': impactOverheated,
      'impactInfected': impactInfected,
      'legacyQuests': legacyQuests,
      'legacyBonds': legacyBonds,
      'legacyDiscoveries': legacyDiscoveries,
      'gameNotes': gameNotes,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      handle: json['handle'],
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
      momentum: json['momentum'] ?? 2,
      momentumReset: json['momentumReset'] ?? 2,
      health: json['health'] ?? 5,
      spirit: json['spirit'] ?? 5,
      supply: json['supply'] ?? 5,
      impactWounded: json['impactWounded'] ?? false,
      impactShaken: json['impactShaken'] ?? false,
      impactUnregulated: json['impactUnregulated'] ?? false,
      impactPermanentlyHarmed: json['impactPermanentlyHarmed'] ?? false,
      impactTraumatized: json['impactTraumatized'] ?? false,
      impactDoomed: json['impactDoomed'] ?? false,
      impactTormented: json['impactTormented'] ?? false,
      impactIndebted: json['impactIndebted'] ?? false,
      impactOverheated: json['impactOverheated'] ?? false,
      impactInfected: json['impactInfected'] ?? false,
      legacyQuests: json['legacyQuests'] ?? 0,
      legacyBonds: json['legacyBonds'] ?? 0,
      legacyDiscoveries: json['legacyDiscoveries'] ?? 0,
      gameNotes: json['gameNotes'],
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
  factory Character.createMainCharacter(String name, {String? handle}) {
    final character = Character(
      name: name,
      handle: handle,
      isMainCharacter: true,
      stats: [
        CharacterStat(name: 'Edge', value: 1),
        CharacterStat(name: 'Heart', value: 1),
        CharacterStat(name: 'Iron', value: 1),
        CharacterStat(name: 'Shadow', value: 1),
        CharacterStat(name: 'Wits', value: 1),
      ],
    );
    
    // If handle is not provided, generate one from the name
    if (handle == null || handle.isEmpty) {
      character.setHandle(character.getHandle());
    }
    
    // Add Base Rig asset
    character.assets.add(Asset.baseRig());
    
    return character;
  }
}
