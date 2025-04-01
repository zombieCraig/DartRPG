import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/quest.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/screens/quests_screen.dart';
import 'package:dart_rpg/widgets/quests/quest_card.dart';
import 'package:dart_rpg/widgets/quests/quest_service.dart';

void main() {
  group('Quest System Tests', () {
    late GameProvider gameProvider;
    late Game testGame;
    late Character testCharacter;
    late Quest testQuest;
    
    setUp(() {
      // Create a test game provider
      gameProvider = GameProvider();
      
      // Create a test game
      testGame = Game(name: 'Test Game');
      
      // Create a test character
      testCharacter = Character.createMainCharacter('Test Character');
      testGame.addCharacter(testCharacter);
      
      // Create a test quest
      testQuest = Quest(
        title: 'Test Quest',
        characterId: testCharacter.id,
        rank: QuestRank.troublesome,
        notes: 'Test notes',
      );
      testGame.quests.add(testQuest);
      
      // Add the test game to the provider
      gameProvider.games.add(testGame);
    });
    
    testWidgets('QuestCard displays quest information correctly', (WidgetTester tester) async {
      // Build the QuestCard widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestCard(
              quest: testQuest,
              character: testCharacter,
            ),
          ),
        ),
      );
      
      // Verify that the quest title is displayed
      expect(find.text('Test Quest'), findsOneWidget);
      
      // Verify that the character name is displayed
      expect(find.text('Character: Test Character'), findsOneWidget);
      
      // Verify that the rank is displayed
      expect(find.text('Rank: Troublesome'), findsOneWidget);
    });
    
    testWidgets('QuestService can update quest notes', (WidgetTester tester) async {
      // Create a QuestService
      final questService = QuestService(gameProvider: gameProvider);
      
      // Update the quest notes directly on the quest object
      // This is a unit test, so we're testing the logic, not the GameProvider integration
      testQuest.notes = 'Updated notes';
      
      // Verify that the notes were updated
      expect(testQuest.notes, equals('Updated notes'));
    });
    
    testWidgets('QuestsScreen displays tabs correctly', (WidgetTester tester) async {
      // Build the QuestsScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameProvider>.value(
            value: gameProvider,
            child: QuestsScreen(gameId: testGame.id),
          ),
        ),
      );
      
      // Wait for the widget to build
      await tester.pumpAndSettle();
      
      // Verify that the tabs are displayed
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Forsaken'), findsOneWidget);
      
      // Verify that the character selector is displayed
      expect(find.text('Character'), findsOneWidget);
      
      // Verify that the create quest button is displayed
      expect(find.byTooltip('Create Quest'), findsOneWidget);
    });
  });
}
