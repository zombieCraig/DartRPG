import 'package:flutter/material.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart';
import '../oracle_result_text.dart';

/// An embeddable widget for displaying oracle roll results inline
/// (without spawning a new dialog).
class InlineOracleResult extends StatelessWidget {
  final OracleTable table;
  final OracleRoll oracleRoll;
  final VoidCallback onRollAgain;
  final Function(OracleRoll) onAddToJournal;

  const InlineOracleResult({
    super.key,
    required this.table,
    required this.oracleRoll,
    required this.onRollAgain,
    required this.onAddToJournal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${table.name} Result',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Roll: ${oracleRoll.dice.join(', ')}'),
          const SizedBox(height: 8),

          // Result text with clickable links
          OracleResultText(
            text: oracleRoll.result,
            style: const TextStyle(fontWeight: FontWeight.bold),
            processReferences: true,
          ),

          // Show nested oracle rolls if any
          if (oracleRoll.nestedRolls.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const Text(
              'Nested Oracle Rolls:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...oracleRoll.nestedRolls.map(
              (nestedRoll) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${nestedRoll.oracleName} (Roll: ${nestedRoll.dice.join(', ')})',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nestedRoll.result,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Action chips
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.casino, size: 18),
                label: const Text('Roll Again'),
                onPressed: onRollAgain,
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Add to Journal'),
                onPressed: () => onAddToJournal(oracleRoll),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
