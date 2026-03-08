import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/session.dart';
import '../models/connection.dart';
import '../models/quest.dart';
import '../utils/dice_roller.dart';

/// Mixin that encapsulates all connection-related operations.
///
/// Requires the host class to provide access to game state via
/// [questGame], [questSession], and [persistAndNotify].
mixin ConnectionOperationsMixin on ChangeNotifier {
  Game? get questGame;
  Session? get questSession;
  Future<void> persistAndNotify();

  Future<Connection> createConnection(
    String name,
    String characterId,
    QuestRank rank,
    String role, {
    String notes = '',
  }) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    questGame!.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => throw Exception('Character not found'),
    );

    final connection = Connection(
      name: name,
      characterId: characterId,
      rank: rank,
      role: role,
      notes: notes,
    );

    questGame!.connections.add(connection);

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == characterId,
      );
      final entry = questSession!.createNewEntry(
        'New connection: "$name" ($role) established by ${character.name}.\n'
        'Rank: ${rank.displayName}'
      );
      entry.metadata = {'sourceScreen': 'connections'};
    }

    await persistAndNotify();

    return connection;
  }

  Future<void> updateConnectionProgress(String connectionId, int progress) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.updateProgress(progress.clamp(0, 10));
    await persistAndNotify();
  }

  Future<void> updateConnectionProgressTicks(String connectionId, int ticks) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.updateProgressTicks(ticks);
    await persistAndNotify();
  }

  Future<void> addConnectionTicksForRank(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.addTicksForRank();
    await persistAndNotify();
  }

  Future<void> removeConnectionTicksForRank(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.removeTicksForRank();
    await persistAndNotify();
  }

  Future<void> updateConnectionNotes(String connectionId, String notes) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.notes = notes;
    await persistAndNotify();
  }

  Future<void> updateConnectionDetails(
    String connectionId, {
    String? name,
    String? role,
    QuestRank? rank,
  }) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    if (name != null) connection.name = name;
    if (role != null) connection.role = role;
    if (rank != null) connection.rank = rank;

    await persistAndNotify();
  }

  Future<void> bondConnection(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.bond();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == connection.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Bond forged with "${connection.name}" (${connection.role}) by ${character.name}.\n'
        'Final progress: ${connection.progress}/10'
      );
      entry.metadata = {'sourceScreen': 'connections'};
    }

    await persistAndNotify();
  }

  Future<void> loseConnection(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    connection.lose();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == connection.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Connection with "${connection.name}" (${connection.role}) lost by ${character.name}.\n'
        'Final progress: ${connection.progress}/10'
      );
      entry.metadata = {'sourceScreen': 'connections'};
    }

    await persistAndNotify();
  }

  Future<void> deleteConnection(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    questGame!.connections.removeWhere((c) => c.id == connectionId);
    await persistAndNotify();
  }

  Future<Map<String, dynamic>> makeConnectionProgressRoll(String connectionId) async {
    if (questGame == null) throw Exception('No game selected');

    final connection = questGame!.connections.firstWhere(
      (c) => c.id == connectionId,
      orElse: () => throw Exception('Connection not found'),
    );

    final result = DiceRoller.rollProgressMove(progressValue: connection.progress);

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == connection.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Progress roll for connection "${connection.name}" by ${character.name}.\n'
        'Progress: ${connection.progress}/10 (${connection.progressTicks} ticks)\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );
      entry.metadata = {'sourceScreen': 'connections'};
    }

    await persistAndNotify();

    return result;
  }
}
