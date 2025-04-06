import 'move_oracle.dart';
import '../utils/oracle_markdown_parser.dart';
import '../utils/logging_service.dart';

class MoveOutcome {
  final String type; // "strong hit", "weak hit", or "miss"
  final String description;

  MoveOutcome({
    required this.type,
    required this.description,
  });

  factory MoveOutcome.fromJson(Map<String, dynamic> json) {
    return MoveOutcome(
      type: json['type'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
    };
  }
}

class Move {
  final String id;
  final String name;
  String? category;
  String? moveCategory; // Added for grouping by move_category
  final String? description;
  final String? trigger;
  final List<MoveOutcome> outcomes;
  final String? stat; // The stat used for this move (Edge, Heart, Iron, Shadow, Wits)
  final bool isProgressMove;
  
  // New properties for enhanced move functionality
  final String rollType; // "action_roll", "progress_roll", or "no_roll"
  final List<Map<String, dynamic>> triggerConditions; // Conditions from the trigger
  final List<Map<String, dynamic>> rollOptions; // Options for rolling
  final bool sentientAi; // Whether this move can trigger the Sentient AI
  
  // Embedded oracles
  Map<String, MoveOracle>? _oracles;
  final Map<String, dynamic>? _oraclesData; // Raw oracles data from JSON
  
  // Outcome-specific oracle references
  final Map<String, List<String>> _outcomeOracleRefs = {};

  Move({
    required this.id,
    required this.name,
    this.category,
    this.moveCategory,
    this.description,
    this.trigger,
    List<MoveOutcome>? outcomes,
    this.stat,
    this.isProgressMove = false,
    String? rollType,
    List<Map<String, dynamic>>? triggerConditions,
    List<Map<String, dynamic>>? rollOptions,
    Map<String, dynamic>? oraclesData,
    this.sentientAi = false,
  }) : 
    outcomes = outcomes ?? [],
    rollType = rollType ?? (isProgressMove ? 'progress_roll' : (stat != null ? 'action_roll' : 'no_roll')),
    triggerConditions = triggerConditions ?? [],
    rollOptions = rollOptions ?? [],
    _oraclesData = oraclesData;

