import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a circuit board pattern reveal animation
class CircuitRevealAnimation extends StatelessWidget {
  /// The progress of the animation (0.0 to 1.0)
  final double progress;
  
  /// The color of the circuit lines
  final Color color;
  
  /// The direction of the reveal
  final CircuitRevealDirection direction;
  
  /// The density of the circuit pattern (higher = more dense)
  final double density;
  
  const CircuitRevealAnimation({
    super.key,
    required this.progress,
    this.color = Colors.green,
    this.direction = CircuitRevealDirection.centerOut,
    this.density = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: CircuitRevealPainter(
          progress: progress,
          color: color,
          direction: direction,
          density: density,
        ),
        child: Container(),
      ),
    );
  }
}

/// The direction of the circuit reveal effect
enum CircuitRevealDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
  centerOut,
}

/// Custom painter for drawing the circuit reveal animation
class CircuitRevealPainter extends CustomPainter {
  final double progress;
  final Color color;
  final CircuitRevealDirection direction;
  final double density;
  final Random _random = Random(42); // Fixed seed for consistent animation
  
  CircuitRevealPainter({
    required this.progress,
    required this.color,
    required this.direction,
    required this.density,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final nodePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Calculate grid size based on density
    final gridSize = 30.0 / density;
    final cols = (size.width / gridSize).ceil() + 1;
    final rows = (size.height / gridSize).ceil() + 1;
    
    // Generate circuit nodes
    final nodes = <Offset>[];
    for (int i = 0; i < (cols * rows * 0.3).ceil(); i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      nodes.add(Offset(x, y));
    }
    
    // Generate circuit paths
    final paths = <Path>[];
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        if (_random.nextDouble() < 0.1) { // Only connect some nodes
          final path = Path();
          path.moveTo(nodes[i].dx, nodes[i].dy);
          
          // Add some randomness to the path
          if (_random.nextBool()) {
            // Straight line
            path.lineTo(nodes[j].dx, nodes[j].dy);
          } else {
            // L-shaped line
            if (_random.nextBool()) {
              path.lineTo(nodes[j].dx, nodes[i].dy);
              path.lineTo(nodes[j].dx, nodes[j].dy);
            } else {
              path.lineTo(nodes[i].dx, nodes[j].dy);
              path.lineTo(nodes[j].dx, nodes[j].dy);
            }
          }
          
          paths.add(path);
        }
      }
    }
    
    // Draw based on progress and direction
    for (int i = 0; i < paths.length; i++) {
      final pathProgress = _getPathProgress(i, paths.length);
      if (pathProgress <= progress) {
        canvas.drawPath(paths[i], paint);
      }
    }
    
    // Draw nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodeProgress = _getNodeProgress(nodes[i], size);
      if (nodeProgress <= progress) {
        canvas.drawCircle(nodes[i], 3.0, nodePaint);
      }
    }
  }
  
  double _getPathProgress(int index, int total) {
    // Distribute paths across the progress range
    return index / total;
  }
  
  double _getNodeProgress(Offset node, Size size) {
    // Calculate progress based on direction
    switch (direction) {
      case CircuitRevealDirection.leftToRight:
        return node.dx / size.width;
      case CircuitRevealDirection.rightToLeft:
        return 1.0 - (node.dx / size.width);
      case CircuitRevealDirection.topToBottom:
        return node.dy / size.height;
      case CircuitRevealDirection.bottomToTop:
        return 1.0 - (node.dy / size.height);
      case CircuitRevealDirection.centerOut:
        final centerX = size.width / 2;
        final centerY = size.height / 2;
        final dx = node.dx - centerX;
        final dy = node.dy - centerY;
        final distance = sqrt(dx * dx + dy * dy);
        final maxDistance = sqrt(centerX * centerX + centerY * centerY);
        return distance / maxDistance;
    }
  }
  
  @override
  bool shouldRepaint(covariant CircuitRevealPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
