import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Enum representing the different ranks a quest can have
enum QuestRank {
  troublesome,
  dangerous,
  formidable,
  extreme,
  epic;
  
  /// Get a display name for the rank
  String get displayName {
    switch (this) {
      case QuestRank.troublesome:
        return 'Troublesome';
      case QuestRank.dangerous:
        return 'Dangerous';
      case QuestRank.formidable:
        return 'Formidable';
      case QuestRank.extreme:
        return 'Extreme';
      case QuestRank.epic:
        return 'Epic';
    }
  }
  
  /// Get an icon for the rank
  IconData get icon {
    switch (this) {
      case QuestRank.troublesome:
        return Icons.assignment;
      case QuestRank.dangerous:
        return Icons.warning;
      case QuestRank.formidable:
        return Icons.shield;
      case QuestRank.extreme:
        return Icons.whatshot;
      case QuestRank.epic:
        return Icons.star;
    }
  }
  
  /// Get a color for the rank
  Color get color {
    switch (this) {
      case QuestRank.troublesome:
        return Colors.green;
      case QuestRank.dangerous:
        return Colors.blue;
      case QuestRank.formidable:
        return Colors.orange;
      case QuestRank.extreme:
        return Colors.red;
      case QuestRank.epic:
        return Colors.purple;
    }
  }
}

/// Enum representing the status of a quest
enum QuestStatus {
  ongoing,
  completed,
  forsaken;
  
  /// Get a display name for the status
  String get displayName {
    switch (this) {
      case QuestStatus.ongoing:
        return 'Ongoing';
      case QuestStatus.completed:
        return 'Completed';
      case QuestStatus.forsaken:
        return 'Forsaken';
    }
  }
  
  /// Get an icon for the status
  IconData get icon {
    switch (this) {
      case QuestStatus.ongoing:
        return Icons.pending_actions;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.forsaken:
        return Icons.cancel;
    }
  }
  
  /// Get a color for the status
  Color get color {
    switch (this) {
      case QuestStatus.ongoing:
        return Colors.blue;
      case QuestStatus.completed:
        return Colors.green;
      case QuestStatus.forsaken:
        return Colors.orange;
    }
  }
}

/// Class representing a quest in the game
class Quest {
  final String id;
  String title;
  final String characterId;
  QuestRank rank;
  int _progressTicks; // Internal storage as ticks (0-40)
  QuestStatus status;
  String notes;
  final DateTime createdAt;
  DateTime? completedAt;
  DateTime? forsakenAt;
  
  /// Create a new quest
  Quest({
    String? id,
    required this.title,
    required this.characterId,
    required this.rank,
    int progress = 0,
    int? progressTicks,
    this.status = QuestStatus.ongoing,
    this.notes = '',
    DateTime? createdAt,
    this.completedAt,
    this.forsakenAt,
  }) : 
    id = id ?? const Uuid().v4(),
    _progressTicks = progressTicks ?? (progress * 4), // Convert from boxes to ticks if needed
    createdAt = createdAt ?? DateTime.now();
    
  /// Get the progress in boxes (0-10)
  int get progress => (_progressTicks / 4).floor();
  
  /// Get the total number of ticks (0-40)
  int get progressTicks => _progressTicks;
  
  /// Get the number of ticks in a specific box (0-4)
  int getTicksInBox(int boxIndex) {
    if (boxIndex < progress) {
      return 4; // Full box
    } else if (boxIndex == progress && _progressTicks % 4 > 0) {
      return _progressTicks % 4; // Partially filled box
    } else {
      return 0; // Empty box
    }
  }
  
  /// Check if a box is full (has 4 ticks)
  bool isBoxFull(int boxIndex) => getTicksInBox(boxIndex) >= 4;
  
  /// Get the number of ticks to add based on quest rank
  int getTicksForRank() {
    switch (rank) {
      case QuestRank.troublesome:
        return 12; // 3 boxes
      case QuestRank.dangerous:
        return 8;  // 2 boxes
      case QuestRank.formidable:
        return 4;  // 1 box
      case QuestRank.extreme:
        return 2;  // 2 ticks
      case QuestRank.epic:
        return 1;  // 1 tick
    }
  }
  
  /// Create a quest from JSON
  factory Quest.fromJson(Map<String, dynamic> json) {
    // Handle both new format (with progressTicks) and old format (with progress)
    final progressTicks = json['progressTicks'];
    final progress = json['progress'];
    
    return Quest(
      id: json['id'],
      title: json['title'],
      characterId: json['characterId'],
      rank: QuestRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => QuestRank.troublesome,
      ),
      progressTicks: progressTicks ?? (progress != null ? progress * 4 : 0),
      status: QuestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QuestStatus.ongoing,
      ),
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      forsakenAt: json['forsakenAt'] != null 
          ? DateTime.parse(json['forsakenAt']) 
          : null,
    );
  }
  
  /// Convert the quest to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'characterId': characterId,
      'rank': rank.name,
      'progressTicks': _progressTicks,
      'progress': progress, // Include for backward compatibility
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'forsakenAt': forsakenAt?.toIso8601String(),
    };
  }
  
  /// Complete the quest
  void complete() {
    status = QuestStatus.completed;
    completedAt = DateTime.now();
  }
  
  /// Forsake the quest
  void forsake() {
    status = QuestStatus.forsaken;
    forsakenAt = DateTime.now();
  }
  
  /// Update the progress of the quest in boxes (0-10)
  void updateProgress(int newProgress) {
    // Ensure progress is between 0 and 10, then convert to ticks
    _progressTicks = (newProgress.clamp(0, 10) * 4);
  }
  
  /// Update the progress of the quest in ticks (0-40)
  void updateProgressTicks(int newTicks) {
    // Ensure ticks are between 0 and 40
    _progressTicks = newTicks.clamp(0, 40);
  }
  
  /// Add a single tick to the progress
  void addTick() {
    if (_progressTicks < 40) {
      _progressTicks++;
    }
  }
  
  /// Remove a single tick from the progress
  void removeTick() {
    if (_progressTicks > 0) {
      _progressTicks--;
    }
  }
  
  /// Add ticks based on the quest rank
  void addTicksForRank() {
    final ticksToAdd = getTicksForRank();
    _progressTicks = (_progressTicks + ticksToAdd).clamp(0, 40);
  }
  
  /// Remove ticks based on the quest rank
  void removeTicksForRank() {
    final ticksToRemove = getTicksForRank();
    _progressTicks = (_progressTicks - ticksToRemove).clamp(0, 40);
  }
  
  /// Clone the quest
  Quest clone() {
    return Quest(
      id: id,
      title: title,
      characterId: characterId,
      rank: rank,
      progressTicks: _progressTicks,
      status: status,
      notes: notes,
      createdAt: createdAt,
      completedAt: completedAt,
      forsakenAt: forsakenAt,
    );
  }
}
