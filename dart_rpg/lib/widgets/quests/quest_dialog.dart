import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/quest.dart';
import 'quest_form.dart';

/// A dialog for creating or editing a quest
class QuestDialog {
  /// Show a dialog for creating a new quest
  static Future<Map<String, dynamic>?> showCreateDialog({
    required BuildContext context,
    required List<Character> characters,
  }) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to create a quest'),
        ),
      );
      return null;
    }
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Quest'),
        content: SingleChildScrollView(
          child: QuestForm(
            characters: characters,
            onSubmit: (title, characterId, rank, notes) {
              Navigator.of(context).pop({
                'title': title,
                'characterId': characterId,
                'rank': rank,
                'notes': notes,
              });
            },
          ),
        ),
      ),
    );
  }
  
  /// Show a dialog for editing an existing quest
  static Future<Map<String, dynamic>?> showEditDialog({
    required BuildContext context,
    required Quest quest,
    required List<Character> characters,
  }) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to edit this quest'),
        ),
      );
      return null;
    }
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Quest'),
        content: SingleChildScrollView(
          child: QuestForm(
            initialQuest: quest,
            characters: characters,
            onSubmit: (title, characterId, rank, notes) {
              Navigator.of(context).pop({
                'title': title,
                'characterId': characterId,
                'rank': rank,
                'notes': notes,
              });
            },
          ),
        ),
      ),
    );
  }
  
  /// Show a confirmation dialog for deleting a quest
  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required Quest quest,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  /// Show a dialog with the results of a progress roll
  static void showProgressRollResult({
    required BuildContext context,
    required Quest quest,
    required Map<String, dynamic> result,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Progress Roll for "${quest.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${quest.progress}/10'),
            const SizedBox(height: 8),
            Text('Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}'),
            const SizedBox(height: 8),
            Text(
              'Outcome: ${result['outcome']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getOutcomeColor(result['outcome']),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  /// Get the color for a roll outcome
  static Color _getOutcomeColor(String outcome) {
    if (outcome.contains('strong hit')) {
      return Colors.green;
    } else if (outcome.contains('weak hit')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
