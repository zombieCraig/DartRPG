import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'quest.dart';

/// Enum representing the status of a connection
enum ConnectionStatus {
  active,
  bonded,
  lost;

  String get displayName {
    switch (this) {
      case ConnectionStatus.active:
        return 'Active';
      case ConnectionStatus.bonded:
        return 'Bonded';
      case ConnectionStatus.lost:
        return 'Lost';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.active:
        return Icons.handshake;
      case ConnectionStatus.bonded:
        return Icons.favorite;
      case ConnectionStatus.lost:
        return Icons.heart_broken;
    }
  }

  Color get color {
    switch (this) {
      case ConnectionStatus.active:
        return Colors.blue;
      case ConnectionStatus.bonded:
        return Colors.green;
      case ConnectionStatus.lost:
        return Colors.red;
    }
  }
}

/// Class representing a connection (NPC relationship) in the game.
/// Uses the same progress track mechanic as Quest.
class Connection {
  final String id;
  String name;
  final String characterId;
  String role;
  QuestRank rank;
  int _progressTicks; // 0-40, same as Quest
  ConnectionStatus status;
  String notes;
  final DateTime createdAt;
  DateTime? bondedAt;
  DateTime? lostAt;

  Connection({
    String? id,
    required this.name,
    required this.characterId,
    required this.role,
    required this.rank,
    int progressTicks = 0,
    this.status = ConnectionStatus.active,
    this.notes = '',
    DateTime? createdAt,
    this.bondedAt,
    this.lostAt,
  })  : id = id ?? const Uuid().v4(),
        _progressTicks = progressTicks,
        createdAt = createdAt ?? DateTime.now();

  /// Get progress in boxes (0-10)
  int get progress => (_progressTicks / 4).floor();

  /// Get total ticks (0-40)
  int get progressTicks => _progressTicks;

  /// Get ticks in a specific box (0-4)
  int getTicksInBox(int boxIndex) {
    if (boxIndex < progress) {
      return 4;
    } else if (boxIndex == progress && _progressTicks % 4 > 0) {
      return _progressTicks % 4;
    } else {
      return 0;
    }
  }

  /// Check if a box is full
  bool isBoxFull(int boxIndex) => getTicksInBox(boxIndex) >= 4;

  /// Get ticks to add based on rank (same as Quest)
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

  void updateProgress(int newProgress) {
    _progressTicks = (newProgress.clamp(0, 10) * 4);
  }

  void updateProgressTicks(int newTicks) {
    _progressTicks = newTicks.clamp(0, 40);
  }

  void addTick() {
    if (_progressTicks < 40) _progressTicks++;
  }

  void removeTick() {
    if (_progressTicks > 0) _progressTicks--;
  }

  void addTicksForRank() {
    _progressTicks = (_progressTicks + getTicksForRank()).clamp(0, 40);
  }

  void removeTicksForRank() {
    _progressTicks = (_progressTicks - getTicksForRank()).clamp(0, 40);
  }

  void bond() {
    status = ConnectionStatus.bonded;
    bondedAt = DateTime.now();
  }

  void lose() {
    status = ConnectionStatus.lost;
    lostAt = DateTime.now();
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'],
      name: json['name'],
      characterId: json['characterId'],
      role: json['role'] ?? '',
      rank: QuestRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => QuestRank.troublesome,
      ),
      progressTicks: json['progressTicks'] ?? 0,
      status: ConnectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ConnectionStatus.active,
      ),
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      bondedAt: json['bondedAt'] != null
          ? DateTime.parse(json['bondedAt'])
          : null,
      lostAt: json['lostAt'] != null
          ? DateTime.parse(json['lostAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'characterId': characterId,
      'role': role,
      'rank': rank.name,
      'progressTicks': _progressTicks,
      'progress': progress,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'bondedAt': bondedAt?.toIso8601String(),
      'lostAt': lostAt?.toIso8601String(),
    };
  }

  Connection clone() {
    return Connection(
      id: id,
      name: name,
      characterId: characterId,
      role: role,
      rank: rank,
      progressTicks: _progressTicks,
      status: status,
      notes: notes,
      createdAt: createdAt,
      bondedAt: bondedAt,
      lostAt: lostAt,
    );
  }
}
