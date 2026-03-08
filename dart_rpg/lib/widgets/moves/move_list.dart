import 'package:flutter/material.dart';
import '../../models/move.dart';
import 'move_card.dart';

/// A widget for displaying a list of moves.
class MoveList extends StatelessWidget {
  final List<Move> moves;
  final Function(Move) onMoveTap;
  final bool preSorted;

  const MoveList({
    super.key,
    required this.moves,
    required this.onMoveTap,
    this.preSorted = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedMoves = preSorted ? moves : (List<Move>.from(moves)..sort((a, b) => a.name.compareTo(b.name)));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMoves.length,
      itemBuilder: (context, index) {
        final move = sortedMoves[index];
        
        return MoveCard(
          move: move,
          onTap: () => onMoveTap(move),
        );
      },
    );
  }
}
