import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a digital blocks animation for transitions
class DigitalBlocksAnimation extends StatelessWidget {
  /// The progress of the animation (0.0 to 1.0)
  final double progress;
  
  /// The direction of the wipe effect
  final DigitalWipeDirection direction;
  
  /// The color of the blocks
  final Color color;
  
  /// The size of each block
  final double blockSize;
  
  /// The density of blocks (higher = more blocks)
  final double density;
  
  const DigitalBlocksAnimation({
    super.key,
    required this.progress,
    this.direction = DigitalWipeDirection.leftToRight,
    this.color = Colors.green,
    this.blockSize = 10.0,
    this.density = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: DigitalBlocksPainter(
          progress: progress,
          direction: direction,
          color: color,
          blockSize: blockSize,
          density: density,
        ),
        child: Container(),
      ),
    );
  }
}

/// The direction of the digital wipe effect
enum DigitalWipeDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

/// Custom painter for drawing the digital blocks animation
class DigitalBlocksPainter extends CustomPainter {
  final double progress;
  final DigitalWipeDirection direction;
  final Color color;
  final double blockSize;
  final double density;
  final Random _random = Random(42); // Fixed seed for consistent animation
  
  DigitalBlocksPainter({
    required this.progress,
    required this.direction,
    required this.color,
    required this.blockSize,
    required this.density,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Calculate the number of blocks based on size and density
    final int numBlocksX = (size.width / blockSize * density).ceil();
    final int numBlocksY = (size.height / blockSize * density).ceil();
    
    // Calculate the threshold for showing blocks based on direction
    for (int x = 0; x < numBlocksX; x++) {
      for (int y = 0; y < numBlocksY; y++) {
        // Calculate normalized position (0-1) based on direction
        double normalizedPos;
        switch (direction) {
          case DigitalWipeDirection.leftToRight:
            normalizedPos = x / numBlocksX;
            break;
          case DigitalWipeDirection.rightToLeft:
            normalizedPos = 1.0 - (x / numBlocksX);
            break;
          case DigitalWipeDirection.topToBottom:
            normalizedPos = y / numBlocksY;
            break;
          case DigitalWipeDirection.bottomToTop:
            normalizedPos = 1.0 - (y / numBlocksY);
            break;
        }
        
        // Add some randomness to the threshold
        final double randomOffset = _random.nextDouble() * 0.2;
        final double threshold = normalizedPos + randomOffset;
        
        // Draw the block if it's within the progress threshold
        if (threshold <= progress) {
          // Calculate block position
          final double blockX = x * blockSize;
          final double blockY = y * blockSize;
          
          // Add some randomness to block size
          final double sizeVariation = 0.7 + _random.nextDouble() * 0.6;
          final double actualBlockSize = blockSize * sizeVariation;
          
          // Draw the block with a random opacity
          final double opacity = 0.5 + _random.nextDouble() * 0.5;
          paint.color = color.withOpacity(opacity);
          
          canvas.drawRect(
            Rect.fromLTWH(blockX, blockY, actualBlockSize, actualBlockSize),
            paint,
          );
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant DigitalBlocksPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
