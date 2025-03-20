import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'journal_entry.dart';

class Session {
  final String id;
  String title;
  String gameId;
  DateTime createdAt;
  DateTime lastUpdatedAt;
  List<JournalEntry> entries;

  Session({
    String? id,
    required this.title,
    required this.gameId,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<JournalEntry>? entries,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUpdatedAt = lastUpdatedAt ?? DateTime.now(),
        entries = entries ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'gameId': gameId,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      title: json['title'],
      gameId: json['gameId'],
      createdAt: DateTime.parse(json['createdAt']),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt']),
      entries: (json['entries'] as List)
          .map((e) => JournalEntry.fromJson(e))
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Session.fromJsonString(String jsonString) {
    return Session.fromJson(jsonDecode(jsonString));
  }

  void addEntry(JournalEntry entry) {
    entries.add(entry);
    lastUpdatedAt = DateTime.now();
  }

  void removeEntry(String entryId) {
    entries.removeWhere((e) => e.id == entryId);
    lastUpdatedAt = DateTime.now();
  }

  JournalEntry createNewEntry(String content) {
    final entry = JournalEntry(content: content);
    addEntry(entry);
    return entry;
  }

  void updateTitle(String newTitle) {
    title = newTitle;
    lastUpdatedAt = DateTime.now();
  }
}
