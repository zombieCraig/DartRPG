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
  final FocusNode _rollButtonFocusNode = FocusNode();
  final GlobalKey _rollButtonKey = GlobalKey();
  
  @override
  void dispose() {
    _rollButtonFocusNode.dispose();
    super.dispose();
  }
  
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
              
              // Schedule a post-frame callback to focus and scroll to the roll button
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Focus the roll button
                _rollButtonFocusNode.requestFocus();
                
                // Scroll to make the roll button visible
                final context = _rollButtonKey.currentContext;
                if (context != null) {
                  Scrollable.ensureVisible(
                    context,
                    alignment: 0.5, // Center the button in the viewport
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
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
            key: _rollButtonKey,
            focusNode: _rollButtonFocusNode,
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
