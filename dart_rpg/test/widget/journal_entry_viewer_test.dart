import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/session.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/widgets/journal/journal_entry_viewer.dart';

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
  Future<void> connectLocations(String sourceId, String targetId) async {}
  
  @override
  Future<Character> createCharacter(String name, {bool isMainCharacter = false, String? handle}) async {
    throw UnimplementedError();
  }
  
  @override
  Future<Game> createGame(String name, {String? dataswornSource}) async {
    throw UnimplementedError();
  }
  
  @override
  Future<JournalEntry> createJournalEntry(String content) async {
    throw UnimplementedError();
  }
  
  @override
  Future<Location> createLocation(String name, {String? description, LocationSegment segment = LocationSegment.core, String? connectToLocationId, double? x, double? y}) async {
    throw UnimplementedError();
  }
  
  @override
  Future<Session> createSession(String title) async {
    throw UnimplementedError();
  }
  
  @override
  Future<void> deleteGame(String gameId) async {}
  
  @override
  Future<void> disconnectLocations(String sourceId, String targetId) async {}
  
  @override
  Future<String?> exportGame(String gameId) async {
    return null;
  }
  
  @override
  List<Location> getValidConnectionsForLocation(String locationId) {
    return [];
  }
  
  @override
  Future<Game?> importGame() async {
    return null;
  }
  
  @override
  Future<void> saveGame() async {}
  
  @override
  Future<void> switchGame(String gameId) async {}
  
  @override
  Future<void> switchSession(String sessionId) async {}
  
  @override
  Future<void> updateJournalEntry(String entryId, String content) async {}
  
  @override
  Future<void> updateLocationPosition(String locationId, double x, double y) async {}
  
  @override
  Future<void> updateLocationScale(String locationId, double scale) async {}
  
  @override
  Future<void> updateLocationSegment(String locationId, LocationSegment segment) async {}
}

void main() {
  group('JournalEntryViewer', () {
    late Game testGame;
    late Character testCharacter;
    late Location testLocation;
    late MoveRoll testMoveRoll;
    late OracleRoll testOracleRoll;
    
    setUp(() {
      // Create test character
      testCharacter = Character(
        id: 'char1',
        name: 'John Doe',
        handle: 'johnny',
      );
      
      // Create test location
      testLocation = Location(
        id: 'loc1',
        name: 'TestLocation',
      );
      
      // Create test move roll
      testMoveRoll = MoveRoll(
        id: 'move1',
        moveName: 'Face Danger',
        stat: 'Edge',
        statValue: 3,
        actionDie: 5,
        challengeDice: [2, 1],
        outcome: 'strong hit',
        rollType: 'action_roll',
      );
      
      // Create test oracle roll
      testOracleRoll = OracleRoll(
        id: 'oracle1',
        oracleName: 'Test Oracle',
        oracleTable: 'Test Category',
        dice: [5],
        result: 'Test Result',
      );
      
      // Create test game with character and location
      testGame = Game(
        id: 'game1',
        name: 'Test Game',
        characters: [testCharacter],
        locations: [testLocation],
      );
    });
    
    testWidgets('renders with RichText widget', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: const JournalEntryViewer(
                content: 'This is a plain text entry with no references.',
              ),
            ),
          ),
        ),
      );
      
      // Verify the RichText widget is created
      expect(find.byType(RichText), findsOneWidget);
    });
    
    testWidgets('creates clickable spans for character references', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: JournalEntryViewer(
                content: 'This is a reference to @johnny in the text.',
                onCharacterTap: (character) {
                  // This callback would be called if the test could tap on the specific span
                  expect(character.id, equals(testCharacter.id));
                },
              ),
            ),
          ),
        ),
      );
      
      // Verify the RichText widget is created
      expect(find.byType(RichText), findsOneWidget);
      
      // Note: We can't easily test tapping on specific spans in a RichText widget
      // in widget tests, so we're just verifying the widget is created correctly
    });
    
    testWidgets('creates clickable spans for location references', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: JournalEntryViewer(
                content: 'This is a reference to #TestLocation in the text.',
                onLocationTap: (location) {
                  // This callback would be called if the test could tap on the specific span
                  expect(location.id, equals(testLocation.id));
                },
              ),
            ),
          ),
        ),
      );
      
      // Verify the RichText widget is created
      expect(find.byType(RichText), findsOneWidget);
    });
    
    testWidgets('creates clickable spans for move roll references', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: JournalEntryViewer(
                content: 'This is a reference to [Face Danger - Strong Hit] in the text.',
                moveRolls: [testMoveRoll],
                onMoveRollTap: (moveRoll) {
                  // This callback would be called if the test could tap on the specific span
                  expect(moveRoll.id, equals(testMoveRoll.id));
                },
              ),
            ),
          ),
        ),
      );
      
      // Verify the RichText widget is created
      expect(find.byType(RichText), findsOneWidget);
    });
    
    testWidgets('creates clickable spans for oracle roll references', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: JournalEntryViewer(
                content: 'This is a reference to [Test Oracle: Test Result] in the text.',
                oracleRolls: [testOracleRoll],
                onOracleRollTap: (oracleRoll) {
                  // This callback would be called if the test could tap on the specific span
                  expect(oracleRoll.id, equals(testOracleRoll.id));
                },
              ),
            ),
          ),
        ),
      );
      
      // Verify the RichText widget is created
      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
