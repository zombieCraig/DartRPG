import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../widgets/progress_track_widget.dart';

/// A panel for displaying and managing quest progress
class QuestProgressPanel extends StatelessWidget {
  /// The quest to display progress for
  final Quest quest;
  
  /// Callback for when the progress changes
  final Function(int)? onProgressChanged;
  
  /// Callback for when a progress roll is requested
  final VoidCallback? onProgressRoll;
  
  /// Callback for when the advance button is pressed
  final VoidCallback? onAdvance;
  
  /// Callback for when the decrease button is pressed
  final VoidCallback? onDecrease;
  
  /// Whether the panel is editable
  final bool isEditable;
  
  /// Creates a new QuestProgressPanel
  const QuestProgressPanel({
    super.key,
    required this.quest,
    this.onProgressChanged,
    this.onProgressRoll,
    this.onAdvance,
    this.onDecrease,
    this.isEditable = true,
  });
  
  @override
  Widget build(BuildContext context) {
    // Check if we're on a mobile device (width < 600)
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress track
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ProgressTrackWidget(
            label: 'Progress',
            value: quest.progress,
            ticks: quest.progressTicks,
            maxValue: 10,
            onBoxChanged: isEditable ? onProgressChanged : null,
            onTickChanged: isEditable 
                ? (ticks) => onProgressChanged?.call(ticks ~/ 4)
                : null,
            isEditable: isEditable,
            showTicks: true,
          ),
        ),
        
        // Progress buttons (only if editable)
        if (isEditable && quest.status == QuestStatus.ongoing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decrease button - show just "-" on mobile
                isMobile
                    ? ElevatedButton(
                        onPressed: onDecrease,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Icon(Icons.remove),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.remove),
                        label: const Text('Decrease'),
                        onPressed: onDecrease,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                
                // Advance button - show just "+" on mobile
                isMobile
                    ? ElevatedButton(
                        onPressed: onAdvance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Icon(Icons.add),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Advance'),
                        onPressed: onAdvance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                
                // Progress Roll button - show compact "Roll" text on mobile
                ElevatedButton.icon(
                  icon: const Icon(Icons.casino),
                  label: Text(isMobile ? 'Roll' : 'Progress Roll'),
                  onPressed: onProgressRoll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
        // Progress information
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                quest.rank.icon,
                color: quest.rank.color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Rank: ${quest.rank.displayName}',
                style: TextStyle(
                  color: quest.rank.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Progress: ${quest.progress}/10',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Rank information tooltip
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Text(
                'Each advance adds ${_getTicksDescription(quest.rank)} based on rank',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Get a description of the ticks added for a rank
  String _getTicksDescription(QuestRank rank) {
    switch (rank) {
      case QuestRank.troublesome:
        return '3 boxes (12 ticks)';
      case QuestRank.dangerous:
        return '2 boxes (8 ticks)';
      case QuestRank.formidable:
        return '1 box (4 ticks)';
      case QuestRank.extreme:
        return '2 ticks';
      case QuestRank.epic:
        return '1 tick';
    }
  }
}
