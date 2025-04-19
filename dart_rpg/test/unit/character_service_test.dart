import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/widgets/character/character_service.dart';

// Mock GameProvider for testing
class MockGameProvider extends GameProvider {
  final Game? _mockGame;
  
  MockGameProvider(this._mockGame);
  
  @override
  Game? get currentGame => _mockGame;
  
  @override
  Future<Character> createCharacter(String name, {bool isMainCharacter = false, String? handle}) async {
    if (_mockGame == null) {
      throw Exception('No game selected');
    }
    
    final character = Character(
      name: name,
      handle: handle,
      isMainCharacter: isMainCharacter,
    );
    
    _mockGame.characters.add(character);
    
    if (isMainCharacter) {
      _mockGame.mainCharacter = character;
    }
    
    return character;
  }
  
  @override
  Future<void> saveGame() async {
    // Mock implementation - do nothing
  }
}

void main() {
  // Initialize Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();
  group('CharacterService', () {
    late MockGameProvider mockGameProvider;
    late CharacterService characterService;
    late Game mockGame;
    
    setUp(() {
      mockGame = Game(
        id: 'test-game',
        name: 'Test Game',
        characters: [],
        locations: [],
        sessions: [],
      );
      mockGameProvider = MockGameProvider(mockGame);
      characterService = CharacterService(mockGameProvider);
    });
    
    test('createCharacter creates a character with correct properties', () async {
      // Act
      final character = await characterService.createCharacter(
        name: 'Test Character',
        handle: 'test',
        bio: 'Test bio',
        imageUrl: 'https://example.com/image.jpg',
        isMainCharacter: true,
        stats: [
          CharacterStat(name: 'Edge', value: 3),
          CharacterStat(name: 'Heart', value: 2),
        ],
      );
      
      // Assert
      expect(character, isNotNull);
      expect(mockGame.characters.length, 1);
      expect(mockGame.characters[0].name, 'Test Character');
      expect(mockGame.characters[0].handle, 'test');
      expect(mockGame.characters[0].bio, 'Test bio');
      expect(mockGame.characters[0].imageUrl, 'https://example.com/image.jpg');
      expect(mockGame.characters[0].isMainCharacter, true);
      expect(mockGame.characters[0].stats.length, 2);
      expect(mockGame.characters[0].stats[0].name, 'Edge');
      expect(mockGame.characters[0].stats[0].value, 3);
      expect(mockGame.characters[0].stats[1].name, 'Heart');
      expect(mockGame.characters[0].stats[1].value, 2);
      expect(mockGame.characters[0].momentum, 2);
      expect(mockGame.characters[0].health, 5);
      expect(mockGame.characters[0].spirit, 5);
      expect(mockGame.characters[0].supply, 5);
      expect(mockGame.characters[0].assets.length, 1);
      expect(mockGame.characters[0].assets[0].category, 'Base Rig');
    });
    
    test('updateCharacter updates a character with correct properties', () async {
      // Arrange
      final character = await characterService.createCharacter(
        name: 'Test Character',
        handle: 'test',
        isMainCharacter: true,
      );
      
      // Act
      final result = await characterService.updateCharacter(
        character: character!,
        name: 'Updated Character',
        handle: 'updated',
        bio: 'Updated bio',
        imageUrl: 'https://example.com/updated.jpg',
        stats: [
          CharacterStat(name: 'Edge', value: 4),
          CharacterStat(name: 'Heart', value: 3),
        ],
        momentum: 3,
        health: 4,
        spirit: 3,
        supply: 2,
        notes: ['Note 1', 'Note 2'],
        impacts: {
          'wounded': true,
          'shaken': true,
        },
      );
      
      // Assert
      expect(result, true);
      expect(mockGame.characters.length, 1);
      expect(mockGame.characters[0].name, 'Updated Character');
      expect(mockGame.characters[0].handle, 'updated');
      expect(mockGame.characters[0].bio, 'Updated bio');
      expect(mockGame.characters[0].imageUrl, 'https://example.com/updated.jpg');
      expect(mockGame.characters[0].stats.length, 2);
      expect(mockGame.characters[0].stats[0].name, 'Edge');
      expect(mockGame.characters[0].stats[0].value, 4);
      expect(mockGame.characters[0].stats[1].name, 'Heart');
      expect(mockGame.characters[0].stats[1].value, 3);
      expect(mockGame.characters[0].momentum, 3);
      expect(mockGame.characters[0].health, 4);
      expect(mockGame.characters[0].spirit, 3);
      expect(mockGame.characters[0].supply, 2);
      expect(mockGame.characters[0].notes.length, 2);
      expect(mockGame.characters[0].notes[0], 'Note 1');
      expect(mockGame.characters[0].notes[1], 'Note 2');
      expect(mockGame.characters[0].impactWounded, true);
      expect(mockGame.characters[0].impactShaken, true);
    });
    
    test('deleteCharacter removes a character', () async {
      // Arrange
      final character = await characterService.createCharacter(
        name: 'Test Character',
        isMainCharacter: true,
      );
      
      // Act
      final result = await characterService.deleteCharacter(character!.id);
      
      // Assert
      expect(result, true);
      expect(mockGame.characters.length, 0);
      expect(mockGame.mainCharacter, null);
    });
    
    test('setMainCharacter sets a character as the main character', () async {
      // Arrange
      final character1 = await characterService.createCharacter(
        name: 'Character 1',
        isMainCharacter: false,
      );
      
      final character2 = await characterService.createCharacter(
        name: 'Character 2',
        isMainCharacter: false,
      );
      
      // Act
      final result = await characterService.setMainCharacter(character2!.id);
      
      // Assert
      expect(result, true);
      expect(mockGame.mainCharacter, isNotNull);
      expect(mockGame.mainCharacter!.id, character2.id);
      expect(mockGame.mainCharacter!.id != character1!.id, true);
    });
    
    test('getCharacterById returns the correct character', () async {
      // Arrange
      final character1 = await characterService.createCharacter(
        name: 'Character 1',
      );
      
      final character2 = await characterService.createCharacter(
        name: 'Character 2',
      );
      
      // Act
      final result = characterService.getCharacterById(character2!.id);
      
      // Assert
      expect(result, isNotNull);
      expect(result!.id, character2.id);
      expect(result.name, 'Character 2');
      expect(result.id != character1!.id, true);
    });
    
    test('getAllCharacters returns all characters', () async {
      // Arrange
      await characterService.createCharacter(name: 'Character 1');
      await characterService.createCharacter(name: 'Character 2');
      await characterService.createCharacter(name: 'Character 3');
      
      // Act
      final result = characterService.getAllCharacters();
      
      // Assert
      expect(result.length, 3);
      expect(result[0].name, 'Character 1');
      expect(result[1].name, 'Character 2');
      expect(result[2].name, 'Character 3');
    });
    
    test('getMainCharacter returns the main character', () async {
      // Arrange
      await characterService.createCharacter(
        name: 'Character 1',
        isMainCharacter: false,
      );
      
      await characterService.createCharacter(
        name: 'Main Character',
        isMainCharacter: true,
      );
      
      // Act
      final result = characterService.getMainCharacter();
      
      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'Main Character');
      expect(result.isMainCharacter, true);
    });
  });
}
