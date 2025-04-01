import 'package:flutter/material.dart';
import '../../models/character.dart';

/// A component for managing character stats.
class StatPanel extends StatelessWidget {
  final List<CharacterStat> stats;
  final bool isEditable;
  final Function(int, int)? onStatChanged;

  const StatPanel({
    super.key,
    required this.stats,
    this.isEditable = false,
    this.onStatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(stats.length, (index) {
          final stat = stats[index];
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(stat.name),
              ),
              Expanded(
                flex: 3,
                child: isEditable
                    ? Slider(
                        value: stat.value.toDouble(),
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: stat.value.toString(),
                        onChanged: (value) {
                          if (onStatChanged != null) {
                            onStatChanged!(index, value.toInt());
                          }
                        },
                      )
                    : LinearProgressIndicator(
                        value: stat.value / 5,
                        backgroundColor: Colors.grey[300],
                      ),
              ),
              SizedBox(
                width: 24,
                child: Text(
                  stat.value.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        }),
        if (isEditable) ...[
          const SizedBox(height: 8),
          const Text(
            'Note: Stats range from 1-5. Typical characters have one stat at 3, two at 2, and two at 1.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
