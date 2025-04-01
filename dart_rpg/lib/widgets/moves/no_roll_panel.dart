import 'package:flutter/material.dart';
import '../../models/move.dart';

/// A panel for handling moves that don't require a roll.
class NoRollPanel extends StatelessWidget {
  final Move move;
  final Function(Move) onPerform;
  
  const NoRollPanel({
    super.key,
    required this.move,
    required this.onPerform,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Perform Move'),
        onPressed: () {
          onPerform(move);
        },
      ),
    );
  }
}
