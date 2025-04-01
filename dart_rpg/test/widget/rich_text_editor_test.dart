import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/widgets/journal/rich_text_editor.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/session.dart';
import 'package:dart_rpg/models/move.dart';
import 'package:dart_rpg/models/character.dart'; // For Asset class

// Mock GameProvider for testing
class MockGameProvider extends ChangeNotifier implements GameProvider {
  Game? _currentGame;
  
  @override
  Game? get currentGame => _currentGame;
  
  // Other required overrides with minimal implementations
  @override
  List<Game> get games => [];
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  Session? get currentSession => null;
  
  // Set the current game for testing
  void setCurrentGameForTest(Game game) {
    _currentGame = game;
    notifyListeners();
  }
  
  // Implement required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Mock DataswornProvider for testing
class MockDataswornProvider extends ChangeNotifier implements DataswornProvider {
  final List<OracleCategory> _oracles = [];
  
  @override
  List<OracleCategory> get oracles => _oracles;
  
  @override
  bool get isLoading => false;
  
  @override
  String? get error => null;
  
  @override
  List<Move> get moves => [];
  
  @override
  List<Asset> get assets => [];
  
  @override
  String? get currentSource => null;
  
  // Add test oracles
  void addTestOracles(List<OracleCategory> categories) {
    _oracles.clear();
    _oracles.addAll(categories);
    notifyListeners();
  }
  
  // Implement required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('RichTextEditor', () {
    late MockGameProvider mockGameProvider;
    late MockDataswornProvider mockDataswornProvider;
    
    setUp(() {
      mockGameProvider = MockGameProvider();
      mockDataswornProvider = MockDataswornProvider();
      
      // Create a test game
      final testGame = Game(
        id: 'game1',
        name: 'Test Game',
      );
      
      mockGameProvider.setCurrentGameForTest(testGame);
      
      // Create test oracle categories
      final testOracleTable = OracleTable(
        id: 'table1',
        name: 'Test Oracle Table',
        rows: [
          OracleTableRow(
            minRoll: 1,
            maxRoll: 100,
            result: 'Test Oracle Result',
          ),
        ],
        diceFormat: '1d100',
      );
      
      final testOracleCategory = OracleCategory(
        id: 'category1',
        name: 'Test Oracle Category',
        tables: [testOracleTable],
      );
      
      mockDataswornProvider.addTestOracles([testOracleCategory]);
    });
    
    testWidgets('renders with toolbar buttons', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(
                  value: mockGameProvider,
                ),
                ChangeNotifierProvider<DataswornProvider>.value(
                  value: mockDataswornProvider,
                ),
              ],
              child: RichTextEditor(
                initialText: '',
                onChanged: (_, __) {},
              ),
            ),
          ),
        ),
      );
      
      // Verify the toolbar buttons are rendered
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.title), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      
      // Verify the custom toolbar buttons are rendered
      expect(find.byIcon(Icons.person), findsOneWidget); // Character button
      expect(find.byIcon(Icons.place), findsOneWidget); // Location button
      expect(find.byIcon(Icons.image), findsOneWidget); // Image button
      expect(find.byIcon(Icons.sports_martial_arts), findsOneWidget); // Move button
      expect(find.byIcon(Icons.casino), findsOneWidget); // Oracle button
      expect(find.byIcon(Icons.task_alt), findsOneWidget); // Quest button
    });
    
    testWidgets('Oracle button triggers onOracleRequested callback', (WidgetTester tester) async {
      bool oracleRequested = false;
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(
                  value: mockGameProvider,
                ),
                ChangeNotifierProvider<DataswornProvider>.value(
                  value: mockDataswornProvider,
                ),
              ],
              child: RichTextEditor(
                initialText: '',
                onChanged: (_, __) {},
                onOracleRequested: () {
                  oracleRequested = true;
                },
              ),
            ),
          ),
        ),
      );
      
      // Find the Oracle button
      final oracleButton = find.byIcon(Icons.casino);
      expect(oracleButton, findsOneWidget);
      
      // Tap the Oracle button
      await tester.tap(oracleButton);
      await tester.pump();
      
      // Verify the callback was triggered
      expect(oracleRequested, isTrue);
    });
    
    testWidgets('Quest button triggers onQuestRequested callback', (WidgetTester tester) async {
      bool questRequested = false;
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(
                  value: mockGameProvider,
                ),
                ChangeNotifierProvider<DataswornProvider>.value(
                  value: mockDataswornProvider,
                ),
              ],
              child: RichTextEditor(
                initialText: '',
                onChanged: (_, __) {},
                onQuestRequested: () {
                  questRequested = true;
                },
              ),
            ),
          ),
        ),
      );
      
      // Find the Quest button
      final questButton = find.byIcon(Icons.task_alt);
      expect(questButton, findsOneWidget);
      
      // Tap the Quest button
      await tester.tap(questButton);
      await tester.pump();
      
      // Verify the callback was triggered
      expect(questRequested, isTrue);
    });
    
    testWidgets('Move button triggers onMoveRequested callback', (WidgetTester tester) async {
      bool moveRequested = false;
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(
                  value: mockGameProvider,
                ),
                ChangeNotifierProvider<DataswornProvider>.value(
                  value: mockDataswornProvider,
                ),
              ],
              child: RichTextEditor(
                initialText: '',
                onChanged: (_, __) {},
                onMoveRequested: () {
                  moveRequested = true;
                },
              ),
            ),
          ),
        ),
      );
      
      // Find the Move button
      final moveButton = find.byIcon(Icons.sports_martial_arts);
      expect(moveButton, findsOneWidget);
      
      // Tap the Move button
      await tester.tap(moveButton);
      await tester.pump();
      
      // Verify the callback was triggered
      expect(moveRequested, isTrue);
    });
  });
}
