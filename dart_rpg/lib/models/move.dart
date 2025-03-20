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
  final String? description;
  final String? trigger;
  final List<MoveOutcome> outcomes;
  final String? stat; // The stat used for this move (Edge, Heart, Iron, Shadow, Wits)
  final bool isProgressMove;

  Move({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.trigger,
    List<MoveOutcome>? outcomes,
    this.stat,
    this.isProgressMove = false,
  }) : outcomes = outcomes ?? [];

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
      description: json['description'],
      trigger: json['trigger'],
      outcomes: outcomes,
      stat: json['stat'],
      isProgressMove: json['isProgressMove'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'trigger': trigger,
      'outcomes': outcomes.map((o) => o.toJson()).toList(),
      'stat': stat,
      'isProgressMove': isProgressMove,
    };
  }

  // Parse a move from the Datasworn JSON format
  factory Move.fromDatasworn(Map<String, dynamic> json, String moveId) {
    final String name = json['name'] ?? 'Unknown Move';
    final String? description = json['text'];
    final String? trigger = json['trigger']?['text'];
    
    List<MoveOutcome> outcomes = [];
    
    if (json['outcomes'] != null) {
      if (json['outcomes']['strong_hit'] != null) {
        outcomes.add(MoveOutcome(
          type: 'strong hit',
          description: json['outcomes']['strong_hit']['text'] ?? '',
        ));
      }
      
      if (json['outcomes']['weak_hit'] != null) {
        outcomes.add(MoveOutcome(
          type: 'weak hit',
          description: json['outcomes']['weak_hit']['text'] ?? '',
        ));
      }
      
      if (json['outcomes']['miss'] != null) {
        outcomes.add(MoveOutcome(
          type: 'miss',
          description: json['outcomes']['miss']['text'] ?? '',
        ));
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

    return Move(
      id: moveId,
      name: name,
      description: description,
      trigger: trigger,
      outcomes: outcomes,
      stat: stat,
      isProgressMove: moveId.contains('progress') || 
                     (name.toLowerCase().contains('progress') && 
                      !name.toLowerCase().contains('mark progress')),
    );
  }
}
