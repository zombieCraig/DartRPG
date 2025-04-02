import '../../models/quest.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling quest operations
class QuestService {
  /// The game provider
  final GameProvider gameProvider;
  
  /// Creates a new QuestService
  QuestService({
    required this.gameProvider,
  });
  
  /// Create a new quest
  Future<Quest?> createQuest({
    required String title,
    required String characterId,
    required QuestRank rank,
    String notes = '',
  }) async {
    try {
      return await gameProvider.createQuest(
        title,
        characterId,
        rank,
        notes: notes,
      );
    } catch (e) {
      LoggingService().error(
        'Failed to create quest',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
  
  /// Update a quest
  Future<bool> updateQuest({
    required String questId,
    required String title,
    required String characterId,
    required QuestRank rank,
    required String notes,
  }) async {
    try {
      // Get the current quest
      final quest = gameProvider.currentGame?.quests.firstWhere(
        (q) => q.id == questId,
        orElse: () => throw Exception('Quest not found'),
      );
      
      if (quest == null) {
        return false;
      }
      
      // Update the quest properties
      quest.title = title;
      
      // If the character ID has changed, we need to update it
      // This is a bit tricky since there's no direct method to update it
      if (quest.characterId != characterId) {
        // Create a new quest with the new character ID
        final newQuest = Quest(
          id: quest.id,
          title: title,
          characterId: characterId,
          rank: rank,
          progressTicks: quest.progressTicks,
          status: quest.status,
          notes: notes,
          createdAt: quest.createdAt,
          completedAt: quest.completedAt,
          forsakenAt: quest.forsakenAt,
        );
        
        // Remove the old quest and add the new one
        gameProvider.currentGame?.quests.removeWhere((q) => q.id == questId);
        gameProvider.currentGame?.quests.add(newQuest);
      } else {
        // Update the rank if it has changed
        quest.rank = rank;
        
        // Update the notes
        await gameProvider.updateQuestNotes(questId, notes);
      }
      
      // Save the changes
      await gameProvider.saveGame();
      
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update quest',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Make a progress roll for a quest
  Future<Map<String, dynamic>?> makeProgressRoll(String questId) async {
    try {
      return await gameProvider.makeQuestProgressRoll(questId);
    } catch (e) {
      LoggingService().error(
        'Failed to make progress roll',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
  
  /// Complete a quest
  Future<bool> completeQuest(String questId) async {
    try {
      await gameProvider.completeQuest(questId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to complete quest',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Forsake a quest
  Future<bool> forsakeQuest(String questId) async {
    try {
      await gameProvider.forsakeQuest(questId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to forsake quest',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Delete a quest
  Future<bool> deleteQuest(String questId) async {
    try {
      await gameProvider.deleteQuest(questId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to delete quest',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Update quest progress
  Future<bool> updateProgress(String questId, int progress) async {
    try {
      await gameProvider.updateQuestProgress(questId, progress);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update quest progress',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Add ticks based on quest rank
  Future<bool> addTicksForRank(String questId) async {
    try {
      await gameProvider.addQuestTicksForRank(questId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to add ticks for rank',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Remove ticks based on quest rank
  Future<bool> removeTicksForRank(String questId) async {
    try {
      await gameProvider.removeQuestTicksForRank(questId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to remove ticks for rank',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Update quest notes
  Future<bool> updateNotes(String questId, String notes) async {
    try {
      await gameProvider.updateQuestNotes(questId, notes);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update quest notes',
        tag: 'QuestService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
}
