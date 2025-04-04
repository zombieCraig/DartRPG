import 'package:flutter/material.dart';
import '../../models/clock.dart';
import '../../widgets/clock_segment_painter.dart';

/// A panel for displaying and managing clock progress
class ClockProgressPanel extends StatelessWidget {
  /// The clock to display progress for
  final Clock clock;
  
  /// Callback for when the advance button is pressed
  final VoidCallback? onAdvance;
  
  /// Callback for when the reset button is pressed
  final VoidCallback? onReset;
  
  /// Whether the panel is editable
  final bool isEditable;
  
  /// Creates a new ClockProgressPanel
  const ClockProgressPanel({
    super.key,
    required this.clock,
    this.onAdvance,
    this.onReset,
    this.isEditable = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Clock visualization
        SizedBox(
          height: 150,
          width: 150,
          child: CustomPaint(
            painter: ClockSegmentPainter(
              segments: clock.segments,
              filledSegments: clock.progress,
              fillColor: clock.type.color,
              emptyColor: Colors.grey.shade200,
              borderColor: Colors.grey.shade600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress information
        Text(
          'Progress: ${clock.progress}/${clock.segments}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Clock type information
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              clock.type.icon,
              color: clock.type.color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Type: ${clock.type.displayName}',
              style: TextStyle(
                color: clock.type.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Progress buttons (only if editable)
        if (isEditable && !clock.isComplete)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Advance'),
                onPressed: onAdvance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                onPressed: onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        
        // Completed message
        if (clock.isComplete)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade700),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Clock Filled',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
