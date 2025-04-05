import 'dart:math';
import 'package:flutter/material.dart';

/// A custom painter for drawing a segmented clock
class ClockSegmentPainter extends CustomPainter {
  /// The total number of segments in the clock
  final int segments;
  
  /// The number of filled segments
  final int filledSegments;
  
  /// The color for filled segments
  final Color fillColor;
  
  /// The color for empty segments
  final Color emptyColor;
  
  /// The color for the border
  final Color borderColor;
  
  /// The stroke width for the border
  final double strokeWidth;
  
  /// Creates a new ClockSegmentPainter
  ClockSegmentPainter({
    required this.segments,
    required this.filledSegments,
    required this.fillColor,
    required this.emptyColor,
    this.borderColor = Colors.black,
    this.strokeWidth = 2.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - strokeWidth;
    
    // Draw the outer circle
    final outerCirclePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, outerCirclePaint);
    
    // Calculate the angle for each segment
    final segmentAngle = 2 * pi / segments;
    
    // Draw each segment
    for (int i = 0; i < segments; i++) {
      final startAngle = -pi / 2 + i * segmentAngle; // Start from the top (12 o'clock position)
      
      // Determine if this segment should be filled
      final isFilled = i < filledSegments;
      
      // Create the segment path
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * cos(startAngle),
          center.dy + radius * sin(startAngle)
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false
        )
        ..lineTo(center.dx, center.dy);
      
      // Draw the segment
      final segmentPaint = Paint()
        ..color = isFilled ? fillColor : emptyColor
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, segmentPaint);
      
      // Draw the segment border
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      
      canvas.drawPath(path, borderPaint);
    }
  }
  
  @override
  bool shouldRepaint(ClockSegmentPainter oldDelegate) {
    return oldDelegate.segments != segments ||
           oldDelegate.filledSegments != filledSegments ||
           oldDelegate.fillColor != fillColor ||
           oldDelegate.emptyColor != emptyColor ||
           oldDelegate.borderColor != borderColor ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}
