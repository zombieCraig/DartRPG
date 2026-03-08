import 'package:flutter/material.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../services/roll_service.dart';

/// Inline result display for the Quick Roll Panel.
/// Shows the roll outcome compactly without a full dialog.
class QuickRollResultBanner extends StatelessWidget {
  final Move move;
  final MoveRoll moveRoll;
  final Map<String, dynamic> rollResult;
  final VoidCallback onRollAgain;
  final VoidCallback? onShowDetails;
  final bool canBurnMomentum;
  final VoidCallback? onBurnMomentum;

  const QuickRollResultBanner({
    super.key,
    required this.move,
    required this.moveRoll,
    required this.rollResult,
    required this.onRollAgain,
    this.onShowDetails,
    this.canBurnMomentum = false,
    this.onBurnMomentum,
  });

  @override
  Widget build(BuildContext context) {
    final outcome = moveRoll.outcome;
    final color = RollService.getOutcomeColor(outcome);
    final isMatch = moveRoll.isMatch;

    return Card(
      color: color.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Outcome header
            Row(
              children: [
                Icon(
                  _getOutcomeIcon(outcome),
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatOutcome(outcome),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'MATCH',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Dice details
            if (moveRoll.rollType == 'action_roll') ...[
              Text(
                'd6(${moveRoll.actionDie}) + ${moveRoll.stat ?? "?"}(${moveRoll.statValue ?? 0})'
                '${moveRoll.modifier != null && moveRoll.modifier != 0 ? " + ${moveRoll.modifier}" : ""}'
                ' = ${rollResult['actionValue'] ?? (moveRoll.actionDie + (moveRoll.statValue ?? 0) + (moveRoll.modifier ?? 0))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'vs d10(${moveRoll.challengeDice[0]}), d10(${moveRoll.challengeDice[1]})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (moveRoll.rollType == 'progress_roll') ...[
              Text(
                'Progress(${moveRoll.progressValue}) vs d10(${moveRoll.challengeDice[0]}), d10(${moveRoll.challengeDice[1]})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 8),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _ActionChip(
                  icon: Icons.refresh,
                  label: 'Roll Again',
                  onPressed: onRollAgain,
                ),
                if (onShowDetails != null)
                  _ActionChip(
                    icon: Icons.info_outline,
                    label: 'Details',
                    onPressed: onShowDetails!,
                  ),
                if (canBurnMomentum && onBurnMomentum != null)
                  _ActionChip(
                    icon: Icons.local_fire_department,
                    label: 'Burn Momentum',
                    onPressed: onBurnMomentum!,
                    color: Colors.orange,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatOutcome(String outcome) {
    return outcome.split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  IconData _getOutcomeIcon(String outcome) {
    if (outcome.contains('strong hit')) return Icons.check_circle;
    if (outcome.contains('weak hit')) return Icons.warning_amber;
    if (outcome.contains('miss')) return Icons.cancel;
    return Icons.check_circle_outline;
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
