import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A compact summary of character stats for mobile displays.
class MobileStatsSummary extends StatelessWidget {
  final Character character;

  const MobileStatsSummary({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withAlpha(128)),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey.withAlpha(26),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('M', character.momentum, Colors.blue),
          _buildStatItem('H', character.health, Colors.red),
          _buildStatItem('S', character.spirit, Colors.purple),
          _buildStatItem('Su', character.supply, Colors.amber[700]!),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, int value, Color color) {
    return Tooltip(
      message: _getFullStatName(label),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color.withAlpha(204),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getFullStatName(String shortLabel) {
    switch (shortLabel) {
      case 'M':
        return 'Momentum';
      case 'H':
        return 'Health';
      case 'S':
        return 'Spirit';
      case 'Su':
        return 'Supply';
      default:
        return shortLabel;
    }
  }
}
