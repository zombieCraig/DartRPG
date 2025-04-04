import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Enum representing the different types of clocks
enum ClockType {
  campaign,
  tension,
  trace;
  
  /// Get a display name for the clock type
  String get displayName {
    switch (this) {
      case ClockType.campaign:
        return 'Campaign';
      case ClockType.tension:
        return 'Tension';
      case ClockType.trace:
        return 'Trace';
    }
  }
  
  /// Get an icon for the clock type
  IconData get icon {
    switch (this) {
      case ClockType.campaign:
        return Icons.public;
      case ClockType.tension:
        return Icons.warning;
      case ClockType.trace:
        return Icons.track_changes;
    }
  }
  
  /// Get a color for the clock type
  Color get color {
    switch (this) {
      case ClockType.campaign:
        return Colors.blue;
      case ClockType.tension:
        return Colors.orange;
      case ClockType.trace:
        return Colors.purple;
    }
  }
}

/// Class representing a countdown clock in the game
class Clock {
  final String id;
  String title;
  final int segments; // 4, 6, 8, or 10
  final ClockType type; // Campaign, Tension, Trace
  int progress; // Current filled segments
  final DateTime createdAt;
  DateTime? completedAt;
  
  /// Create a new clock
  Clock({
    String? id,
    required this.title,
    required this.segments,
    required this.type,
    this.progress = 0,
    DateTime? createdAt,
    this.completedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now();
  
  /// Check if the clock is complete
  bool get isComplete => progress >= segments;
  
  /// Advance the clock by one segment
  void advance() {
    if (progress < segments) {
      progress++;
      
      // If the clock is now complete, set the completedAt timestamp
      if (isComplete) {
        completedAt = DateTime.now();
      }
    }
  }
  
  /// Reset the clock progress
  void reset() {
    progress = 0;
    completedAt = null;
  }
  
  /// Create a clock from JSON
  factory Clock.fromJson(Map<String, dynamic> json) {
    return Clock(
      id: json['id'],
      title: json['title'],
      segments: json['segments'],
      type: ClockType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ClockType.campaign,
      ),
      progress: json['progress'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
  
  /// Convert the clock to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'segments': segments,
      'type': type.name,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
  
  /// Clone the clock
  Clock clone() {
    return Clock(
      id: id,
      title: title,
      segments: segments,
      type: type,
      progress: progress,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }
}
