import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/location.dart';

void main() {
  group('Location', () {
    group('constructor', () {
      test('creates location with default values', () {
        final location = Location(name: 'Test Location');
        
        expect(location.name, equals('Test Location'));
        expect(location.description, isNull);
        expect(location.imageUrl, isNull);
        expect(location.notes, isEmpty);
        expect(location.connectedLocationIds, isEmpty);
        expect(location.segment, equals(LocationSegment.core));
        expect(location.x, isNull);
        expect(location.y, isNull);
        expect(location.scale, isNull);
        expect(location.id, isNotNull);
      });
      
      test('creates location with provided values', () {
        final location = Location(
          id: 'test-id',
          name: 'Test Location',
          description: 'Test Description',
          imageUrl: 'https://example.com/image.jpg',
          notes: ['Note 1', 'Note 2'],
          connectedLocationIds: ['loc1', 'loc2'],
          segment: LocationSegment.corpNet,
          x: 10.0,
          y: 20.0,
          scale: 1.5,
        );
        
        expect(location.id, equals('test-id'));
        expect(location.name, equals('Test Location'));
        expect(location.description, equals('Test Description'));
        expect(location.imageUrl, equals('https://example.com/image.jpg'));
        expect(location.notes, equals(['Note 1', 'Note 2']));
        expect(location.connectedLocationIds, equals(['loc1', 'loc2']));
        expect(location.segment, equals(LocationSegment.corpNet));
        expect(location.x, equals(10.0));
        expect(location.y, equals(20.0));
        expect(location.scale, equals(1.5));
      });
    });
    
    group('toJson and fromJson', () {
      test('serializes and deserializes correctly', () {
        final original = Location(
          id: 'test-id',
          name: 'Test Location',
          description: 'Test Description',
          imageUrl: 'https://example.com/image.jpg',
          notes: ['Note 1', 'Note 2'],
          connectedLocationIds: ['loc1', 'loc2'],
          segment: LocationSegment.govNet,
          x: 10.0,
          y: 20.0,
          scale: 1.5,
        );
        
        final json = original.toJson();
        final deserialized = Location.fromJson(json);
        
        expect(deserialized.id, equals(original.id));
        expect(deserialized.name, equals(original.name));
        expect(deserialized.description, equals(original.description));
        expect(deserialized.imageUrl, equals(original.imageUrl));
        expect(deserialized.notes, equals(original.notes));
        expect(deserialized.connectedLocationIds, equals(original.connectedLocationIds));
        expect(deserialized.segment, equals(original.segment));
        expect(deserialized.x, equals(original.x));
        expect(deserialized.y, equals(original.y));
        expect(deserialized.scale, equals(original.scale));
      });
      
      test('handles null values correctly', () {
        final original = Location(
          name: 'Test Location',
        );
        
        final json = original.toJson();
        final deserialized = Location.fromJson(json);
        
        expect(deserialized.id, equals(original.id));
        expect(deserialized.name, equals(original.name));
        expect(deserialized.description, isNull);
        expect(deserialized.imageUrl, isNull);
        expect(deserialized.notes, isEmpty);
        expect(deserialized.connectedLocationIds, isEmpty);
        expect(deserialized.segment, equals(LocationSegment.core));
        expect(deserialized.x, isNull);
        expect(deserialized.y, isNull);
        expect(deserialized.scale, isNull);
      });
    });
    
    group('addNote and removeNote', () {
      test('adds note correctly', () {
        final location = Location(name: 'Test Location');
        
        location.addNote('Test Note');
        
        expect(location.notes.length, equals(1));
        expect(location.notes[0], equals('Test Note'));
      });
      
      test('removes note correctly', () {
        final location = Location(
          name: 'Test Location',
          notes: ['Note 1', 'Note 2', 'Note 3'],
        );
        
        location.removeNote(1);
        
        expect(location.notes.length, equals(2));
        expect(location.notes, equals(['Note 1', 'Note 3']));
      });
      
      test('ignores invalid index when removing note', () {
        final location = Location(
          name: 'Test Location',
          notes: ['Note 1', 'Note 2'],
        );
        
        location.removeNote(-1);
        location.removeNote(2);
        
        expect(location.notes.length, equals(2));
        expect(location.notes, equals(['Note 1', 'Note 2']));
      });
    });
    
    group('connection management', () {
      test('adds connection correctly', () {
        final location = Location(name: 'Test Location');
        
        location.addConnection('loc1');
        
        expect(location.connectedLocationIds.length, equals(1));
        expect(location.connectedLocationIds[0], equals('loc1'));
      });
      
      test('does not add duplicate connection', () {
        final location = Location(
          name: 'Test Location',
          connectedLocationIds: ['loc1'],
        );
        
        location.addConnection('loc1');
        
        expect(location.connectedLocationIds.length, equals(1));
        expect(location.connectedLocationIds[0], equals('loc1'));
      });
      
      test('removes connection correctly', () {
        final location = Location(
          name: 'Test Location',
          connectedLocationIds: ['loc1', 'loc2', 'loc3'],
        );
        
        location.removeConnection('loc2');
        
        expect(location.connectedLocationIds.length, equals(2));
        expect(location.connectedLocationIds, equals(['loc1', 'loc3']));
      });
      
      test('ignores non-existent connection when removing', () {
        final location = Location(
          name: 'Test Location',
          connectedLocationIds: ['loc1', 'loc2'],
        );
        
        location.removeConnection('loc3');
        
        expect(location.connectedLocationIds.length, equals(2));
        expect(location.connectedLocationIds, equals(['loc1', 'loc2']));
      });
      
      test('checks connection correctly', () {
        final location = Location(
          name: 'Test Location',
          connectedLocationIds: ['loc1', 'loc2'],
        );
        
        expect(location.isConnectedTo('loc1'), isTrue);
        expect(location.isConnectedTo('loc3'), isFalse);
      });
    });
    
    group('position and scale management', () {
      test('updates position correctly', () {
        final location = Location(name: 'Test Location');
        
        location.updatePosition(10.0, 20.0);
        
        expect(location.x, equals(10.0));
        expect(location.y, equals(20.0));
      });
      
      test('updates scale correctly', () {
        final location = Location(name: 'Test Location');
        
        location.updateScale(1.5);
        
        expect(location.scale, equals(1.5));
      });
    });
    
    group('LocationSegment', () {
      test('displayName returns correct values', () {
        expect(LocationSegment.core.displayName, equals('Core'));
        expect(LocationSegment.corpNet.displayName, equals('CorpNet'));
        expect(LocationSegment.govNet.displayName, equals('GovNet'));
        expect(LocationSegment.darkNet.displayName, equals('DarkNet'));
      });
      
      test('color returns correct values', () {
        expect(LocationSegment.core.color, equals(Colors.green));
        expect(LocationSegment.corpNet.color, equals(Colors.yellow));
        expect(LocationSegment.govNet.color, equals(Colors.grey));
        expect(LocationSegment.darkNet.color, equals(Colors.black));
      });
      
      test('fromString returns correct enum values', () {
        expect(LocationSegmentExtension.fromString('core'), equals(LocationSegment.core));
        expect(LocationSegmentExtension.fromString('corpnet'), equals(LocationSegment.corpNet));
        expect(LocationSegmentExtension.fromString('govnet'), equals(LocationSegment.govNet));
        expect(LocationSegmentExtension.fromString('darknet'), equals(LocationSegment.darkNet));
      });
      
      test('fromString handles case insensitivity', () {
        expect(LocationSegmentExtension.fromString('CORE'), equals(LocationSegment.core));
        expect(LocationSegmentExtension.fromString('CorpNet'), equals(LocationSegment.corpNet));
        expect(LocationSegmentExtension.fromString('govNet'), equals(LocationSegment.govNet));
        expect(LocationSegmentExtension.fromString('DarkNet'), equals(LocationSegment.darkNet));
      });
      
      test('fromString returns default for invalid values', () {
        expect(LocationSegmentExtension.fromString('invalid'), equals(LocationSegment.core));
        expect(LocationSegmentExtension.fromString(''), equals(LocationSegment.core));
      });
    });
  });
}
