import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/quest.dart';
import 'quest_card.dart';
import 'quest_dialog.dart';
import 'quest_service.dart';

/// A list of quests filtered by status
class QuestTabList extends StatelessWidget {
  /// The quests to display
  final List<Quest> quests;
  
  /// The characters in the game
  final List<Character> characters;
  
  /// The quest service
  final QuestService questService;
  
  /// The status of quests to display
  final QuestStatus status;
  
  /// Creates a new QuestTabList
  const QuestTabList({
    super.key,
    required this.quests,
    required this.characters,
    required this.questService,
    required this.status,
  });
  
  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView.builder(
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final character = characters.firstWhere(
          (c) => c.id == quest.characterId,
          orElse: () => throw Exception('Character not found'),
        );
        
        return QuestCard(
          quest: quest,
          character: character,
          onProgressChanged: (value) {
            questService.updateProgress(quest.id, value);
          },
          onProgressRoll: () async {
            final result = await questService.makeProgressRoll(quest.id);
            if (result != null && context.mounted) {
              QuestDialog.showProgressRollResult(
                context: context,
                quest: quest,
                result: result,
              );
            }
          },
          onAdvance: () {
            questService.addTicksForRank(quest.id);
          },
          onDecrease: () {
            questService.removeTicksForRank(quest.id);
          },
          onComplete: () {
            questService.completeQuest(quest.id);
          },
          onForsake: () {
            questService.forsakeQuest(quest.id);
          },
          onDelete: () async {
            final shouldDelete = await QuestDialog.showDeleteConfirmation(
              context: context,
              quest: quest,
            );
            
            if (shouldDelete == true && context.mounted) {
              questService.deleteQuest(quest.id);
            }
          },
          onEdit: () async {
            final result = await QuestDialog.showEditDialog(
              context: context,
              quest: quest,
              characters: characters,
            );
            
            if (result != null && context.mounted) {
              questService.updateQuest(
                questId: quest.id,
                title: result['title'],
                characterId: result['characterId'],
                rank: result['rank'],
                notes: result['notes'],
              );
            }
          },
          onNotesChanged: (notes) {
            questService.updateNotes(quest.id, notes);
          },
        );
      },
    );
  }
  
  /// Build the empty state widget
  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;
    
    switch (status) {
      case QuestStatus.ongoing:
        message = 'No ongoing quests';
        icon = Icons.pending_actions;
        break;
      case QuestStatus.completed:
        message = 'No completed quests';
        icon = Icons.check_circle;
        break;
      case QuestStatus.forsaken:
        message = 'No forsaken quests';
        icon = Icons.cancel;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status == QuestStatus.ongoing
                ? 'Create a new quest using the + button'
                : status == QuestStatus.completed
                    ? 'Complete quests to see them here'
                    : 'Forsake quests to see them here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
