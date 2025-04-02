import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum LocationSegment {
  core,
  corpNet,
  govNet,
  darkNet,
}

extension LocationSegmentExtension on LocationSegment {
  String get displayName {
    switch (this) {
      case LocationSegment.core:
        return 'Core';
      case LocationSegment.corpNet:
        return 'CorpNet';
      case LocationSegment.govNet:
        return 'GovNet';
      case LocationSegment.darkNet:
        return 'DarkNet';
    }
  }
  
  Color get color {
    switch (this) {
      case LocationSegment.core:
        return Colors.green;
      case LocationSegment.corpNet:
        return Colors.yellow;
      case LocationSegment.govNet:
        return Colors.grey;
      case LocationSegment.darkNet:
        return Colors.black;
    }
  }
  
  static LocationSegment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'core':
        return LocationSegment.core;
      case 'corpnet':
        return LocationSegment.corpNet;
      case 'govnet':
        return LocationSegment.govNet;
      case 'darknet':
        return LocationSegment.darkNet;
      default:
        return LocationSegment.core;
    }
  }
}

class Location {
  final String id;
  String name;
  String? description;
  String? imageUrl;
  List<String> notes;
  List<String> connectedLocationIds;
  LocationSegment segment;
  String? nodeType; // Added nodeType property
  double? x;
  double? y;
  double? scale;

  Location({
    String? id,
    required this.name,
    this.description,
    this.imageUrl,
    List<String>? notes,
    List<String>? connectedLocationIds,
    this.segment = LocationSegment.core,
    this.nodeType, // Added nodeType parameter
    this.x,
    this.y,
    this.scale,
  })  : id = id ?? const Uuid().v4(),
        notes = notes ?? [],
        connectedLocationIds = connectedLocationIds ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'notes': notes,
      'connectedLocationIds': connectedLocationIds,
      'segment': segment.toString().split('.').last,
      'nodeType': nodeType,
      'x': x,
      'y': y,
      'scale': scale,
    };
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      notes: (json['notes'] as List?)?.cast<String>() ?? [],
      connectedLocationIds: (json['connectedLocationIds'] as List?)?.cast<String>() ?? [],
      segment: json['segment'] != null 
          ? LocationSegmentExtension.fromString(json['segment'])
          : LocationSegment.core,
      nodeType: json['nodeType'],
      x: json['x'] != null ? (json['x'] as num).toDouble() : null,
      y: json['y'] != null ? (json['y'] as num).toDouble() : null,
      scale: json['scale'] != null ? (json['scale'] as num).toDouble() : null,
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
  
  void addConnection(String locationId) {
    if (!connectedLocationIds.contains(locationId)) {
      connectedLocationIds.add(locationId);
    }
  }
  
  void removeConnection(String locationId) {
    connectedLocationIds.remove(locationId);
  }
  
  bool isConnectedTo(String locationId) {
    return connectedLocationIds.contains(locationId);
  }
  
  void updatePosition(double newX, double newY) {
    x = newX;
    y = newY;
  }
  
  void updateScale(double newScale) {
    scale = newScale;
  }
}
