import 'package:flutter/material.dart';
import '../../models/move.dart';

/// A panel for handling progress rolls.
class ProgressRollPanel extends StatefulWidget {
  final Move move;
  final Function(Move, int) onRoll;
  
  const ProgressRollPanel({
    super.key,
    required this.move,
    required this.onRoll,
  });
  
  @override
  State<ProgressRollPanel> createState() => _ProgressRollPanelState();
}

class _ProgressRollPanelState extends State<ProgressRollPanel> {
  int _progressValue = 5; // Default progress value
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Progress:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Progress slider
        Slider(
          value: _progressValue.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _progressValue.toString(),
          onChanged: (value) {
            setState(() {
              _progressValue = value.round();
            });
          },
        ),
        
        // Progress value indicator
        Center(
          child: Text(
            'Progress: $_progressValue',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Roll button
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.trending_up),
            label: const Text('Perform Move'),
            onPressed: () {
              widget.onRoll(widget.move, _progressValue);
            },
          ),
        ),
      ],
    );
  }
}
