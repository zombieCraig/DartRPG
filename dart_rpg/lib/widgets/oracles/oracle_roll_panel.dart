import 'package:flutter/material.dart';
import '../../models/oracle.dart';

/// A panel for rolling on an oracle table.
class OracleRollPanel extends StatelessWidget {
  final OracleTable table;
  final VoidCallback onRoll;
  
  const OracleRollPanel({
    super.key,
    required this.table,
    required this.onRoll,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Oracle table information
        Text(
          table.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        
        if (table.description != null) ...[
          const SizedBox(height: 8),
          Text(
            table.description!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Dice format information
        Text(
          'Dice: ${table.diceFormat}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Roll button
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.casino),
            label: const Text('Roll on Oracle'),
            onPressed: onRoll,
          ),
        ),
      ],
    );
  }
}
