import 'package:flutter/material.dart';
import 'package:dart_rpg/widgets/progress_box_painter.dart';

class ProgressTrackWidget extends StatelessWidget {
  final String label;
  final int value; // Value in boxes (0-10)
  final int ticks; // Value in ticks (0-40)
  final int maxValue; // Max value in boxes
  final Function(int)? onBoxChanged; // Callback when box value changes
  final Function(int)? onTickChanged; // Callback when tick value changes
  final bool isEditable;
  final bool showTicks; // Whether to show ticks or just filled boxes

  const ProgressTrackWidget({
    super.key,
    required this.label,
    this.value = 0,
    this.ticks = 0,
    this.maxValue = 10,
    this.onBoxChanged,
    this.onTickChanged,
    this.isEditable = true,
    this.showTicks = true,
  });

  // Calculate the number of ticks in a specific box
  int _getTicksInBox(int boxIndex) {
    if (boxIndex < value) {
      return 4; // Full box
    } else if (boxIndex == value && ticks % 4 > 0) {
      return ticks % 4; // Partially filled box
    } else {
      return 0; // Empty box
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).colorScheme.outline;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40, // Increased height for better visibility
                child: Row(
                  children: List.generate(maxValue, (index) {
                    final boxTicks = showTicks ? _getTicksInBox(index) : (index < value ? 4 : 0);
                    final isHighlighted = isEditable && index == value && boxTicks < 4;
                    
                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0, // Make boxes square
                        child: GestureDetector(
                          onTap: isEditable ? () {
                            if (showTicks && onTickChanged != null) {
                              // Calculate new tick value
                              int newTicks;
                              if (index < value) {
                                // If tapping a full box, set to this box with 1 tick
                                newTicks = index * 4 + 1;
                              } else if (index == value) {
                                // If tapping current box, increment tick or move to next box
                                int currentTicks = ticks % 4;
                                if (currentTicks < 4) {
                                  newTicks = (index * 4) + currentTicks + 1;
                                } else {
                                  newTicks = (index + 1) * 4;
                                }
                              } else {
                                // If tapping an empty box ahead, set to this box with 1 tick
                                newTicks = index * 4 + 1;
                              }
                              onTickChanged!(newTicks);
                            } else if (onBoxChanged != null) {
                              // Legacy behavior: fill the box completely
                              onBoxChanged!(index + 1);
                            }
                          } : null,
                          child: Container(
                            margin: const EdgeInsets.all(3), // Increased margin for better spacing
                            child: showTicks
                                ? CustomPaint(
                                    painter: ProgressBoxPainter(
                                      ticks: boxTicks,
                                      boxColor: backgroundColor,
                                      tickColor: primaryColor,
                                      borderColor: borderColor,
                                      isHighlighted: isHighlighted,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: boxTicks == 4
                                          ? primaryColor
                                          : backgroundColor,
                                      border: Border.all(color: borderColor, width: 2.0),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$value/$maxValue'), // Always show box ratio
          ],
        ),
      ],
    );
  }
}