  factory Move.fromJson(Map<String, dynamic> json) {
    List<MoveOutcome> outcomes = [];
    
    if (json['outcomes'] != null) {
      outcomes = (json['outcomes'] as List)
          .map((o) => MoveOutcome.fromJson(o))
          .toList();
    }

    return Move(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      moveCategory: json['moveCategory'],
      description: json['description'],
      trigger: json['trigger'],
      outcomes: outcomes,
      stat: json['stat'],
      isProgressMove: json['isProgressMove'] ?? false,
      rollType: json['rollType'],
      triggerConditions: json['triggerConditions'] != null 
          ? List<Map<String, dynamic>>.from(json['triggerConditions'])
          : null,
      rollOptions: json['rollOptions'] != null 
          ? List<Map<String, dynamic>>.from(json['rollOptions'])
          : null,
      oraclesData: json['oracles'],
      sentientAi: json['sentient_ai'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'moveCategory': moveCategory,
      'description': description,
      'trigger': trigger,
      'outcomes': outcomes.map((o) => o.toJson()).toList(),
      'stat': stat,
      'isProgressMove': isProgressMove,
      'rollType': rollType,
      'triggerConditions': triggerConditions,
      'rollOptions': rollOptions,
      'oracles': _oraclesData,
      'sentient_ai': sentientAi,
    };
  }

  // Parse a move from the Datasworn JSON format
  factory Move.fromDatasworn(Map<String, dynamic> json, String moveId) {
    final loggingService = LoggingService();
    final String name = json['name'] ?? 'Unknown Move';
    final String? description = json['text'];
    final String? trigger = json['trigger']?['text'];
    final String? moveCategory = json['move_category'];
    
    List<MoveOutcome> outcomes = [];
    
    // Map to store outcome oracle references
    final Map<String, List<String>> outcomeOracleRefs = {};
    
    if (json['outcomes'] != null) {
      if (json['outcomes']['strong_hit'] != null) {
        final outcomeText = json['outcomes']['strong_hit']['text'] ?? '';
        outcomes.add(MoveOutcome(
          type: 'strong hit',
          description: outcomeText,
        ));
        
        // Check for oracle references in the outcome text
        if (OracleMarkdownParser.containsOracleReferences(outcomeText)) {
          outcomeOracleRefs['strong hit'] = OracleMarkdownParser.parseOracleReferences(outcomeText);
          loggingService.debug(
            'Found oracle references in strong hit outcome: ${outcomeOracleRefs['strong hit']}',
            tag: 'Move.fromDatasworn',
          );
        }
      }
      
      if (json['outcomes']['weak_hit'] != null) {
        final outcomeText = json['outcomes']['weak_hit']['text'] ?? '';
        outcomes.add(MoveOutcome(
          type: 'weak hit',
          description: outcomeText,
        ));
        
        // Check for oracle references in the outcome text
        if (OracleMarkdownParser.containsOracleReferences(outcomeText)) {
          outcomeOracleRefs['weak hit'] = OracleMarkdownParser.parseOracleReferences(outcomeText);
          loggingService.debug(
            'Found oracle references in weak hit outcome: ${outcomeOracleRefs['weak hit']}',
            tag: 'Move.fromDatasworn',
          );
        }
      }
      
      if (json['outcomes']['miss'] != null) {
        final outcomeText = json['outcomes']['miss']['text'] ?? '';
        outcomes.add(MoveOutcome(
          type: 'miss',
          description: outcomeText,
        ));
        
        // Check for oracle references in the outcome text
        if (OracleMarkdownParser.containsOracleReferences(outcomeText)) {
          outcomeOracleRefs['miss'] = OracleMarkdownParser.parseOracleReferences(outcomeText);
          loggingService.debug(
            'Found oracle references in miss outcome: ${outcomeOracleRefs['miss']}',
            tag: 'Move.fromDatasworn',
          );
        }
      }
    }

    // Try to determine the stat from the trigger text
    String? stat;
    if (trigger != null) {
      if (trigger.contains('+edge')) {
        stat = 'Edge';
      } else if (trigger.contains('+heart')) {
        stat = 'Heart';
      } else if (trigger.contains('+iron')) {
        stat = 'Iron';
      } else if (trigger.contains('+shadow')) { 
        stat = 'Shadow';
      } else if (trigger.contains('+wits')) {
        stat = 'Wits';
      }
    }
    
    // Determine roll type
    String rollType;
    // First check if roll_type is explicitly defined in the JSON
    if (json['roll_type'] != null) {
      rollType = json['roll_type'];
    } 
    // Otherwise, try to infer it from the move name and ID
    else if (moveId.contains('progress') ||
        (name.toLowerCase().contains('progress') &&
         !name.toLowerCase().contains('mark progress'))) {
      rollType = 'progress_roll';
    } else if (stat != null) {
      rollType = 'action_roll';
    } else {
      rollType = 'no_roll';
    }
    
    // Extract trigger conditions
    List<Map<String, dynamic>> triggerConditions = [];
    if (json['trigger']?['conditions'] != null) {
      for (var condition in json['trigger']['conditions']) {
        triggerConditions.add(Map<String, dynamic>.from(condition));
      }
    }
    
    // Extract roll options
    List<Map<String, dynamic>> rollOptions = [];
    if (json['roll_options'] != null) {
      for (var option in json['roll_options']) {
        rollOptions.add(Map<String, dynamic>.from(option));
      }
    }

    // Create the move
    final move = Move(
      id: moveId,
      name: name,
      description: description,
      moveCategory: moveCategory,
      trigger: trigger,
      outcomes: outcomes,
      stat: stat,
      isProgressMove: rollType == 'progress_roll',
      rollType: rollType,
      triggerConditions: triggerConditions,
      rollOptions: rollOptions,
      oraclesData: json['oracles'],
      sentientAi: json['sentient_ai'] ?? false,
    );
    
    // Add outcome oracle references to the move
    outcomeOracleRefs.forEach((outcome, refs) {
      move._outcomeOracleRefs[outcome] = refs;
    });
    
    return move;
  }
  
  /// Gets the embedded oracles for this move, if any.
  Map<String, MoveOracle> get oracles {
    if (_oracles != null) {
      return _oracles!;
    }
    
    _oracles = {};
    if (_oraclesData != null) {
      _oraclesData.forEach((key, value) {
        _oracles![key] = MoveOracle.fromJson(key, value);
      });
    }
    
    return _oracles!;
  }
  
  /// Checks if this move has embedded oracles.
  bool get hasEmbeddedOracles => oracles.isNotEmpty;
  
  /// Gets the outcome oracle references for this move.
  Map<String, List<String>> get outcomeOracleRefs => _outcomeOracleRefs;
  
  /// Checks if an outcome has associated oracles.
  bool hasOraclesForOutcome(String outcome) {
    return _outcomeOracleRefs.containsKey(outcome) && 
           _outcomeOracleRefs[outcome]!.isNotEmpty;
  }
  
  /// Gets oracles for a specific outcome.
  /// 
  /// This method returns a list of MoveOracle objects for the specified outcome.
  /// If the outcome has no associated oracles, an empty list is returned.
  List<MoveOracle> getOraclesForOutcome(String outcome) {
    if (!hasOraclesForOutcome(outcome)) return [];
    
    final List<MoveOracle> outcomeOracles = [];
    for (final ref in _outcomeOracleRefs[outcome]!) {
      // The ref might be a direct key or a path that needs to be resolved
      // For now, we'll just check if it's a direct key in the oracles map
      if (oracles.containsKey(ref)) {
        outcomeOracles.add(oracles[ref]!);
      }
    }
    
    return outcomeOracles;
  }
  
  /// Gets the appropriate oracle for a stat.
  /// 
  /// This method is specifically for the "Explore the System" move, which
  /// has oracles for edge, shadow, and wits.
  MoveOracle? getOracleForStat(String stat) {
    // Convert stat to lowercase for case-insensitive comparison
    final lowerStat = stat.toLowerCase();
    
    // Try to find an oracle with a key that matches the stat
    for (final entry in oracles.entries) {
      if (entry.key.toLowerCase() == lowerStat) {
        return entry.value;
      }
    }
    
    return null;
  }
  
  // Enhanced method to get available stats and condition meters
  List<Map<String, dynamic>> getAvailableOptions() {
    List<Map<String, dynamic>> availableOptions = [];
    
    // First check if we have player_choice or other method conditions
    for (var condition in triggerConditions) {
      if (condition['method'] == 'player_choice') {
        // For player_choice, add all options
        if (condition['roll_options'] != null) {
          for (var option in condition['roll_options']) {
            if ((option['using'] == 'stat' && option['stat'] != null) ||
                (option['using'] == 'condition_meter' && option['condition_meter'] != null)) {
              availableOptions.add(option);
            }
          }
        }
      } else if (condition['method'] == 'highest' || condition['method'] == 'lowest') {
        // For highest/lowest, we'll need to determine the value at runtime
        // Just add all options for now, we'll filter in the UI
        if (condition['roll_options'] != null) {
          for (var option in condition['roll_options']) {
            if ((option['using'] == 'stat' && option['stat'] != null) ||
                (option['using'] == 'condition_meter' && option['condition_meter'] != null)) {
              availableOptions.add({...option, 'method': condition['method']});
            }
          }
        }
      }
      // Add other methods as needed
    }
    
    // If no options found in conditions, check roll options
    if (availableOptions.isEmpty) {
      for (var option in rollOptions) {
        if ((option['using'] == 'stat' && option['stat'] != null) ||
            (option['using'] == 'condition_meter' && option['condition_meter'] != null)) {
          availableOptions.add(option);
        }
      }
    }
    
    // If still empty and we have a stat property, use that
    if (availableOptions.isEmpty && stat != null) {
      availableOptions.add({
        'using': 'stat',
        'stat': stat!
      });
    }
    
    return availableOptions;
  }

  // Helper method to get just the stat names (for backward compatibility)
  List<String> getAvailableStats() {
    final options = getAvailableOptions();
    final stats = <String>[];
    
    for (var option in options) {
      if (option['using'] == 'stat' && option['stat'] != null) {
        stats.add(option['stat']);
      }
    }
    
    // If no stats found, return default stats
    if (stats.isEmpty) {
      return ['Edge', 'Heart', 'Iron', 'Shadow', 'Wits'];
    }
    
    return stats;
  }
  
  // Helper method to check if this move has player choice
  bool hasPlayerChoice() {
    for (var condition in triggerConditions) {
      if (condition['method'] == 'player_choice') {
        return true;
      }
    }
    return false;
  }
  
  // Helper method to check if this move has the "highest" method
  bool hasHighestMethod() {
    for (var condition in triggerConditions) {
      if (condition['method'] == 'highest') {
        return true;
      }
    }
    return false;
  }
  
  // Helper method to check if this move has the "lowest" method
  bool hasLowestMethod() {
    for (var condition in triggerConditions) {
      if (condition['method'] == 'lowest') {
        return true;
      }
    }
    return false;
  }
  
  // Helper method to check if this move has any special method (highest or lowest)
  bool hasSpecialMethod() {
    return hasHighestMethod() || hasLowestMethod();
  }
  
  // Helper method to get the special method if any
  String? getSpecialMethod() {
    for (var condition in triggerConditions) {
      if (condition['method'] == 'highest' || condition['method'] == 'lowest') {
        return condition['method'];
      }
    }
    return null;
  }
}
