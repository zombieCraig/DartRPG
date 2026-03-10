import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/session.dart';
import '../models/combat.dart';
import '../models/quest.dart';
import '../utils/dice_roller.dart';

/// Mixin that encapsulates all combat-related operations.
///
/// Requires the host class to provide access to game state via
/// [combatGame], [combatSession], and [persistAndNotify].
mixin CombatOperationsMixin on ChangeNotifier {
  Game? get combatGame;
  Session? get combatSession;
  Future<void> persistAndNotify();

  Future<Combat> createCombat(
    String title,
    String characterId,
    QuestRank rank, {
    bool isInControl = true,
  }) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    combatGame!.characters.firstWhere(
      (c) => c.id == characterId,
      orElse: () => throw Exception('Character not found'),
    );

    final combat = Combat(
      title: title,
      characterId: characterId,
      rank: rank,
      isInControl: isInControl,
    );

    combatGame!.combats.add(combat);

    await persistAndNotify();

    return combat;
  }

  Future<void> addCombatTicksForRank(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.addTicksForRank();

    await persistAndNotify();
  }

  Future<void> addCombatTicksForRankDouble(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.addTicksForRank();
    combat.addTicksForRank();

    await persistAndNotify();
  }

  Future<void> removeCombatTicksForRank(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.removeTicksForRank();

    await persistAndNotify();
  }

  Future<void> updateCombatProgressTicks(String combatId, int ticks) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.updateProgressTicks(ticks);

    await persistAndNotify();
  }

  Future<void> setCombatControl(String combatId, bool inControl) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.isInControl = inControl;

    await persistAndNotify();
  }

  Future<void> toggleCombatControl(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.isInControl = !combat.isInControl;

    await persistAndNotify();
  }

  Future<Map<String, dynamic>> makeCombatProgressRoll(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    final result = DiceRoller.rollProgressMove(progressValue: combat.progress);

    if (combatSession != null) {
      final character = combatGame!.characters.firstWhere(
        (c) => c.id == combat.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = combatSession!.createNewEntry(
        'Progress roll for combat "${combat.title}" by ${character.name}.\n'
        'Progress: ${combat.progress}/10 (${combat.progressTicks} ticks)\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );

      entry.metadata = {'sourceScreen': 'combat'};
    }

    await persistAndNotify();

    return result;
  }

  Future<void> endCombat(String combatId, CombatStatus endStatus) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    final combat = combatGame!.combats.firstWhere(
      (c) => c.id == combatId,
      orElse: () => throw Exception('Combat not found'),
    );

    combat.end(endStatus);

    await persistAndNotify();
  }

  Future<void> deleteCombat(String combatId) async {
    if (combatGame == null) {
      throw Exception('No game selected');
    }

    combatGame!.combats.removeWhere((c) => c.id == combatId);

    await persistAndNotify();
  }
}
