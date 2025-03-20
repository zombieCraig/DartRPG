import 'dart:convert';
import 'package:uuid/uuid.dart';

class Location {
  final String id;
  String name;
  String? description;
  String? imageUrl;
  List<String> notes;

  Location({
    String? id,
    required this.name,
    this.description,
    this.imageUrl,
    List<String>? notes,
  })  : id = id ?? const Uuid().v4(),
        notes = notes ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      notes: (json['notes'] as List?)?.cast<String>() ?? [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Location.fromJsonString(String jsonString) {
    return Location.fromJson(jsonDecode(jsonString));
  }

  void addNote(String note) {
    notes.add(note);
  }

  void removeNote(int index) {
    if (index >= 0 && index < notes.length) {
      notes.removeAt(index);
    }
  }
}
