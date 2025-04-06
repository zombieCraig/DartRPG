import 'package:flutter/material.dart';

/// Enum representing the different types of screen transitions
enum TransitionType {
  glitch,
  cyberSlide,
  hackerFade,
  digitalWipe,
  terminalBoot,
  circuitReveal,
  none;
  
  /// Get a display name for the transition type
  String get displayName {
    switch (this) {
      case TransitionType.glitch:
        return 'Glitch Effect';
      case TransitionType.cyberSlide:
        return 'Cyber Slide';
      case TransitionType.hackerFade:
        return 'Hacker Fade';
      case TransitionType.digitalWipe:
        return 'Digital Wipe';
      case TransitionType.terminalBoot:
        return 'Terminal Boot';
      case TransitionType.circuitReveal:
        return 'Circuit Reveal';
      case TransitionType.none:
        return 'None (Instant)';
    }
  }
  
  /// Get a description for the transition type
  String get description {
    switch (this) {
      case TransitionType.glitch:
        return 'Random pixel displacements with color channel splitting and scan lines';
      case TransitionType.cyberSlide:
        return 'Slide transition with a digital/cyber aesthetic';
      case TransitionType.hackerFade:
        return 'Fade transition with matrix-style effects';
      case TransitionType.digitalWipe:
        return 'Digital blocks being assembled/disassembled';
      case TransitionType.terminalBoot:
        return 'Old terminal booting up with text appearing';
      case TransitionType.circuitReveal:
        return 'Circuit board pattern that progressively reveals the screen';
      case TransitionType.none:
        return 'No transition effect, instant page change';
    }
  }
  
  /// Get an icon for the transition type
  IconData get icon {
    switch (this) {
      case TransitionType.glitch:
        return Icons.screen_rotation_alt;
      case TransitionType.cyberSlide:
        return Icons.swap_horiz;
      case TransitionType.hackerFade:
        return Icons.blur_on;
      case TransitionType.digitalWipe:
        return Icons.grid_view;
      case TransitionType.terminalBoot:
        return Icons.terminal;
      case TransitionType.circuitReveal:
        return Icons.developer_board;
      case TransitionType.none:
        return Icons.flash_on;
    }
  }
}
