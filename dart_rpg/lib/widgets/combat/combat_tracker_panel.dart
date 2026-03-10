import 'package:flutter/material.dart';
import '../../models/combat.dart';
import '../progress_track_widget.dart';

/// Compact combat tracker widget designed for the QuickRollPanel.
class CombatTrackerPanel extends StatelessWidget {
  final Combat combat;
  final VoidCallback? onMarkProgress;
  final VoidCallback? onMarkProgressDouble;
  final VoidCallback? onDecrease;
  final VoidCallback? onProgressRoll;
  final VoidCallback? onToggleControl;
  final Function(CombatStatus)? onEnd;
  final Function(int)? onTickChanged;

  const CombatTrackerPanel({
    super.key,
    required this.combat,
    this.onMarkProgress,
    this.onMarkProgressDouble,
    this.onDecrease,
    this.onProgressRoll,
    this.onToggleControl,
    this.onEnd,
    this.onTickChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = combat.status == CombatStatus.active;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with rank badge and control toggle
            Row(
              children: [
                Icon(
                  combat.rank.icon,
                  size: 16,
                  color: combat.rank.color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    combat.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive) ...[
                  _buildControlChip(context),
                ] else ...[
                  Chip(
                    label: Text(
                      combat.status.displayName,
                      style: const TextStyle(fontSize: 10),
                    ),
                    avatar: Icon(combat.status.icon, size: 14),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.only(right: 4),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 4),

            // Progress track
            ProgressTrackWidget(
              label: '',
              value: combat.progress,
              ticks: combat.progressTicks,
              maxValue: 10,
              isEditable: isActive,
              showTicks: true,
              onTickChanged: isActive ? onTickChanged : null,
            ),

            // Action buttons (only when active)
            if (isActive) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decrease
                  _buildActionButton(
                    context,
                    icon: Icons.remove,
                    tooltip: 'Decrease progress',
                    onPressed: onDecrease,
                    color: Theme.of(context).colorScheme.errorContainer,
                    foreground: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  // Mark progress x1
                  _buildActionButton(
                    context,
                    icon: Icons.add,
                    tooltip: 'Mark progress',
                    onPressed: onMarkProgress,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    foreground: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  // Mark progress x2
                  _buildActionButton(
                    context,
                    label: 'x2',
                    tooltip: 'Mark progress x2',
                    onPressed: onMarkProgressDouble,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    foreground: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  // Take Decisive Action (progress roll)
                  _buildActionButton(
                    context,
                    icon: Icons.casino,
                    tooltip: 'Take Decisive Action',
                    onPressed: onProgressRoll,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    foreground: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  // End combat
                  PopupMenuButton<CombatStatus>(
                    tooltip: 'End combat',
                    onSelected: onEnd,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: CombatStatus.won,
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Won'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: CombatStatus.lost,
                        child: Row(
                          children: [
                            Icon(Icons.dangerous, size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Lost'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: CombatStatus.fled,
                        child: Row(
                          children: [
                            Icon(Icons.directions_run, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Fled'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.flag,
                        size: 16,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlChip(BuildContext context) {
    final inControl = combat.isInControl;
    return GestureDetector(
      onTap: onToggleControl,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: inControl
              ? Colors.green.withAlpha(40)
              : Colors.red.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inControl ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Text(
          inControl ? 'In Control' : 'Bad Spot',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: inControl ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    IconData? icon,
    String? label,
    required String tooltip,
    VoidCallback? onPressed,
    required Color color,
    required Color foreground,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: foreground)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
        ),
      ),
    );
  }
}
