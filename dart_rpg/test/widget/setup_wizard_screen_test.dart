import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/providers/settings_provider.dart';
import 'package:dart_rpg/screens/setup_wizard_screen.dart';
import 'package:dart_rpg/widgets/setup_wizard/wizard_step_indicator.dart';
import '../mocks/mock_game_provider.dart';
import '../mocks/mock_datasworn_provider.dart';
import '../mocks/shared_preferences_mock.dart';

void main() {
  late MockGameProvider mockGameProvider;
  late MockDataswornProvider mockDataswornProvider;

  setUp(() async {
    setupSharedPreferencesMock();
    mockGameProvider = MockGameProvider();
    mockDataswornProvider = MockDataswornProvider();

    // Create a test game and set it as current
    final game = Game(name: 'Test Game');
    mockGameProvider.setCurrentGameForTest(game);
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GameProvider>.value(value: mockGameProvider),
        ChangeNotifierProvider<DataswornProvider>.value(value: mockDataswornProvider),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
      ],
      child: const MaterialApp(
        home: SetupWizardScreen(),
      ),
    );
  }

  group('SetupWizardScreen', () {
    testWidgets('shows step indicator with 5 steps', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(WizardStepIndicator), findsOneWidget);
      // Should show step labels
      expect(find.text('Truths'), findsOneWidget);
      expect(find.text('Factions'), findsOneWidget);
      expect(find.text('Character'), findsOneWidget);
      expect(find.text('Network'), findsOneWidget);
      expect(find.text('Scene'), findsOneWidget);
    });

    testWidgets('shows Campaign Setup title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Campaign Setup'), findsOneWidget);
    });

    testWidgets('shows Skip All button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Skip All'), findsOneWidget);
    });

    testWidgets('shows navigation buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should show Skip and Next on first step, no Back
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('navigates to next step on Next press', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should now show Back button (on step 2)
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('navigates back on Back press', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Go back to step 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should not show Back on step 1
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Skip advances to next step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip step 1
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should be on step 2 (Back is visible)
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('shows Finish button on last step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to last step (step 5)
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Should show Finish instead of Next
      expect(find.text('Finish'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('starts on World Truths step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1 content
      expect(
        find.textContaining('Define the world'),
        findsOneWidget,
      );
    });

    testWidgets('step 2 shows faction setup', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Add Faction'), findsOneWidget);
    });

    testWidgets('step 3 shows character creation', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to step 3
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Create Character'), findsOneWidget);
    });

    testWidgets('step 4 shows network nodes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to step 4
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Add Network Node'), findsOneWidget);
    });

    testWidgets('step 5 shows scene setup', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Skip to step 5
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('opening scene'), findsOneWidget);
      expect(find.text('Action + Theme'), findsOneWidget);
      expect(find.text('Descriptor + Focus'), findsOneWidget);
    });
  });

  group('Game model - setupWizardCompleted', () {
    test('defaults to false', () {
      final game = Game(name: 'Test');
      expect(game.setupWizardCompleted, isFalse);
    });

    test('serializes to JSON', () {
      final game = Game(name: 'Test', setupWizardCompleted: true);
      final json = game.toJson();
      expect(json['setupWizardCompleted'], isTrue);
    });

    test('deserializes from JSON', () {
      final game = Game(name: 'Test', setupWizardCompleted: true);
      final json = game.toJson();
      final restored = Game.fromJson(json);
      expect(restored.setupWizardCompleted, isTrue);
    });

    test('defaults to false when missing from JSON', () {
      final game = Game(name: 'Test');
      final json = game.toJson();
      json.remove('setupWizardCompleted');
      final restored = Game.fromJson(json);
      expect(restored.setupWizardCompleted, isFalse);
    });
  });
}
