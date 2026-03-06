import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/character_screen.dart';
import '../mocks/shared_preferences_mock.dart';
import '../mocks/mock_game_provider.dart';
import '../mocks/mock_datasworn_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGameProvider gameProvider;
  late MockDataswornProvider dataswornProvider;
  late SettingsProvider settingsProvider;
  late Game testGame;

  setUp(() {
    setupSharedPreferencesMock();
    gameProvider = MockGameProvider();
    dataswornProvider = MockDataswornProvider();
    settingsProvider = SettingsProvider();

    testGame = Game(name: 'Test Game');
    gameProvider.setCurrentGameForTest(testGame);
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
        ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CharacterScreen(gameId: testGame.id),
        ),
      ),
    );
  }

  group('Character Screen Flow', () {
    testWidgets('shows empty state when no characters', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No characters yet'), findsOneWidget);
      expect(find.text('Create Character'), findsOneWidget);
    });

    testWidgets('displays character with handle', (tester) async {
      final char = Character(name: 'Alice', handle: 'al1c3', isMainCharacter: true);
      testGame.addCharacter(char);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('al1c3'), findsOneWidget);
    });

    testWidgets('displays multiple characters', (tester) async {
      testGame.addCharacter(Character(name: 'Alice', handle: 'al1c3', isMainCharacter: true));
      testGame.addCharacter(Character(name: 'Bob', handle: 'b0b'));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('al1c3'), findsOneWidget);
      expect(find.text('b0b'), findsOneWidget);
    });

    testWidgets('shows add character card when characters exist', (tester) async {
      testGame.addCharacter(Character(name: 'Alice', handle: 'al1c3', isMainCharacter: true));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Add Character'), findsOneWidget);
    });

    testWidgets('shows character assets', (tester) async {
      final char = Character(
        name: 'Alice',
        handle: 'al1c3',
        isMainCharacter: true,
        assets: [
          Asset(id: 'a1', name: 'Ghost Rig', category: 'Base Rig', description: 'Custom rig'),
          Asset(id: 'a2', name: 'Stealth Module', category: 'Module', description: 'Stealth capabilities'),
        ],
      );
      testGame.addCharacter(char);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Assets:'), findsOneWidget);
      expect(find.textContaining('Ghost Rig'), findsWidgets);
      expect(find.textContaining('Stealth Module'), findsWidgets);
    });

    testWidgets('shows character stats', (tester) async {
      final char = Character(
        name: 'Alice',
        handle: 'al1c3',
        isMainCharacter: true,
        stats: [
          CharacterStat(name: 'Edge', value: 3),
          CharacterStat(name: 'Heart', value: 1),
          CharacterStat(name: 'Iron', value: 2),
          CharacterStat(name: 'Shadow', value: 2),
          CharacterStat(name: 'Wits', value: 1),
        ],
      );
      testGame.addCharacter(char);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Stats should be visible somewhere on the character card
      expect(find.textContaining('Edge'), findsWidgets);
    });
  });
}
