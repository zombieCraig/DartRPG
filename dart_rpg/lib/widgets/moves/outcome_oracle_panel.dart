import 'package:flutter/material.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../models/move_oracle.dart';
import '../../utils/dice_roller.dart';
import '../oracles/oracle_result_view.dart';

/// A widget for displaying and interacting with outcome-specific oracles in a move.
class OutcomeOraclePanel extends StatefulWidget {
  final Move move;
  final String outcome;
  final String? statUsed;
  final Function(OracleRoll oracleRoll) onOracleRollAdded;

  const OutcomeOraclePanel({
    super.key,
    required this.move,
    required this.outcome,
    this.statUsed,
    required this.onOracleRollAdded,
  });

  @override
  State<OutcomeOraclePanel> createState() => _OutcomeOraclePanelState();
}

class _OutcomeOraclePanelState extends State<OutcomeOraclePanel> {
  String? selectedOracleKey;
  
  @override
  void initState() {
    super.initState();
    
    // If we have a stat and this is a weak hit, auto-select the corresponding oracle
    if (widget.outcome == 'weak hit' && widget.statUsed != null) {
      final stat = widget.statUsed!.toLowerCase();
      
      // Try to find an oracle that matches the stat
      for (final key in widget.move.oracles.keys) {
        if (key.toLowerCase() == stat) {
          selectedOracleKey = key;
          break;
        }
      }
    }
    
    // If no oracle was selected and there are oracles available, select the first one
    if (selectedOracleKey == null && widget.move.hasOraclesForOutcome(widget.outcome)) {
      final outcomeOracles = widget.move.getOraclesForOutcome(widget.outcome);
      if (outcomeOracles.isNotEmpty) {
        // Find the key for this oracle
        for (final entry in widget.move.oracles.entries) {
          if (entry.value.id == outcomeOracles.first.id) {
            selectedOracleKey = entry.key;
            break;
          }
        }
      }
    }
    
    // If still no oracle selected, use the first available oracle
    if (selectedOracleKey == null && widget.move.oracles.isNotEmpty) {
      selectedOracleKey = widget.move.oracles.keys.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if the move has oracles for this outcome or has embedded oracles
    if (!widget.move.hasOraclesForOutcome(widget.outcome) && !widget.move.hasEmbeddedOracles) {
      return const SizedBox.shrink();
    }

    final oracles = widget.move.oracles;
    if (oracles.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // For "Explore the System" move, we want to show a specific message
    final isExploreSystem = widget.move.id == 'fe_runners/exploration/explore_the_system';
    final isWeakHit = widget.outcome == 'weak hit';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        
        // Special message for "Explore the System" move on weak hit
        if (isExploreSystem && isWeakHit) ...[
          const Text(
            'Roll on the oracle table for your stat:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ] else ...[
          const Text(
            'Oracle Tables',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
        
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
        
        // Show match text if available
        if (selectedOracleKey != null && oracles[selectedOracleKey]!.matchText != null) ...[
          const SizedBox(height: 8),
          Text(
            oracles[selectedOracleKey]!.matchText!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
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
    
    // Create an OracleRoll object
    final oracleRoll = OracleRoll(
      oracleName: oracleTable.name,
      oracleTable: oracleTable.id,
      dice: dice,
      result: result,
    );
    
    // Show the result
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return OracleResultView(
            table: oracleTable,
            oracleRoll: oracleRoll,
            onClose: () {
              Navigator.pop(context);
            },
            onRollAgain: () {
              Navigator.pop(context);
              _rollOnSelectedOracle(context);
            },
            onAddToJournal: (roll) {
              widget.onOracleRollAdded(roll);
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oracle roll added to journal entry'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
      );
    }
  }
}
