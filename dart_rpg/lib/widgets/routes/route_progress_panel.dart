import 'package:flutter/material.dart';
import '../../models/network_route.dart';
import '../../models/quest.dart';
import '../progress_track_widget.dart';

/// A panel for displaying and managing route progress
class RouteProgressPanel extends StatelessWidget {
  final NetworkRoute route;
  final Function(int)? onProgressChanged;
  final VoidCallback? onProgressRoll;
  final VoidCallback? onAdvance;
  final VoidCallback? onDecrease;
  final bool isEditable;

  const RouteProgressPanel({
    super.key,
    required this.route,
    this.onProgressChanged,
    this.onProgressRoll,
    this.onAdvance,
    this.onDecrease,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
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
            value: route.progress,
            ticks: route.progressTicks,
            maxValue: 10,
            onBoxChanged: isEditable ? onProgressChanged : null,
            onTickChanged: isEditable
                ? (ticks) => onProgressChanged?.call(ticks ~/ 4)
                : null,
            isEditable: isEditable,
            showTicks: true,
          ),
        ),

        // Progress buttons (only if editable and active)
        if (isEditable && route.status == RouteStatus.active)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.casino),
                  label: Text(isMobile ? 'Roll' : 'Infiltrate Segment'),
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
              Icon(route.rank.icon, color: route.rank.color, size: 16),
              const SizedBox(width: 8),
              Text(
                'Rank: ${route.rank.displayName}',
                style: TextStyle(
                  color: route.rank.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Progress: ${route.progress}/10',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              const SizedBox(width: 8),
              Text(
                'Each advance adds ${_getTicksDescription(route.rank)} based on rank',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

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
