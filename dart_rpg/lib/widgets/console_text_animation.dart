import 'dart:async';
import 'package:flutter/material.dart';

/// A callback that provides the next message to display in the console animation.
/// Returns null when there are no more messages to display.
typedef MessageProvider = String? Function();

class ConsoleTextAnimation extends StatefulWidget {
  /// Callback to get the next message to display
  final MessageProvider getNextMessage;
  
  /// Callback when animation is complete
  final VoidCallback onComplete;
  
  /// Callback when a message is fully displayed
  final VoidCallback onMessageComplete;
  
  /// Speed of typing animation
  final Duration typingSpeed;
  
  /// Initial pause before animation starts
  final Duration initialPause;
  
  /// Pause between lines
  final Duration linePause;
  
  /// Reduced pause when loading is complete
  final Duration reducedPause;
  
  /// Whether loading is complete
  final bool isLoadingComplete;
  
  /// Main character name to replace in messages
  final String? mainCharacterName;

  const ConsoleTextAnimation({
    super.key,
    required this.getNextMessage,
    required this.onComplete,
    required this.onMessageComplete,
    required this.typingSpeed,
    required this.initialPause,
    required this.linePause,
    required this.reducedPause,
    required this.isLoadingComplete,
    this.mainCharacterName,
  });

  @override
  State<ConsoleTextAnimation> createState() => _ConsoleTextAnimationState();
}

class _ConsoleTextAnimationState extends State<ConsoleTextAnimation> {
  /// List of messages that have been displayed
  final List<String> _displayedMessages = [];
  
  /// Current message being displayed
  String? _currentMessage;
  
  /// Number of characters displayed for the current message
  int _displayedCharacters = 0;
  
  /// Whether animation is in progress
  bool _isAnimating = false;
  
  /// Timer for typing animation
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startAnimation();
  }
  
  @override
  void didUpdateWidget(ConsoleTextAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If loading status changed, update animation speed
    if (widget.isLoadingComplete != oldWidget.isLoadingComplete) {
      // We don't need to do anything special here, as the next message
      // will automatically use the updated pause duration
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() async {
    // Initial pause before starting
    await Future.delayed(widget.initialPause);
    
    if (!mounted) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    _displayNextMessage();
  }

  void _displayNextMessage() {
    // Get the next message
    final nextMessage = widget.getNextMessage();
    
    // If there are no more messages, animation is complete
    if (nextMessage == null) {
      widget.onComplete();
      return;
    }
    
    // Set the current message
    setState(() {
      _currentMessage = _processMessage(nextMessage);
      _displayedCharacters = 0;
    });
    
    // Start typing animation
    _animateTyping();
  }
  
  String _processMessage(String message) {
    // Replace placeholder with actual character name if available
    if (widget.mainCharacterName != null && message.contains("<player's main character>")) {
      return message.replaceAll("<player's main character>", widget.mainCharacterName!);
    }
    return message;
  }
  
  void _animateTyping() {
    if (_currentMessage == null) return;
    
    // Start typing animation for current message
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_displayedCharacters < _currentMessage!.length) {
          _displayedCharacters++;
        } else {
          timer.cancel();
          
          // Store the completed message temporarily
          final completedMessage = _currentMessage;
          
          // Notify that a message is complete
          widget.onMessageComplete();
          
          // Determine the pause duration based on loading state
          final pauseDuration = widget.isLoadingComplete ? widget.reducedPause : widget.linePause;
          
          // Move to next message after pause
          Future.delayed(pauseDuration, () {
            if (mounted) {
              // Add the completed message to the displayed messages before moving to the next one
              if (completedMessage != null) {
                setState(() {
                  _displayedMessages.add(completedMessage);
                });
              }
              
              _displayNextMessage();
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display previously completed messages
          for (final message in _displayedMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
          
          // Display current message being typed
          if (_currentMessage != null && _displayedCharacters > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _currentMessage!.substring(0, _displayedCharacters),
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
          
          // Blinking cursor
          if (_isAnimating)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: BlinkingCursor(),
            ),
        ],
      ),
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> {
  bool _showCursor = true;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      _showCursor ? "_" : " ",
      style: const TextStyle(
        color: Colors.green,
        fontFamily: 'monospace',
        fontSize: 16,
      ),
    );
  }
}
