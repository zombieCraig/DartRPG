import 'package:flutter/material.dart';
import '../../models/move.dart';
import '../../services/roll_service.dart';

/// A card widget for displaying a move in a list.
class MoveCard extends StatelessWidget {
  final Move move;
  final VoidCallback onTap;
  
  const MoveCard({
    super.key,
    required this.move,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(move.name),
        subtitle: Text(
          move.trigger ?? move.description ?? 'No description available',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Tooltip(
          message: RollService.getRollTypeTooltip(move.rollType),
          child: Icon(
            RollService.getRollTypeIcon(move.rollType),
            color: RollService.getRollTypeColor(move.rollType),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
