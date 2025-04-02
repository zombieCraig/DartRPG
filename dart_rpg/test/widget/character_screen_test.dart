import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/screens/character_screen.dart';

// Mock GameProvider for testing
class MockGameProvider extends GameProvider {
  final Game _mockGame;
  
  MockGameProvider(this._mockGame);
  
  @override
  Game? get currentGame => _mockGame;
}

void main() {
  // Create test characters with assets
  Character createTestCharacter({
    required String name,
    required List<Asset> assets,
    bool isMainCharacter = false,
  }) {
    final character = Character(
      id: 'test-character-$name',
      name: name,
      handle: name.toLowerCase(),
      isMainCharacter: isMainCharacter,
      stats: [
        CharacterStat(name: 'Edge', value: 2),
        CharacterStat(name: 'Heart', value: 1),
        CharacterStat(name: 'Iron', value: 3),
        CharacterStat(name: 'Shadow', value: 2),
        CharacterStat(name: 'Wits', value: 1),
      ],
      assets: assets,
    );
    return character;
  }

  // Create test assets
  Asset createTestAsset({
    required String name,
    required String category,
    String? description,
  }) {
    return Asset(
      id: 'test-asset-$name',
      name: name,
      category: category,
      description: description,
    );
  }

  // Create a mock GameProvider
  Widget createTestApp({
    required List<Character> characters,
    Character? mainCharacter,
  }) {
    final mockGame = Game(
      id: 'test-game',
      name: 'Test Game',
      characters: characters,
      mainCharacter: mainCharacter,
      locations: [],
      sessions: [],
    );

    // Create a mock GameProvider with the current game set
    final mockGameProvider = MockGameProvider(mockGame);

    return MaterialApp(
      home: ChangeNotifierProvider<GameProvider>.value(
        value: mockGameProvider,
        child: const CharacterScreen(gameId: 'test-game'),
      ),
    );
  }

  group('CharacterScreen', () {
    testWidgets('displays character cards with assets', (WidgetTester tester) async {
      // Create test assets
      final baseRigAsset = createTestAsset(
        name: 'Base Rig',
        category: 'Base Rig',
        description: 'Your personal computer system',
      );
      
      final moduleAsset = createTestAsset(
        name: 'Stealth Module',
        category: 'Module',
        description: 'Enhanced stealth capabilities',
      );
      
      final pathAsset = createTestAsset(
        name: 'Infiltrator',
        category: 'Path',
        description: 'Specialized in infiltration',
      );

      // Create test characters with assets
      final character1 = createTestCharacter(
        name: 'Alice',
        assets: [baseRigAsset, moduleAsset],
        isMainCharacter: true,
      );
      
      final character2 = createTestCharacter(
        name: 'Bob',
        assets: [baseRigAsset, pathAsset],
      );

      // Build the widget
      await tester.pumpWidget(createTestApp(
        characters: [character1, character2],
        mainCharacter: character1,
      ));

      // Verify character cards are displayed
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      // Verify assets section is displayed
      expect(find.text('Assets:'), findsNWidgets(2)); // One for each character

      // Verify specific assets are displayed
      // Each asset name should appear in the UI
      expect(find.textContaining('Base Rig'), findsWidgets); // At least one for each character
      expect(find.textContaining('Stealth Module'), findsWidgets);
      expect(find.textContaining('Infiltrator'), findsWidgets);
    });

    testWidgets('displays empty state when no characters', (WidgetTester tester) async {
      // Build the widget with no characters
      await tester.pumpWidget(createTestApp(
        characters: [],
        mainCharacter: null,
      ));

      // Verify empty state is displayed
      expect(find.text('No characters yet'), findsOneWidget);
      expect(find.text('Create Character'), findsOneWidget);
    });

    testWidgets('displays add card when characters exist', (WidgetTester tester) async {
      // Create test character
      final character = createTestCharacter(
        name: 'Alice',
        assets: [createTestAsset(name: 'Base Rig', category: 'Base Rig')],
        isMainCharacter: true,
      );

      // Build the widget
      await tester.pumpWidget(createTestApp(
        characters: [character],
        mainCharacter: character,
      ));

      // Verify character card is displayed
      expect(find.text('Alice'), findsOneWidget);

      // Verify add card is displayed
      expect(find.text('Add Character'), findsOneWidget);
    });
  });
}
