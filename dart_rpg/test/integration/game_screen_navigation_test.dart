import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/game_screen.dart';
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

    testGame = Game(name: 'Neon Run');
    final char = Character.createMainCharacter('Runner');
    testGame.addCharacter(char);
    gameProvider.setCurrentGameForTest(testGame);
  });

  Widget buildApp({int initialTabIndex = 1}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
        ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: GameScreen(gameId: testGame.id, initialTabIndex: initialTabIndex),
      ),
    );
  }

  group('Game Screen Navigation', () {
    testWidgets('displays game name in app bar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Neon Run'), findsOneWidget);
    });

    testWidgets('shows all bottom navigation tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('Locations'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);
      expect(find.text('Moves'), findsOneWidget);
      expect(find.text('Oracles'), findsOneWidget);
      expect(find.text('Assets'), findsOneWidget);
    });

    testWidgets('starts on Characters tab by default', (tester) async {
      // Use a game without a main character so it stays on Characters tab
      final noCharGame = Game(name: 'Empty');
      gameProvider.setCurrentGameForTest(noCharGame);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: GameScreen(gameId: noCharGame.id),
        ),
      ));
      await tester.pumpAndSettle();

      // Characters tab content should be visible
      expect(find.text('No characters yet'), findsOneWidget);
    });

    testWidgets('can navigate to Journal tab', (tester) async {
      await tester.pumpWidget(buildApp(initialTabIndex: 1));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      // Journal content should be visible (no session selected)
      expect(find.textContaining('session'), findsWidgets);
    });

    testWidgets('can navigate to Locations tab', (tester) async {
      // Use a game with no main character to stay on Characters initially
      final noCharGame = Game(name: 'Empty');
      gameProvider.setCurrentGameForTest(noCharGame);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: GameScreen(gameId: noCharGame.id, initialTabIndex: 1),
        ),
      ));
      await tester.pumpAndSettle();

      // Verify we start on Characters tab
      expect(find.text('No characters yet'), findsOneWidget);

      await tester.tap(find.text('Locations'));
      // Graph view animates continuously, so use pump instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 500));

      // Characters empty state should no longer be visible
      expect(find.text('No characters yet'), findsNothing);
    });

    testWidgets('respects initialTabIndex parameter', (tester) async {
      await tester.pumpWidget(buildApp(initialTabIndex: 4));
      await tester.pumpAndSettle();

      // Should start on Moves tab
      // Moves tab will show empty state or moves list
      expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget);
    });

    testWidgets('shows settings popup menu', (tester) async {
      // Use a game without main character to avoid Journal tab with animations
      final simpleGame = Game(name: 'Simple');
      gameProvider.setCurrentGameForTest(simpleGame);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
          ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: GameScreen(gameId: simpleGame.id, initialTabIndex: 1),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap the settings popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Game Settings'), findsOneWidget);
      expect(find.text('App Settings'), findsOneWidget);
    });

    testWidgets('shows export button in app bar', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_alt), findsOneWidget);
    });
  });
}
