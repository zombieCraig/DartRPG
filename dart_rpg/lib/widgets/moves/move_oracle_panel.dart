import 'package:flutter/material.dart';
import '../../models/move.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart';
import '../../utils/dice_roller.dart';
import '../oracles/inline_oracle_result.dart';

/// A widget for displaying and interacting with embedded oracles in a move.
class MoveOraclePanel extends StatefulWidget {
  final Move move;
  final Function(OracleRoll oracleRoll) onOracleRollAdded;

  const MoveOraclePanel({
    super.key,
    required this.move,
    required this.onOracleRollAdded,
  });

  @override
  State<MoveOraclePanel> createState() => _MoveOraclePanelState();
}

class _MoveOraclePanelState extends State<MoveOraclePanel> {
  String? selectedOracleKey;
  OracleRoll? _lastOracleRoll;
  OracleTable? _lastOracleTable;
  
  @override
  void initState() {
    super.initState();
    // Set initial selection to first oracle
    if (widget.move.oracles.isNotEmpty) {
      selectedOracleKey = widget.move.oracles.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.move.hasEmbeddedOracles) {
      return const SizedBox.shrink();
    }

    final oracles = widget.move.oracles;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Oracle Tables',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Oracle dropdown
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Oracle',
                  border: OutlineInputBorder(),
                ),
                value: selectedOracleKey,
                items: oracles.keys.map((key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(oracles[key]!.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedOracleKey = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            // Dice button
            IconButton(
              icon: const Icon(Icons.casino),
              tooltip: 'Roll on Oracle',
              onPressed: selectedOracleKey != null
                  ? () => _rollOnSelectedOracle(context)
                  : null,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
        if (selectedOracleKey != null && oracles[selectedOracleKey]!.matchText != null) ...[
          const SizedBox(height: 8),
          Text(
            oracles[selectedOracleKey]!.matchText!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],

        // Show inline oracle result
        if (_lastOracleRoll != null && _lastOracleTable != null)
          InlineOracleResult(
            table: _lastOracleTable!,
            oracleRoll: _lastOracleRoll!,
            onRollAgain: () => _rollOnSelectedOracle(context),
            onAddToJournal: (roll) {
              widget.onOracleRollAdded(roll);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oracle roll added to journal entry'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }

  void _rollOnSelectedOracle(BuildContext context) {
    if (selectedOracleKey == null) return;

    final oracle = widget.move.oracles[selectedOracleKey]!;
    final oracleTable = oracle.toOracleTable();

    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(oracleTable.diceFormat);
    final total = rollResult['total'] as int;
    final dice = rollResult['dice'] as List<int>;

    // Find the matching row
    String result = 'No result found for roll: $total';
    for (final row in oracleTable.rows) {
      if (row.matchesRoll(total)) {
        result = row.result;
        break;
      }
    }

    // Create an OracleRoll object and display inline
    setState(() {
      _lastOracleTable = oracleTable;
      _lastOracleRoll = OracleRoll(
        oracleName: oracleTable.name,
        oracleTable: oracleTable.id,
        dice: dice,
        result: result,
      );
    });
  }
}
