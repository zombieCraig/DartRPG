import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../models/journal_entry.dart';
import '../../models/character.dart';
import '../../models/location.dart';

/// Static methods for showing detail dialogs for journal-linked items.
class JournalDetailDialogs {
  JournalDetailDialogs._();

  static Color getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Colors.green;
      case 'weak hit':
        return Colors.orange;
      case 'miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static void showMoveRollDetails(BuildContext context, MoveRoll moveRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${moveRoll.moveName} Roll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moveRoll.moveDescription != null) ...[
                  MarkdownBody(
                    data: moveRoll.moveDescription!,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                      textAlign: WrapAlignment.start,
                    ),
                    softLineBreak: true,
                  ),
                  const SizedBox(height: 16),
                ],

                if (moveRoll.rollType == 'action_roll') ...[
                  Text('Action Die: ${moveRoll.actionDie}'),

                  if (moveRoll.statValue != null) ...[
                    const SizedBox(height: 4),
                    Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                    const SizedBox(height: 4),
                    Text('Total Action Value: ${moveRoll.actionDie + moveRoll.statValue!}'),
                  ],

                  if (moveRoll.modifier != null && moveRoll.modifier != 0) ...[
                    const SizedBox(height: 4),
                    Text('Modifier: ${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}'),
                  ],
                ],

                if (moveRoll.rollType == 'progress_roll' && moveRoll.progressValue != null) ...[
                  Text('Progress Value: ${moveRoll.progressValue}'),
                ],

                if (moveRoll.challengeDice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                ],

                if (moveRoll.outcome != 'performed') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Outcome: ${moveRoll.outcome.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getOutcomeColor(moveRoll.outcome),
                    ),
                  ),

                  if (moveRoll.momentumBurned) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Momentum Burned',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Move performed successfully',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),

                  if (moveRoll.rollType == 'oracle_roll' &&
                      moveRoll.moveData != null &&
                      moveRoll.moveData!.containsKey('oracleResult')) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Oracle Result: ${moveRoll.moveData!['oracleResult']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showOracleRollDetails(BuildContext context, OracleRoll oracleRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${oracleRoll.oracleName} Result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oracleRoll.oracleTable != null) ...[
                  Text('Table: ${oracleRoll.oracleTable}'),
                  const SizedBox(height: 8),
                ],

                Text('Roll: ${oracleRoll.dice.join(', ')}'),
                const SizedBox(height: 16),

                Text(
                  'Result: ${oracleRoll.result}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showCharacterDetails(BuildContext context, Character character) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(character.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (character.bio != null && character.bio!.isNotEmpty) ...[
                  const Text(
                    'Bio:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(character.bio!),
                  const SizedBox(height: 16),
                ],

                if (character.stats.isNotEmpty) ...[
                  const Text(
                    'Stats:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: character.stats.map((stat) =>
                      Chip(
                        label: Text('${stat.name}: ${stat.value}'),
                        backgroundColor: Colors.grey[200],
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                if (character.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...character.notes.map((note) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showLocationDetails(BuildContext context, Location location) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(location.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.description != null && location.description!.isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(location.description!),
                  const SizedBox(height: 16),
                ],

                if (location.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...location.notes.map((note) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
