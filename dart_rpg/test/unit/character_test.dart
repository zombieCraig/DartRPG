import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/character.dart';

void main() {
  group('Character', () {
    group('getHandle', () {
      test('returns handle when it exists', () {
        final character = Character(
          name: 'John Doe',
          handle: 'johnny',
        );
        
        expect(character.getHandle(), equals('johnny'));
      });
      
      test('generates handle from first name when handle is null', () {
        final character = Character(
          name: 'John Doe',
          handle: null,
        );
        
        expect(character.getHandle(), equals('John'));
      });
      
      test('generates handle from first name when handle is empty', () {
        final character = Character(
          name: 'John Doe',
          handle: '',
        );
        
        expect(character.getHandle(), equals('John'));
      });
      
      test('removes special characters from generated handle', () {
        final character = Character(
          name: 'J@hn [Doe]',
          handle: null,
        );
        
        expect(character.getHandle(), equals('Jhn'));
      });
      
      test('handles single word names', () {
        final character = Character(
          name: 'Cher',
          handle: null,
        );
        
        expect(character.getHandle(), equals('Cher'));
      });
    });
    
    group('setHandle', () {
      test('sets handle correctly', () {
        final character = Character(
          name: 'John Doe',
          handle: null,
        );
        
        character.setHandle('johnny');
        expect(character.handle, equals('johnny'));
      });
      
      test('sets handle to null when null is provided', () {
        final character = Character(
          name: 'John Doe',
          handle: 'johnny',
        );
        
        character.setHandle(null);
        expect(character.handle, isNull);
      });
      
      test('sets handle to null when empty string is provided', () {
        final character = Character(
          name: 'John Doe',
          handle: 'johnny',
        );
        
        character.setHandle('');
        expect(character.handle, isNull);
      });
      
      test('removes spaces from handle', () {
        final character = Character(
          name: 'John Doe',
          handle: null,
        );
        
        character.setHandle('johnny boy');
        expect(character.handle, equals('johnnyboy'));
      });
      
      test('removes special characters from handle', () {
        final character = Character(
          name: 'John Doe',
          handle: null,
        );
        
        character.setHandle('j@hnny#b[o]y');
        expect(character.handle, equals('jhnnyboy'));
      });
    });
    
    group('createMainCharacter', () {
      test('creates character with provided handle', () {
        final character = Character.createMainCharacter('John Doe', handle: 'johnny');
        
        expect(character.name, equals('John Doe'));
        expect(character.handle, equals('johnny'));
        expect(character.isMainCharacter, isTrue);
      });
      
      test('generates handle when not provided', () {
        final character = Character.createMainCharacter('John Doe');
        
        expect(character.name, equals('John Doe'));
        expect(character.handle, equals('John'));
        expect(character.isMainCharacter, isTrue);
      });
      
      test('generates handle when empty string is provided', () {
        final character = Character.createMainCharacter('John Doe', handle: '');
        
        expect(character.name, equals('John Doe'));
        expect(character.handle, equals('John'));
        expect(character.isMainCharacter, isTrue);
      });
      
      test('creates character with default stats', () {
        final character = Character.createMainCharacter('John Doe');
        
        expect(character.stats.length, equals(5));
        expect(character.stats.any((s) => s.name == 'Edge' && s.value == 1), isTrue);
        expect(character.stats.any((s) => s.name == 'Heart' && s.value == 1), isTrue);
        expect(character.stats.any((s) => s.name == 'Iron' && s.value == 1), isTrue);
        expect(character.stats.any((s) => s.name == 'Shadow' && s.value == 1), isTrue);
        expect(character.stats.any((s) => s.name == 'Wits' && s.value == 1), isTrue);
      });
      
      test('creates character with Base Rig asset', () {
        final character = Character.createMainCharacter('John Doe');
        
        expect(character.assets.length, equals(1));
        expect(character.assets[0].name, equals('Base Rig'));
        expect(character.assets[0].category, equals('Base Rig'));
        expect(character.assets[0].enabled, isTrue);
      });
    });
  });
}
