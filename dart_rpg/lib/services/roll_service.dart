import 'package:flutter/material.dart';
import '../models/move.dart';
import '../models/journal_entry.dart';
import '../models/game.dart';
import '../utils/dice_roller.dart';

/// Service for handling dice rolls and move outcomes.
class RollService {
  /// Performs an action roll with a specific stat and modifier.
  static Map<String, dynamic> performActionRoll({
    required Move move,
    required String stat,
    required int statValue,
    int modifier = 0,
    int momentum = 0,
    Game? game,
  }) {
    // Roll the dice
    final rollResult = DiceRoller.rollMove(
      statValue: statValue,
      momentum: momentum,
      modifier: modifier,
    );
    
    // Create a MoveRoll object
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      rollType: 'action_roll',
      stat: stat,
      statValue: statValue,
      modifier: modifier,
      actionDie: rollResult['actionDie'] as int,
      challengeDice: rollResult['challengeDice'] as List<int>,
      outcome: rollResult['outcome'] as String,
      isMatch: rollResult['isMatch'] as bool? ?? false,
      moveData: {'moveId': move.id},
    );
    
    // Check for Sentient AI trigger
    bool sentientAiTriggered = false;
    if (game != null && 
        game.sentientAiEnabled && 
        move.sentientAi && 
        (rollResult['challengeDice'] as List<int>).any((die) => die == 10)) {
      sentientAiTriggered = true;
    }
    
    return {
      'rollResult': rollResult,
      'moveRoll': moveRoll,
      'sentientAiTriggered': sentientAiTriggered,
    };
  }
  
  /// Performs a progress roll with a specific progress value.
  static Map<String, dynamic> performProgressRoll({
    required Move move,
    required int progressValue,
    Game? game,
  }) {
    // Roll the dice
    final rollResult = DiceRoller.rollProgressMove(progressValue: progressValue);
    
    // Create a MoveRoll object
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      rollType: 'progress_roll',
      progressValue: progressValue,
      challengeDice: rollResult['challengeDice'] as List<int>,
      outcome: rollResult['outcome'] as String,
      actionDie: 0, // Default value for progress rolls
      isMatch: rollResult['isMatch'] as bool? ?? false,
      moveData: {'moveId': move.id},
    );
    
    // Check for Sentient AI trigger
    bool sentientAiTriggered = false;
    if (game != null && 
        game.sentientAiEnabled && 
        move.sentientAi && 
        (rollResult['challengeDice'] as List<int>).any((die) => die == 10)) {
      sentientAiTriggered = true;
    }
    
    return {
      'rollResult': rollResult,
      'moveRoll': moveRoll,
      'sentientAiTriggered': sentientAiTriggered,
    };
  }
  
  /// Performs a move that doesn't require a roll.
  static MoveRoll performNoRollMove({
    required Move move,
  }) {
    // Create a MoveRoll object for a move that doesn't require a roll
    return MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      rollType: 'no_roll',
      outcome: 'performed',
      actionDie: 0, // Default value for no-roll moves
      challengeDice: [], // Empty for no-roll moves
      moveData: {'moveId': move.id},
    );
  }
  
  /// Returns a color based on the outcome of a move roll.
  static Color getOutcomeColor(String outcome) {
    if (outcome.toLowerCase().contains('strong hit with a match')) {
      return Colors.green[700]!;
    } else if (outcome.toLowerCase().contains('strong hit')) {
      return Colors.green;
    } else if (outcome.toLowerCase().contains('weak hit')) {
      return Colors.orange;
    } else if (outcome.toLowerCase().contains('miss with a match')) {
      return Colors.red[700]!;
    } else if (outcome.toLowerCase().contains('miss')) {
      return Colors.red;
    } else if (outcome.toLowerCase() == 'performed') {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
  
  /// Returns a color for match indicators based on the outcome.
  static Color getMatchColor(String outcome) {
    if (outcome.contains('strong hit')) {
      return Colors.green[700]!;
    } else if (outcome.contains('miss')) {
      return Colors.red[700]!;
    }
    return Colors.grey;
  }
  
  /// Returns an icon for match indicators based on the outcome.
  static IconData getMatchIcon(String outcome) {
    if (outcome.contains('strong hit')) {
      return Icons.star; // Star icon for positive matches
    } else if (outcome.contains('miss')) {
      return Icons.warning; // Warning icon for negative matches
    }
    return Icons.casino; // Default dice icon
  }
  
  /// Returns an icon based on the roll type.
  static IconData getRollTypeIcon(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return Icons.sports_martial_arts; // Person kicking icon
      case 'progress_roll':
        return Icons.trending_up;
      case 'no_roll':
        return Icons.check_circle_outline;
      default:
        return Icons.sports_martial_arts;
    }
  }
  
  /// Returns a color based on the roll type.
  static Color getRollTypeColor(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return Colors.blue;
      case 'progress_roll':
        return Colors.green;
      case 'no_roll':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
  
  /// Returns a tooltip based on the roll type.
  static String getRollTypeTooltip(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return 'Action Roll';
      case 'progress_roll':
        return 'Progress Roll';
      case 'no_roll':
        return 'No Roll Required';
      default:
        return 'Move';
    }
  }
}
