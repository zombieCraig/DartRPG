import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../services/roll_service.dart';
import '../character/panels/character_key_stats_panel.dart';

/// Inline result display for the Quick Roll Panel.
/// Shows the roll outcome compactly without a full dialog.
class QuickRollResultBanner extends StatefulWidget {
  final Move move;
  final MoveRoll moveRoll;
  final Map<String, dynamic> rollResult;
  final VoidCallback onRollAgain;
  final VoidCallback? onShowDetails;
  final bool canBurnMomentum;
  final VoidCallback? onBurnMomentum;
  final Character? character;
  final Function(String text)? onInsertText;

  const QuickRollResultBanner({
    super.key,
    required this.move,
    required this.moveRoll,
    required this.rollResult,
    required this.onRollAgain,
    this.onShowDetails,
    this.canBurnMomentum = false,
    this.onBurnMomentum,
    this.character,
    this.onInsertText,
  });

  @override
  State<QuickRollResultBanner> createState() => _QuickRollResultBannerState();
}

class _QuickRollResultBannerState extends State<QuickRollResultBanner> {
  bool _showStats = false;

  // Snapshot of stats when the panel was last opened, for computing deltas
  late int _snapMomentum;
  late int _snapHealth;
  late int _snapSpirit;
  late int _snapSupply;

  void _takeSnapshot() {
    final c = widget.character!;
    _snapMomentum = c.momentum;
    _snapHealth = c.health;
    _snapSpirit = c.spirit;
    _snapSupply = c.supply;
  }

  void _onStatsChanged(int momentum, int health, int spirit, int supply) {
    if (widget.onInsertText == null) return;

    final deltas = <String>[];
    if (momentum != _snapMomentum) deltas.add('Momentum ${_fmtDelta(momentum - _snapMomentum)}');
    if (health != _snapHealth) deltas.add('Health ${_fmtDelta(health - _snapHealth)}');
    if (spirit != _snapSpirit) deltas.add('Spirit ${_fmtDelta(spirit - _snapSpirit)}');
    if (supply != _snapSupply) deltas.add('Supply ${_fmtDelta(supply - _snapSupply)}');

    if (deltas.isNotEmpty) {
      widget.onInsertText!('\n*[${deltas.join(", ")}]*');
      // Update snapshot so the next adjustment is relative to the new values
      _snapMomentum = momentum;
      _snapHealth = health;
      _snapSpirit = spirit;
      _snapSupply = supply;
    }
  }

  String _fmtDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

  @override
  Widget build(BuildContext context) {
    final outcome = widget.moveRoll.outcome;
    final color = RollService.getOutcomeColor(outcome);
    final isMatch = widget.moveRoll.isMatch;

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
            if (widget.moveRoll.rollType == 'action_roll') ...[
              Text(
                'd6(${widget.moveRoll.actionDie}) + ${widget.moveRoll.stat ?? "?"}(${widget.moveRoll.statValue ?? 0})'
                '${widget.moveRoll.modifier != null && widget.moveRoll.modifier != 0 ? " + ${widget.moveRoll.modifier}" : ""}'
                ' = ${widget.rollResult['actionValue'] ?? (widget.moveRoll.actionDie + (widget.moveRoll.statValue ?? 0) + (widget.moveRoll.modifier ?? 0))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'vs d10(${widget.moveRoll.challengeDice[0]}), d10(${widget.moveRoll.challengeDice[1]})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else if (widget.moveRoll.rollType == 'progress_roll') ...[
              Text(
                'Progress(${widget.moveRoll.progressValue}) vs d10(${widget.moveRoll.challengeDice[0]}), d10(${widget.moveRoll.challengeDice[1]})',
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
                  onPressed: widget.onRollAgain,
                ),
                if (widget.onShowDetails != null)
                  _ActionChip(
                    icon: Icons.info_outline,
                    label: 'Details',
                    onPressed: widget.onShowDetails!,
                  ),
                if (widget.canBurnMomentum && widget.onBurnMomentum != null)
                  _ActionChip(
                    icon: Icons.local_fire_department,
                    label: 'Burn Momentum',
                    onPressed: widget.onBurnMomentum!,
                    color: Colors.orange,
                  ),
                if (widget.character != null)
                  _ActionChip(
                    icon: _showStats ? Icons.expand_less : Icons.tune,
                    label: _showStats ? 'Hide Stats' : 'Adjust Stats',
                    onPressed: () {
                      setState(() {
                        _showStats = !_showStats;
                        if (_showStats) _takeSnapshot();
                      });
                    },
                  ),
              ],
            ),

            // Inline stat adjustment strip
            if (_showStats && widget.character != null) ...[
              const Divider(height: 16),
              CharacterKeyStatsPanel(
                character: widget.character!,
                useCompactMode: true,
                isEditable: true,
                onStatsChanged: _onStatsChanged,
              ),
            ],
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
