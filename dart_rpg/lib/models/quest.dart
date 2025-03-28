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
  int progress;
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
    this.progress = 0,
    this.status = QuestStatus.ongoing,
    this.notes = '',
    DateTime? createdAt,
    this.completedAt,
    this.forsakenAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Create a quest from JSON
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      characterId: json['characterId'],
      rank: QuestRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => QuestRank.troublesome,
      ),
      progress: json['progress'] ?? 0,
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
      'progress': progress,
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
  
  /// Update the progress of the quest
  void updateProgress(int newProgress) {
    // Ensure progress is between 0 and 10
    progress = newProgress.clamp(0, 10);
  }
  
  /// Clone the quest
  Quest clone() {
    return Quest(
      id: id,
      title: title,
      characterId: characterId,
      rank: rank,
      progress: progress,
      status: status,
      notes: notes,
      createdAt: createdAt,
      completedAt: completedAt,
      forsakenAt: forsakenAt,
    );
  }
}
