import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/game_selection_screen.dart';
import '../mocks/shared_preferences_mock.dart';
import '../mocks/mock_game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGameProvider gameProvider;
  late SettingsProvider settingsProvider;

  setUp(() {
    setupSharedPreferencesMock();
    gameProvider = MockGameProvider();
    settingsProvider = SettingsProvider();
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: const GameSelectionScreen(),
      ),
    );
  }

  group('Game Selection Screen', () {
    testWidgets('shows empty state when no games exist', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No Games Found'), findsOneWidget);
      expect(find.text('Create New Game'), findsOneWidget);
      expect(find.text('Import Game'), findsOneWidget);
    });

    testWidgets('shows game list when games exist', (tester) async {
      final game = Game(name: 'Test Campaign');
      gameProvider.setCurrentGameForTest(game);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Your Games'), findsOneWidget);
      expect(find.text('Test Campaign'), findsOneWidget);
      expect(find.text('New Game'), findsOneWidget);
    });

    testWidgets('shows game metadata in list', (tester) async {
      final game = Game(name: 'Neon Run');
      final char = Character(name: 'Runner', handle: 'r00t');
      game.addCharacter(char);
      game.createNewSession('Session 1');
      gameProvider.setCurrentGameForTest(game);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Neon Run'), findsOneWidget);
      expect(find.textContaining('Sessions: 1'), findsOneWidget);
      expect(find.textContaining('Characters: 1'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      final game = Game(name: 'Delete Me');
      gameProvider.setCurrentGameForTest(game);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Game'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete "Delete Me"?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel delete closes dialog without deleting', (tester) async {
      final game = Game(name: 'Keep Me');
      gameProvider.setCurrentGameForTest(game);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open delete dialog
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Game should still be visible
      expect(find.text('Keep Me'), findsOneWidget);
    });

    testWidgets('settings button is visible', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
