import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'location.dart';
import 'quest.dart';

/// Enum representing the status of a network route
enum RouteStatus {
  active,
  completed,
  burned;

  String get displayName {
    switch (this) {
      case RouteStatus.active:
        return 'Active';
      case RouteStatus.completed:
        return 'Completed';
      case RouteStatus.burned:
        return 'Burned';
    }
  }

  IconData get icon {
    switch (this) {
      case RouteStatus.active:
        return Icons.route;
      case RouteStatus.completed:
        return Icons.check_circle;
      case RouteStatus.burned:
        return Icons.local_fire_department;
    }
  }

  Color get color {
    switch (this) {
      case RouteStatus.active:
        return Colors.blue;
      case RouteStatus.completed:
        return Colors.green;
      case RouteStatus.burned:
        return Colors.red;
    }
  }
}

/// Class representing a network route between segments.
/// Uses the same progress track mechanic as Quest/Connection.
class NetworkRoute {
  final String id;
  String name;
  final String characterId;
  LocationSegment origin;
  LocationSegment destination;
  QuestRank rank;
  int _progressTicks; // 0-40, same as Quest
  RouteStatus status;
  String notes;
  final DateTime createdAt;
  DateTime? completedAt;
  DateTime? burnedAt;

  NetworkRoute({
    String? id,
    required this.name,
    required this.characterId,
    required this.origin,
    required this.destination,
    required this.rank,
    int progressTicks = 0,
    this.status = RouteStatus.active,
    this.notes = '',
    DateTime? createdAt,
    this.completedAt,
    this.burnedAt,
  })  : id = id ?? const Uuid().v4(),
        _progressTicks = progressTicks,
        createdAt = createdAt ?? DateTime.now();

  /// Label showing origin → destination
  String get routeLabel => '${origin.displayName} → ${destination.displayName}';

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

  void complete() {
    status = RouteStatus.completed;
    completedAt = DateTime.now();
  }

  void burn() {
    status = RouteStatus.burned;
    burnedAt = DateTime.now();
  }

  factory NetworkRoute.fromJson(Map<String, dynamic> json) {
    return NetworkRoute(
      id: json['id'],
      name: json['name'],
      characterId: json['characterId'],
      origin: LocationSegmentExtension.fromString(json['origin'] ?? 'core'),
      destination: LocationSegmentExtension.fromString(json['destination'] ?? 'core'),
      rank: QuestRank.values.firstWhere(
        (r) => r.name == json['rank'],
        orElse: () => QuestRank.troublesome,
      ),
      progressTicks: json['progressTicks'] ?? 0,
      status: RouteStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RouteStatus.active,
      ),
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      burnedAt: json['burnedAt'] != null
          ? DateTime.parse(json['burnedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'characterId': characterId,
      'origin': origin.toString().split('.').last,
      'destination': destination.toString().split('.').last,
      'rank': rank.name,
      'progressTicks': _progressTicks,
      'progress': progress,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'burnedAt': burnedAt?.toIso8601String(),
    };
  }

  NetworkRoute clone() {
    return NetworkRoute(
      id: id,
      name: name,
      characterId: characterId,
      origin: origin,
      destination: destination,
      rank: rank,
      progressTicks: _progressTicks,
      status: status,
      notes: notes,
      createdAt: createdAt,
      completedAt: completedAt,
      burnedAt: burnedAt,
    );
  }
}
