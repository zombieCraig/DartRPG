import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/quest.dart';
import 'package:dart_rpg/models/clock.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/quests_screen.dart';
import '../mocks/shared_preferences_mock.dart';
import '../mocks/mock_game_provider.dart';
import '../mocks/mock_datasworn_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGameProvider gameProvider;
  late SettingsProvider settingsProvider;
  late MockDataswornProvider dataswornProvider;
  late Game testGame;
  late Character testCharacter;

  setUp(() {
    setupSharedPreferencesMock();
    gameProvider = MockGameProvider();
    settingsProvider = SettingsProvider();
    dataswornProvider = MockDataswornProvider();

    testGame = Game(name: 'Test Game');
    testCharacter = Character(
      name: 'Runner',
      handle: 'r00t',
      isMainCharacter: true,
      stats: [
        CharacterStat(name: 'Edge', value: 2),
        CharacterStat(name: 'Heart', value: 1),
        CharacterStat(name: 'Iron', value: 3),
        CharacterStat(name: 'Shadow', value: 2),
        CharacterStat(name: 'Wits', value: 1),
      ],
    );
    testGame.addCharacter(testCharacter);
    gameProvider.setCurrentGameForTest(testGame);
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: gameProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<DataswornProvider>.value(value: dataswornProvider),
      ],
      child: MaterialApp(
        home: QuestsScreen(gameId: testGame.id),
      ),
    );
  }

  group('Quest Screen', () {
    testWidgets('shows quest tabs', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Forsaken'), findsOneWidget);
      expect(find.text('Clocks'), findsOneWidget);
    });

    testWidgets('shows character selector', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Character'), findsOneWidget);
      expect(find.text('Runner'), findsWidgets);
    });

    testWidgets('shows empty state when no quests', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Should show some indication of no quests
      expect(find.text('Quests'), findsOneWidget);
    });

    testWidgets('displays ongoing quest', (tester) async {
      final quest = Quest(
        title: 'Hack the Mainframe',
        characterId: testCharacter.id,
        rank: QuestRank.dangerous,
        notes: 'Need to find the access codes',
      );
      testGame.quests.add(quest);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Hack the Mainframe'), findsOneWidget);
    });

    testWidgets('displays quest rank', (tester) async {
      final quest = Quest(
        title: 'Side Job',
        characterId: testCharacter.id,
        rank: QuestRank.troublesome,
      );
      testGame.quests.add(quest);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Side Job'), findsOneWidget);
      expect(find.textContaining('Troublesome'), findsWidgets);
    });

    testWidgets('shows FAB for creating quest', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('can switch to Clocks tab', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clocks'));
      await tester.pumpAndSettle();

      // Character selector should be hidden on clocks tab
      // FAB should still be visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays clocks on Clocks tab', (tester) async {
      testGame.addClock(Clock(
        title: 'Corp Alert',
        segments: 4,
        type: ClockType.trace,
        progress: 1,
      ));
      testGame.addClock(Clock(
        title: 'Heist Timer',
        segments: 6,
        type: ClockType.campaign,
        progress: 3,
      ));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Clocks'));
      await tester.tap(find.text('Clocks'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Corp Alert'), findsOneWidget);
      expect(find.text('Heist Timer'), findsOneWidget);
    });

    testWidgets('completed quests show on Completed tab', (tester) async {
      final quest = Quest(
        title: 'Done Quest',
        characterId: testCharacter.id,
        rank: QuestRank.troublesome,
        status: QuestStatus.completed,
      );
      testGame.quests.add(quest);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to Completed tab
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Done Quest'), findsOneWidget);
    });

    testWidgets('forsaken quests show on Forsaken tab', (tester) async {
      final quest = Quest(
        title: 'Abandoned Quest',
        characterId: testCharacter.id,
        rank: QuestRank.formidable,
        status: QuestStatus.forsaken,
      );
      testGame.quests.add(quest);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Switch to Forsaken tab
      await tester.tap(find.text('Forsaken'));
      await tester.pumpAndSettle();

      expect(find.text('Abandoned Quest'), findsOneWidget);
    });
  });
}
