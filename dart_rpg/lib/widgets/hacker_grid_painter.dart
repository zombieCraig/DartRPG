import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom painter that renders a hacker-themed grid background with pulsating effects.
class HackerGridPainter extends CustomPainter {
  final Animation<double> pulseAnimation;
  final Animation<double> flowAnimation;
  final Color primaryColor;
  final Color secondaryColor;
  final double gridSpacing;
  final bool showDataFlow;

  HackerGridPainter({
    required this.pulseAnimation,
    required this.flowAnimation,
    this.primaryColor = const Color(0xFF00FFFF), // Cyan
    this.secondaryColor = const Color(0xFF0088FF), // Blue
    this.gridSpacing = 40.0,
    this.showDataFlow = true,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw background
    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(217); // 0.85 opacity = 217 alpha
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

    // Calculate grid lines
    final horizontalLines = (height / gridSpacing).ceil() + 1;
    final verticalLines = (width / gridSpacing).ceil() + 1;

    // Draw grid lines with pulsating effect
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = primaryColor.withAlpha(((0.3 + 0.2 * pulseAnimation.value) * 255).toInt()); // Dynamic alpha based on animation

    // Draw horizontal grid lines
    for (int i = 0; i < horizontalLines; i++) {
      final y = i * gridSpacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        gridPaint,
      );
    }

    // Draw vertical grid lines
    for (int i = 0; i < verticalLines; i++) {
      final x = i * gridSpacing;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        gridPaint,
      );
    }

    // Draw accent lines (brighter lines that appear periodically)
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = primaryColor.withAlpha(((0.5 + 0.3 * pulseAnimation.value) * 255).toInt()); // Dynamic alpha based on animation

    // Horizontal accent lines (every 4 lines)
    for (int i = 0; i < horizontalLines; i += 4) {
      final y = i * gridSpacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(width, y),
        accentPaint,
      );
    }

    // Vertical accent lines (every 4 lines)
    for (int i = 0; i < verticalLines; i += 4) {
      final x = i * gridSpacing;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        accentPaint,
      );
    }

    // Draw data flow effects if enabled
    if (showDataFlow) {
      _drawDataFlowEffects(canvas, size);
    }
  }

  void _drawDataFlowEffects(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Number of data packets to draw
    final packetCount = 5;
    
    // Data flow paint
    final flowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = secondaryColor.withAlpha(((0.6 * pulseAnimation.value) * 255).toInt()); // Dynamic alpha based on animation
    
    // Use flowAnimation to determine position of data packets
    final random = math.Random(42); // Fixed seed for deterministic randomness
    
    for (int i = 0; i < packetCount; i++) {
      // Determine if this packet flows horizontally or vertically
      final isHorizontal = random.nextBool();
      
      // Calculate position based on animation value
      if (isHorizontal) {
        final y = (random.nextInt(height ~/ gridSpacing) * gridSpacing).toDouble();
        final startX = -20.0 + (width + 40) * ((flowAnimation.value + i / packetCount) % 1.0);
        
        // Draw data packet
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, y - 2, 15, 4),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, flowPaint);
      } else {
        final x = (random.nextInt(width ~/ gridSpacing) * gridSpacing).toDouble();
        final startY = -20.0 + (height + 40) * ((flowAnimation.value + i / packetCount) % 1.0);
        
        // Draw data packet
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2, startY, 4, 15),
          const Radius.circular(2),
        );
        canvas.drawRRect(rect, flowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HackerGridPainter oldDelegate) {
    return oldDelegate.pulseAnimation != pulseAnimation ||
        oldDelegate.flowAnimation != flowAnimation ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.gridSpacing != gridSpacing ||
        oldDelegate.showDataFlow != showDataFlow;
  }
}
