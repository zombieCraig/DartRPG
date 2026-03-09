import 'package:flutter/foundation.dart';
import '../models/clock.dart';
import '../models/faction.dart';
import '../models/game.dart';
import '../models/session.dart';

/// Mixin that encapsulates all faction-related operations.
///
/// Requires the host class to provide access to game state via
/// [questGame], [questSession], and [persistAndNotify].
mixin FactionOperationsMixin on ChangeNotifier {
  Game? get questGame;
  Session? get questSession;
  Future<void> persistAndNotify();

  Future<Faction> createFaction(
    String name, {
    FactionType type = FactionType.corporate,
    FactionInfluence influence = FactionInfluence.established,
    String description = '',
    String leadershipStyle = '',
    List<String>? subtypes,
    String projects = '',
    String quirks = '',
    String rumors = '',
  }) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final faction = Faction(
      name: name,
      type: type,
      influence: influence,
      description: description,
      leadershipStyle: leadershipStyle,
      subtypes: subtypes,
      projects: projects,
      quirks: quirks,
      rumors: rumors,
    );

    questGame!.factions.add(faction);

    if (questSession != null) {
      final entry = questSession!.createNewEntry(
        'New faction: "$name" (${type.displayName}) established.\n'
        'Influence: ${influence.displayName}',
      );
      entry.metadata = {'sourceScreen': 'factions'};
    }

    await persistAndNotify();
    return faction;
  }

  Future<void> updateFactionDetails(
    String factionId, {
    String? name,
    FactionType? type,
    FactionInfluence? influence,
    String? description,
    String? leadershipStyle,
    List<String>? subtypes,
    String? projects,
    String? quirks,
    String? rumors,
  }) async {
    if (questGame == null) throw Exception('No game selected');

    final faction = questGame!.factions.firstWhere(
      (f) => f.id == factionId,
      orElse: () => throw Exception('Faction not found'),
    );

    if (name != null) faction.name = name;
    if (type != null) faction.type = type;
    if (influence != null) faction.influence = influence;
    if (description != null) faction.description = description;
    if (leadershipStyle != null) faction.leadershipStyle = leadershipStyle;
    if (subtypes != null) faction.subtypes = subtypes;
    if (projects != null) faction.projects = projects;
    if (quirks != null) faction.quirks = quirks;
    if (rumors != null) faction.rumors = rumors;

    await persistAndNotify();
  }

  Future<void> updateFactionRelationship(
    String factionId,
    String otherFactionId,
    String relationship,
  ) async {
    if (questGame == null) throw Exception('No game selected');

    final faction = questGame!.factions.firstWhere(
      (f) => f.id == factionId,
      orElse: () => throw Exception('Faction not found'),
    );

    faction.relationships[otherFactionId] = relationship;
    await persistAndNotify();
  }

  Future<void> setFactionRelationships(
    String factionId,
    Map<String, String> relationships,
  ) async {
    if (questGame == null) throw Exception('No game selected');

    final faction = questGame!.factions.firstWhere(
      (f) => f.id == factionId,
      orElse: () => throw Exception('Faction not found'),
    );

    faction.relationships = relationships;
    await persistAndNotify();
  }

  Future<void> deleteFaction(String factionId) async {
    if (questGame == null) throw Exception('No game selected');

    // Unlink any clocks associated with this faction
    for (final clock in questGame!.clocks) {
      if (clock.factionId == factionId) {
        clock.factionId = null;
      }
    }

    // Clean up relationship references from other factions
    for (final faction in questGame!.factions) {
      faction.relationships.remove(factionId);
    }

    questGame!.factions.removeWhere((f) => f.id == factionId);
    await persistAndNotify();
  }

  Future<Clock> addClockToFaction(
    String factionId,
    String title,
    int segments,
    ClockType type,
  ) async {
    if (questGame == null) throw Exception('No game selected');

    final faction = questGame!.factions.firstWhere(
      (f) => f.id == factionId,
      orElse: () => throw Exception('Faction not found'),
    );

    if (![4, 6, 8, 10].contains(segments)) {
      throw Exception('Invalid number of segments. Must be 4, 6, 8, or 10.');
    }

    final clock = Clock(
      title: title,
      segments: segments,
      type: type,
      factionId: factionId,
    );

    questGame!.clocks.add(clock);
    faction.clockIds.add(clock.id);

    if (questSession != null) {
      final entry = questSession!.createNewEntry(
        'Clock "$title" (${type.displayName}, $segments segments) '
        'added to faction "${faction.name}".',
      );
      entry.metadata = {'sourceScreen': 'factions'};
    }

    await persistAndNotify();
    return clock;
  }

  Future<void> removeClockFromFaction(String factionId, String clockId) async {
    if (questGame == null) throw Exception('No game selected');

    final faction = questGame!.factions.firstWhere(
      (f) => f.id == factionId,
      orElse: () => throw Exception('Faction not found'),
    );

    faction.clockIds.remove(clockId);

    // Unlink the clock's factionId but don't delete the clock
    for (final clock in questGame!.clocks) {
      if (clock.id == clockId && clock.factionId == factionId) {
        clock.factionId = null;
      }
    }

    await persistAndNotify();
  }
}
