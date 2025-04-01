import 'package:flutter/material.dart';
import '../../models/quest.dart';

/// A panel for displaying quest action buttons
class QuestActionsPanel extends StatelessWidget {
  /// The quest to display actions for
  final Quest quest;
  
  /// Callback for when the complete button is pressed
  final VoidCallback? onComplete;
  
  /// Callback for when the forsake button is pressed
  final VoidCallback? onForsake;
  
  /// Callback for when the delete button is pressed
  final VoidCallback? onDelete;
  
  /// Callback for when the edit button is pressed
  final VoidCallback? onEdit;
  
  /// Creates a new QuestActionsPanel
  const QuestActionsPanel({
    super.key,
    required this.quest,
    this.onComplete,
    this.onForsake,
    this.onDelete,
    this.onEdit,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status actions (only for ongoing quests)
        if (quest.status == QuestStatus.ongoing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Forsake'),
                  onPressed: onForsake,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  onPressed: onComplete,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        
        // Edit and delete actions (for all quests)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (quest.status == QuestStatus.ongoing)
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
        
        // Status information
        if (quest.status != QuestStatus.ongoing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  quest.status.icon,
                  color: quest.status.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${quest.status.displayName}',
                  style: TextStyle(
                    color: quest.status.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  quest.status == QuestStatus.completed
                      ? 'Completed: ${_formatDate(quest.completedAt)}'
                      : 'Forsaken: ${_formatDate(quest.forsakenAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  /// Format a date as a string
  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Unknown';
    }
    
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
