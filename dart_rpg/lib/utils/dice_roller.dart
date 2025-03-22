import 'dart:math';

class DiceRoller {
  static final Random _random = Random();

  // Roll a single die with the given number of sides
  static int rollDie(int sides) {
    return _random.nextInt(sides) + 1;
  }

  // Roll multiple dice with the given number of sides
  static List<int> rollDice(int count, int sides) {
    return List.generate(count, (_) => rollDie(sides));
  }

  // Parse a dice notation string (e.g., "2d10") and roll the dice
  static List<int> rollDiceNotation(String notation) {
    final parts = notation.toLowerCase().split('d');
    if (parts.length != 2) {
      throw ArgumentError('Invalid dice notation: $notation');
    }

    final count = int.tryParse(parts[0]) ?? 1;
    final sides = int.tryParse(parts[1]) ?? 6;

    return rollDice(count, sides);
  }

  // Roll for a move (1d6 + stat + modifier vs 2d10)
  // Now with momentum and modifier support
  static Map<String, dynamic> rollMove({
    int? statValue,
    int momentum = 2,
    int modifier = 0, // New parameter for one-time adjustments
  }) {
    final actionDie = rollDie(6);
    
    // Check if negative momentum cancels the action die
    final bool actionDieCanceled = momentum < 0 && actionDie == -momentum;
    
    // Include the modifier in the action value calculation
    final actionValue = actionDieCanceled 
        ? (statValue ?? 0) + modifier 
        : actionDie + (statValue ?? 0) + modifier;
    
    final challengeDice = rollDice(2, 10);
    
    // Determine outcome
    final strongHit = actionValue > challengeDice[0] && actionValue > challengeDice[1];
    final weakHit = (actionValue > challengeDice[0] && actionValue <= challengeDice[1]) ||
                    (actionValue <= challengeDice[0] && actionValue > challengeDice[1]);
    
    String outcome;
    if (strongHit) {
      outcome = 'strong hit';
    } else if (weakHit) {
      outcome = 'weak hit';
    } else {
      outcome = 'miss';
    }
    
    return {
      'actionDie': actionDie,
      'actionDieCanceled': actionDieCanceled,
      'statValue': statValue,
      'modifier': modifier,
      'actionValue': actionValue,
      'challengeDice': challengeDice,
      'outcome': outcome,
      'momentum': momentum,
      'couldBurnMomentum': momentum > 0 && momentum > actionValue,
    };
  }

  // Roll for a progress move (progress value vs 2d10)
  static Map<String, dynamic> rollProgressMove({required int progressValue}) {
    final challengeDice = rollDice(2, 10);
    
    // Determine outcome
    final strongHit = progressValue > challengeDice[0] && progressValue > challengeDice[1];
    final weakHit = (progressValue > challengeDice[0] && progressValue <= challengeDice[1]) ||
                    (progressValue <= challengeDice[0] && progressValue > challengeDice[1]);
    
    String outcome;
    if (strongHit) {
      outcome = 'strong hit';
    } else if (weakHit) {
      outcome = 'weak hit';
    } else {
      outcome = 'miss';
    }
    
    return {
      'progressValue': progressValue,
      'challengeDice': challengeDice,
      'outcome': outcome,
    };
  }

  // Roll on an oracle table
  static Map<String, dynamic> rollOracle(String diceFormat) {
    final dice = rollDiceNotation(diceFormat);
    final total = dice.reduce((sum, die) => sum + die);
    
    return {
      'dice': dice,
      'total': total,
    };
  }
}
