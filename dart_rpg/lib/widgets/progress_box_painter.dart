import 'package:flutter/material.dart';

/// A custom painter that draws a progress box with 0-4 ticks
class ProgressBoxPainter extends CustomPainter {
  final int ticks; // 0-4 ticks
  final Color boxColor;
  final Color tickColor;
  final Color borderColor;
  final bool isHighlighted;

  ProgressBoxPainter({
    required this.ticks,
    required this.boxColor,
    required this.tickColor,
    required this.borderColor,
    this.isHighlighted = false,
  }) : assert(ticks >= 0 && ticks <= 4, 'Ticks must be between 0 and 4');

  @override
  void paint(Canvas canvas, Size size) {
    // Create a rectangle with some padding to ensure borders are fully visible
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    
    // Draw the box background
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // Draw a clear border for all boxes
    paint
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, paint);

    // If the box is full (4 ticks), fill it completely
    if (ticks == 4) {
      paint
        ..color = tickColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
      
      // Add a border to the filled box
      paint
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, paint);
      return;
    }

    // If this is the highlighted box (active box), draw a thicker border
    if (isHighlighted) {
      paint
        ..color = tickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRect(rect, paint);
    }

    // Apply clipping to ensure ticks stay within the box
    canvas.save();
    canvas.clipRect(rect);
    
    // Draw the ticks based on count
    if (ticks > 0) {
      paint
        ..color = tickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0; // Thicker lines for better visibility

      final center = Offset(size.width / 2, size.height / 2);
      // We can keep the current radius since we're using clipping
      final radius = size.width * 0.22;

      if (ticks >= 1) {
        // First tick: diagonal line (/)
        canvas.drawLine(
          Offset(center.dx - radius, center.dy + radius),
          Offset(center.dx + radius, center.dy - radius),
          paint,
        );
      }

      if (ticks >= 2) {
        // Second tick: diagonal line (\) to form an X with the first tick
        canvas.drawLine(
          Offset(center.dx - radius, center.dy - radius),
          Offset(center.dx + radius, center.dy + radius),
          paint,
        );
      }

      if (ticks >= 3) {
        // Third tick: horizontal line (-)
        canvas.drawLine(
          Offset(center.dx - radius, center.dy),
          Offset(center.dx + radius, center.dy),
          paint,
        );
      }
    }
    
    // Restore the canvas state (remove clipping)
    canvas.restore();
  }

  @override
  bool shouldRepaint(ProgressBoxPainter oldDelegate) {
    return ticks != oldDelegate.ticks ||
        boxColor != oldDelegate.boxColor ||
        tickColor != oldDelegate.tickColor ||
        borderColor != oldDelegate.borderColor ||
        isHighlighted != oldDelegate.isHighlighted;
  }
}
