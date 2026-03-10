import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'quest.dart';

/// Enum representing the status of a combat encounter
enum CombatStatus {
  active,
  won,
  lost,
  fled;

  String get displayName {
    switch (this) {
      case CombatStatus.active:
        return 'Active';
      case CombatStatus.won:
        return 'Won';
      case CombatStatus.lost:
        return 'Lost';
      case CombatStatus.fled:
        return 'Fled';
    }
  }

  IconData get icon {
    switch (this) {
      case CombatStatus.active:
        return Icons.sports_martial_arts;
      case CombatStatus.won:
        return Icons.emoji_events;
      case CombatStatus.lost:
        return Icons.dangerous;
      case CombatStatus.fled:
        return Icons.directions_run;
    }
  }

  Color get color {
    switch (this) {
      case CombatStatus.active:
        return Colors.red;
      case CombatStatus.won:
        return Colors.green;
      case CombatStatus.lost:
        return Colors.grey;
      case CombatStatus.fled:
        return Colors.orange;
    }
  }
}

/// Class representing a combat encounter in the game
class Combat {
  final String id;
  String title;
  final String characterId;
  QuestRank rank;
  int _progressTicks;
  CombatStatus status;
  bool isInControl;
  String notes;
  final DateTime createdAt;
  DateTime? endedAt;

  Combat({
    String? id,
    required this.title,
    required this.characterId,
    required this.rank,
    int progressTicks = 0,
    this.status = CombatStatus.active,
    this.isInControl = true,
    this.notes = '',
    DateTime? createdAt,
    this.endedAt,
  })  : id = id ?? const Uuid().v4(),
        _progressTicks = progressTicks,
        createdAt = createdAt ?? DateTime.now();

  /// Get the progress in boxes (0-10)
  int get progress => (_progressTicks / 4).floor();

  /// Get the total number of ticks (0-40)
  int get progressTicks => _progressTicks;

  /// Get the number of ticks in a specific box (0-4)
  int getTicksInBox(int boxIndex) {
    if (boxIndex < progress) {
      return 4;
    } else if (boxIndex == progress && _progressTicks % 4 > 0) {
      return _progressTicks % 4;
    } else {
      return 0;
    }
  }

  /// Get the number of ticks to add based on rank
  int getTicksForRank() {
    switch (rank) {
      case QuestRank.troublesome:
        return 12;
      case QuestRank.dangerous:
        return 8;
      case QuestRank.formidable:
        return 4;
      case QuestRank.extreme:
        return 2;
      case QuestRank.epic:
        return 1;
    }
  }

  /// Add ticks based on rank
  void addTicksForRank() {
    final ticksToAdd = getTicksForRank();
    _progressTicks = (_progressTicks + ticksToAdd).clamp(0, 40);
  }

  /// Remove ticks based on rank
  void removeTicksForRank() {
    final ticksToRemove = getTicksForRank();
    _progressTicks = (_progressTicks - ticksToRemove).clamp(0, 40);
  }

  /// Update progress ticks directly
  void updateProgressTicks(int newTicks) {
    _progressTicks = newTicks.clamp(0, 40);
  }

  /// End the combat with a given status
  void end(CombatStatus endStatus) {
    status = endStatus;
    endedAt = DateTime.now();
  }

  factory Combat.fromJson(Map<String, dynamic> json) {
    return Combat(
      id: json['id'],
      title: json['title'],
      characterId: json['characterId'],
      rank: QuestRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => QuestRank.dangerous,
      ),
      progressTicks: json['progressTicks'] ?? 0,
      status: CombatStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CombatStatus.active,
      ),
      isInControl: json['isInControl'] ?? true,
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'characterId': characterId,
      'rank': rank.name,
      'progressTicks': _progressTicks,
      'status': status.name,
      'isInControl': isInControl,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }
}
