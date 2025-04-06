import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays a Matrix-style digital rain animation
class MatrixRainAnimation extends StatefulWidget {
  /// The opacity of the animation
  final double opacity;
  
  /// The color of the characters
  final Color color;
  
  /// The speed of the animation (1.0 is normal speed)
  final double speed;
  
  /// Whether to use a more complex character set (Japanese-like characters)
  final bool useComplexChars;
  
  const MatrixRainAnimation({
    super.key,
    this.opacity = 0.7,
    this.color = Colors.green,
    this.speed = 1.0,
    this.useComplexChars = false,
  });

  @override
  State<MatrixRainAnimation> createState() => _MatrixRainAnimationState();
}

class _MatrixRainAnimationState extends State<MatrixRainAnimation> {
  late List<RainColumn> _columns;
  late Timer _timer;
  late Random _random;
  late Size _size;
  
  // Character sets
  static const String _binaryChars = '01';
  static const String _complexChars = 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦﾝ0123456789';
  
  @override
  void initState() {
    super.initState();
    _random = Random();
    _columns = [];
    
    // Initialize with a dummy size, will be updated in didChangeDependencies
    _size = const Size(300, 500);
    
    // Start the animation timer
    _timer = Timer.periodic(
      Duration(milliseconds: (50 / widget.speed).round()),
      _updateRain,
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the screen size
    _size = MediaQuery.of(context).size;
    _initializeColumns();
  }
  
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  
  void _initializeColumns() {
    _columns = [];
    
    // Calculate number of columns based on width
    final columnWidth = 14.0; // Width of each character column
    final numColumns = (_size.width / columnWidth).ceil();
    
    // Create columns with random properties
    for (int i = 0; i < numColumns; i++) {
      _columns.add(RainColumn(
        x: i * columnWidth,
        speed: 2 + _random.nextDouble() * 5,
        length: 5 + _random.nextInt(15),
        startY: -100.0 - _random.nextDouble() * 500,
        charSet: widget.useComplexChars ? _complexChars : _binaryChars,
        random: _random,
      ));
    }
  }
  
  void _updateRain(Timer timer) {
    if (!mounted) return;
    
    setState(() {
      for (var column in _columns) {
        column.update(_size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: Container(
        color: Colors.black,
        width: _size.width,
        height: _size.height,
        child: CustomPaint(
          painter: MatrixRainPainter(
            columns: _columns,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// A class representing a single column of falling characters
class RainColumn {
  final double x;
  double y;
  final double speed;
  final int length;
  final String charSet;
  final Random random;
  late List<String> chars;
  late List<double> opacities;
  
  RainColumn({
    required this.x,
    required this.speed,
    required this.length,
    required double startY,
    required this.charSet,
    required this.random,
  }) : y = startY {
    // Initialize with random characters
    chars = List.generate(
      length,
      (_) => charSet[random.nextInt(charSet.length)],
    );
    
    // Initialize with decreasing opacity for trailing characters
    opacities = List.generate(
      length,
      (index) => 1.0 - (index / length),
    );
  }
  
  void update(double maxHeight) {
    // Move the column down
    y += speed;
    
    // Reset if it's gone off screen
    if (y - length * 20 > maxHeight) {
      y = -100.0 - random.nextDouble() * 200;
    }
    
    // Randomly change some characters
    for (int i = 0; i < length; i++) {
      if (random.nextDouble() < 0.1) {
        chars[i] = charSet[random.nextInt(charSet.length)];
      }
    }
  }
}

/// Custom painter for drawing the matrix rain
class MatrixRainPainter extends CustomPainter {
  final List<RainColumn> columns;
  final Color color;
  
  MatrixRainPainter({
    required this.columns,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var column in columns) {
      // Draw each character in the column
      for (int i = 0; i < column.length; i++) {
        final textStyle = TextStyle(
          color: color.withOpacity(column.opacities[i]),
          fontSize: 14,
          fontFamily: 'monospace',
        );
        
        final textSpan = TextSpan(
          text: column.chars[i],
          style: textStyle,
        );
        
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout();
        
        // Position and draw the character
        final yPos = column.y - i * 20;
        if (yPos > -20 && yPos < size.height) {
          textPainter.paint(canvas, Offset(column.x, yPos));
        }
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
