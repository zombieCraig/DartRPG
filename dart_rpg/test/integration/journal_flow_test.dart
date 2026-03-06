import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/journal_screen.dart';
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
    final char = Character.createMainCharacter('Runner');
    testGame.addCharacter(char);
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
          body: JournalScreen(gameId: testGame.id),
        ),
      ),
    );
  }

  // MarkdownBody never fully settles, so use pump() for tests with journal entries
  Future<void> pumpWithEntries(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('Journal Flow', () {
    testWidgets('shows empty state when no sessions exist', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Select Session'), findsOneWidget);
      expect(find.textContaining('No session selected'), findsOneWidget);
    });

    testWidgets('shows new session button', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('new session dialog appears on tap', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('New Session'));
      await tester.pumpAndSettle();

      expect(find.text('New Session'), findsWidgets);
      expect(find.text('Session Title'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows session entries when session has entries', (tester) async {
      final session = testGame.createNewSession('Session 1');
      session.createNewEntry('First entry content');
      session.createNewEntry('Second entry content');
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.textContaining('First entry content'), findsOneWidget);
      expect(find.textContaining('Second entry content'), findsOneWidget);
    });

    testWidgets('shows new journal entry button when session is selected', (tester) async {
      final session = testGame.createNewSession('Session 1');
      gameProvider.setCurrentSessionForTest(session);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('New Journal Entry'), findsOneWidget);
    });

    testWidgets('shows empty state when session has no entries', (tester) async {
      final session = testGame.createNewSession('Empty Session');
      gameProvider.setCurrentSessionForTest(session);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('No journal entries yet'), findsOneWidget);
    });

    testWidgets('shows linked characters on journal entries', (tester) async {
      final char = testGame.characters.first;
      final session = testGame.createNewSession('Session 1');
      final entry = session.createNewEntry('Entry with character link');
      entry.linkedCharacterIds.add(char.id);
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('shows linked locations on journal entries', (tester) async {
      final rig = testGame.rigLocation!;
      final session = testGame.createNewSession('Session 1');
      final entry = session.createNewEntry('Entry with location link');
      entry.linkedLocationIds.add(rig.id);
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.byIcon(Icons.place), findsWidgets);
      expect(find.text('Your Rig'), findsWidgets);
    });

    testWidgets('shows move roll on journal entry', (tester) async {
      final session = testGame.createNewSession('Session 1');
      final entry = session.createNewEntry('Made a move');
      entry.moveRoll = MoveRoll(
        moveName: 'Face Danger',
        actionDie: 4,
        statValue: 2,
        challengeDice: [3, 7],
        outcome: 'Weak Hit',
      );
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.textContaining('Face Danger'), findsOneWidget);
      expect(find.textContaining('Weak Hit'), findsOneWidget);
    });

    testWidgets('shows oracle roll on journal entry', (tester) async {
      final session = testGame.createNewSession('Session 1');
      final entry = session.createNewEntry('Consulted oracle');
      entry.oracleRoll = OracleRoll(
        oracleName: 'Action',
        result: 'Investigate',
        dice: [42],
      );
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.textContaining('Action'), findsOneWidget);
      expect(find.textContaining('Investigate'), findsOneWidget);
    });

    testWidgets('session dropdown shows all sessions', (tester) async {
      testGame.createNewSession('Session 1');
      testGame.createNewSession('Session 2');
      testGame.createNewSession('Session 3');
      gameProvider.setCurrentSessionForTest(testGame.sessions.first);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap the dropdown to open it
      await tester.tap(find.text('Session 1'));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsWidgets);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('Session 3'), findsOneWidget);
    });

    testWidgets('export button visible when session has entries', (tester) async {
      final session = testGame.createNewSession('Session 1');
      session.createNewEntry('Some content');
      gameProvider.setCurrentSessionForTest(session);

      await pumpWithEntries(tester);

      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });
  });
}
