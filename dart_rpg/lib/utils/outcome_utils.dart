import 'package:flutter/material.dart';

/// Returns the color associated with a move outcome.
Color getOutcomeColor(String outcome) {
  final lower = outcome.toLowerCase();
  if (lower.contains('strong hit with a match')) {
    return Colors.green[700]!;
  } else if (lower.contains('strong hit')) {
    return Colors.green;
  } else if (lower.contains('weak hit')) {
    return Colors.orange;
  } else if (lower.contains('miss with a match')) {
    return Colors.red[700]!;
  } else if (lower.contains('miss')) {
    return Colors.red;
  } else {
    return Colors.grey;
  }
}

/// Returns the icon for a given roll type and outcome.
IconData getRollTypeIcon(String rollType, String outcome) {
  if (rollType == 'no_roll') {
    return Icons.check_circle_outline;
  }

  if (rollType == 'progress_roll') {
    return Icons.trending_up;
  }

  if (rollType == 'oracle_roll') {
    return Icons.casino;
  }

  // For action rolls, use outcome-based icons
  final lower = outcome.toLowerCase();
  if (lower.contains('strong hit with a match')) {
    return Icons.star;
  } else if (lower.contains('strong hit')) {
    return Icons.check_circle;
  } else if (lower.contains('weak hit')) {
    return Icons.check_circle_outline;
  } else if (lower.contains('miss with a match')) {
    return Icons.warning;
  } else if (lower.contains('miss')) {
    return Icons.cancel;
  } else {
    return Icons.sports_martial_arts;
  }
}
