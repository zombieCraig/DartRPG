import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/session.dart';
import '../models/network_route.dart';
import '../models/location.dart';
import '../models/quest.dart';
import '../utils/dice_roller.dart';

/// Mixin that encapsulates all route-related operations.
///
/// Requires the host class to provide access to game state via
/// [questGame], [questSession], and [persistAndNotify].
mixin RouteOperationsMixin on ChangeNotifier {
  Game? get questGame;
  Session? get questSession;
  Future<void> persistAndNotify();

  Future<NetworkRoute> createRoute(
    String name,
    String characterId,
    LocationSegment origin,
    LocationSegment destination,
    QuestRank rank, {
    String notes = '',
  }) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    questGame!.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => throw Exception('Character not found'),
    );

    final route = NetworkRoute(
      name: name,
      characterId: characterId,
      origin: origin,
      destination: destination,
      rank: rank,
      notes: notes,
    );

    questGame!.routes.add(route);

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == characterId,
      );
      final entry = questSession!.createNewEntry(
        'New route mapped: "$name" (${route.routeLabel}) by ${character.name}.\n'
        'Rank: ${rank.displayName}'
      );
      entry.metadata = {'sourceScreen': 'routes'};
    }

    await persistAndNotify();

    return route;
  }

  Future<void> updateRouteProgress(String routeId, int progress) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.updateProgress(progress.clamp(0, 10));
    await persistAndNotify();
  }

  Future<void> updateRouteProgressTicks(String routeId, int ticks) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.updateProgressTicks(ticks);
    await persistAndNotify();
  }

  Future<void> addRouteTicksForRank(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.addTicksForRank();
    await persistAndNotify();
  }

  Future<void> removeRouteTicksForRank(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.removeTicksForRank();
    await persistAndNotify();
  }

  Future<void> updateRouteNotes(String routeId, String notes) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.notes = notes;
    await persistAndNotify();
  }

  Future<void> updateRouteDetails(
    String routeId, {
    String? name,
    LocationSegment? origin,
    LocationSegment? destination,
    QuestRank? rank,
  }) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    if (name != null) route.name = name;
    if (origin != null) route.origin = origin;
    if (destination != null) route.destination = destination;
    if (rank != null) route.rank = rank;

    await persistAndNotify();
  }

  Future<void> completeRoute(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.complete();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == route.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Route "${route.name}" (${route.routeLabel}) completed by ${character.name}.\n'
        'Final progress: ${route.progress}/10'
      );
      entry.metadata = {'sourceScreen': 'routes'};
    }

    await persistAndNotify();
  }

  Future<void> burnRoute(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    route.burn();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == route.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Route "${route.name}" (${route.routeLabel}) burned by ${character.name}.\n'
        'Final progress: ${route.progress}/10'
      );
      entry.metadata = {'sourceScreen': 'routes'};
    }

    await persistAndNotify();
  }

  Future<void> deleteRoute(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    questGame!.routes.removeWhere((r) => r.id == routeId);
    await persistAndNotify();
  }

  Future<Map<String, dynamic>> makeRouteProgressRoll(String routeId) async {
    if (questGame == null) throw Exception('No game selected');

    final route = questGame!.routes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => throw Exception('Route not found'),
    );

    final result = DiceRoller.rollProgressMove(progressValue: route.progress);

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == route.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Infiltrate Segment roll for route "${route.name}" (${route.routeLabel}) by ${character.name}.\n'
        'Progress: ${route.progress}/10 (${route.progressTicks} ticks)\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );
      entry.metadata = {'sourceScreen': 'routes'};
    }

    await persistAndNotify();

    return result;
  }
}
