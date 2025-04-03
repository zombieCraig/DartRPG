import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../providers/game_provider.dart';
import '../utils/dice_roller.dart';
import '../services/roll_service.dart';
import 'progress_track_widget.dart';

/// A widget that displays a condition meter for an asset control.
class ConditionMeterWidget extends StatelessWidget {
  final AssetControl control;
  final Function(int)? onValueChanged;
  final Function()? onRoll;
  final bool isEditable;

  const ConditionMeterWidget({
    super.key,
    required this.control,
    this.onValueChanged,
    this.onRoll,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              control.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (control.rollable && isEditable)
              IconButton(
                icon: const Icon(Icons.casino),
                onPressed: onRoll ?? () => _handleControlRoll(context),
                tooltip: 'Roll challenge dice + 1d6 + current value',
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
          ],
        ),
        ProgressTrackWidget(
          label: '', // Label already shown above
          value: control.valueAsInt,
          maxValue: control.max,
          onBoxChanged: isEditable ? onValueChanged : null,
          isEditable: isEditable,
        ),
        
        // Display nested controls if any
        if (control.controls.isNotEmpty) ...[
          const Divider(height: 16),
          ...control.controls.entries.map((entry) {
            final nestedControl = entry.value;
            if (nestedControl.fieldType == 'checkbox') {
              return CheckboxListTile(
                title: Text(nestedControl.label),
                value: nestedControl.valueAsBool,
                onChanged: isEditable 
                  ? (value) {
                      // Update the nested control value
                      nestedControl.setValue(value);
                      
                      // Save the game
                      Provider.of<GameProvider>(context, listen: false).saveGame();
                    }
                  : null,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              );
            } else if (nestedControl.fieldType != 'condition_meter') {
              // Show warning for unsupported field types
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Warning: Unsupported control field type "${nestedControl.fieldType}" for ${nestedControl.label}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ],
    );
  }

  /// Handle rolling for the control
  void _handleControlRoll(BuildContext context) {
    // Roll 2d10 (challenge dice) + 1d6 + current value
    final d6Roll = DiceRoller.rollDie(6);
    final challengeDice = DiceRoller.rollDice(2, 10);
    final actionValue = d6Roll + control.valueAsInt;
    
    // Determine outcome
    final strongHit = actionValue > challengeDice[0] && actionValue > challengeDice[1];
    final weakHit = (actionValue > challengeDice[0] && actionValue <= challengeDice[1]) ||
                  (actionValue <= challengeDice[0] && actionValue > challengeDice[1]);
    final isMatch = challengeDice[0] == challengeDice[1];
    
    String outcome;
    if (strongHit) {
      outcome = isMatch ? 'strong hit with a match' : 'strong hit';
    } else if (weakHit) {
      outcome = 'weak hit';
    } else {
      outcome = isMatch ? 'miss with a match' : 'miss';
    }
    
    // Show result dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${control.label} Roll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action die: $d6Roll'),
            Text('Control value: ${control.valueAsInt}'),
            Text('Action total: $actionValue'),
            Text('Challenge dice: ${challengeDice[0]}, ${challengeDice[1]}'),
            const Divider(),
            Text(
              'Outcome: $outcome', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: RollService.getOutcomeColor(outcome),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
