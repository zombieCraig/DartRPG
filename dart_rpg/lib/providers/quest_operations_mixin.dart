import 'package:flutter/foundation.dart';
import '../models/game.dart';
import '../models/session.dart';
import '../models/quest.dart';
import '../utils/dice_roller.dart';

/// Mixin that encapsulates all quest-related operations.
///
/// Requires the host class to provide access to game state via
/// [questGame], [questSession], and [persistAndNotify].
mixin QuestOperationsMixin on ChangeNotifier {
  Game? get questGame;
  Session? get questSession;
  Future<void> persistAndNotify();

  Future<Quest> createQuest(
    String title,
    String characterId,
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

    final quest = Quest(
      title: title,
      characterId: characterId,
      rank: rank,
      notes: notes,
    );

    questGame!.quests.add(quest);

    await persistAndNotify();

    return quest;
  }

  Future<void> updateQuestProgress(String questId, int progress) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    final newProgress = progress.clamp(0, 10);
    quest.updateProgress(newProgress);

    await persistAndNotify();
  }

  Future<void> updateQuestProgressTicks(String questId, int ticks) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.updateProgressTicks(ticks);

    await persistAndNotify();
  }

  Future<void> addQuestTick(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.addTick();

    await persistAndNotify();
  }

  Future<void> removeQuestTick(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.removeTick();

    await persistAndNotify();
  }

  Future<void> addQuestTicksForRank(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.addTicksForRank();

    await persistAndNotify();
  }

  Future<void> removeQuestTicksForRank(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.removeTicksForRank();

    await persistAndNotify();
  }

  Future<void> updateQuestNotes(String questId, String notes) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.notes = notes;

    await persistAndNotify();
  }

  Future<void> completeQuest(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.complete();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Quest "${quest.title}" completed by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );

      entry.metadata = {'sourceScreen': 'quests'};
    }

    await persistAndNotify();
  }

  Future<void> forsakeQuest(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    quest.forsake();

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Quest "${quest.title}" forsaken by ${character.name}.\n'
        'Final progress: ${quest.progress}/10\n'
        'Notes: ${quest.notes}'
      );

      entry.metadata = {'sourceScreen': 'quests'};
    }

    await persistAndNotify();
  }

  Future<void> deleteQuest(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    questGame!.quests.removeWhere((q) => q.id == questId);

    await persistAndNotify();
  }

  Future<Map<String, dynamic>> makeQuestProgressRoll(String questId) async {
    if (questGame == null) {
      throw Exception('No game selected');
    }

    final quest = questGame!.quests.firstWhere(
      (q) => q.id == questId,
      orElse: () => throw Exception('Quest not found'),
    );

    final result = DiceRoller.rollProgressMove(progressValue: quest.progress);

    if (questSession != null) {
      final character = questGame!.characters.firstWhere(
        (c) => c.id == quest.characterId,
        orElse: () => throw Exception('Character not found'),
      );

      final entry = questSession!.createNewEntry(
        'Progress roll for quest "${quest.title}" by ${character.name}.\n'
        'Progress: ${quest.progress}/10 (${quest.progressTicks} ticks)\n'
        'Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}\n'
        'Outcome: ${result['outcome']}'
      );

      entry.metadata = {'sourceScreen': 'quests'};
    }

    await persistAndNotify();

    return result;
  }
}
