import 'package:flutter/material.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart';
import '../oracle_result_text.dart';

/// A widget for displaying the results of an oracle roll.
class OracleResultView extends StatelessWidget {
  final OracleTable table;
  final OracleRoll oracleRoll;
  final VoidCallback onClose;
  final VoidCallback onRollAgain;
  final Function(OracleRoll) onAddToJournal;
  
  const OracleResultView({
    super.key,
    required this.table,
    required this.oracleRoll,
    required this.onClose,
    required this.onRollAgain,
    required this.onAddToJournal,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${table.name} Result'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roll: ${oracleRoll.dice.join(', ')}'),
            const SizedBox(height: 16),
            
            // Use OracleResultText widget to display the result with clickable links and processed references
            OracleResultText(
              text: oracleRoll.result,
              style: const TextStyle(fontWeight: FontWeight.bold),
              processReferences: true,
            ),
            
            // Show nested oracle rolls if any
            if (oracleRoll.nestedRolls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Nested Oracle Rolls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // List all nested rolls
              ...oracleRoll.nestedRolls.map((nestedRoll) => 
                Padding(
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: onRollAgain,
          child: const Text('Roll Again'),
        ),
        TextButton(
          onPressed: () => onAddToJournal(oracleRoll),
          child: const Text('Add to Journal'),
        ),
      ],
    );
  }
}
