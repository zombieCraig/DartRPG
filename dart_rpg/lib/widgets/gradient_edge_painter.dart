import 'package:flutter/material.dart';
import '../models/location.dart';

class GradientEdgePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color startColor;
  final Color endColor;
  
  GradientEdgePainter({
    required this.start,
    required this.end,
    required this.startColor,
    required this.endColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromPoints(start, end))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(start, end, paint);
  }
  
  @override
  bool shouldRepaint(covariant GradientEdgePainter oldDelegate) {
    return oldDelegate.start != start ||
           oldDelegate.end != end ||
           oldDelegate.startColor != startColor ||
           oldDelegate.endColor != endColor;
  }
}
