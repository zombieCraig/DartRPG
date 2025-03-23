import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/session.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/widgets/journal/linked_items_summary.dart';

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
  group('LinkedItemsSummary', () {
    late Game testGame;
    late Character testCharacter;
    late Location testLocation;
    late JournalEntry testEntry;
    
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
        name: 'Test Location',
      );
      
      // Create test game with character and location
      testGame = Game(
        id: 'game1',
        name: 'Test Game',
        characters: [testCharacter],
        locations: [testLocation],
      );
      
      // Create test journal entry with linked items
      testEntry = JournalEntry(
        content: 'Test content with @johnny and #Test Location',
        linkedCharacterIds: [testCharacter.id],
        linkedLocationIds: [testLocation.id],
      );
      
      // Add a move roll
      testEntry.attachMoveRoll(MoveRoll(
        moveName: 'Face Danger',
        stat: 'Edge',
        statValue: 3,
        actionDie: 5,
        challengeDice: [2, 1],
        outcome: 'strong hit',
        rollType: 'action_roll',
      ));
      
      // Add an oracle roll
      testEntry.attachOracleRoll(OracleRoll(
        oracleName: 'Test Oracle',
        oracleTable: 'Test Category',
        dice: [5],
        result: 'Test Result',
      ));
    });
    
    testWidgets('renders correctly when collapsed', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
              ),
            ),
          ),
        ),
      );
      
      // Verify the header is displayed
      expect(find.text('Linked Items'), findsOneWidget);
      expect(find.text('4 items'), findsOneWidget);
      
      // Verify the content is not displayed when collapsed
      expect(find.text('Characters'), findsNothing);
      expect(find.text('Locations'), findsNothing);
      expect(find.text('Move Outcomes'), findsNothing);
      expect(find.text('Oracle Rolls'), findsNothing);
    });
    
    testWidgets('expands and shows content when tapped', (WidgetTester tester) async {
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
              ),
            ),
          ),
        ),
      );
      
      // Tap the header to expand
      await tester.tap(find.text('Linked Items'));
      await tester.pump();
      
      // Verify the content is displayed when expanded
      expect(find.text('Characters'), findsOneWidget);
      expect(find.text('johnny'), findsOneWidget);
      expect(find.text('Locations'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('Move Outcomes'), findsOneWidget);
      expect(find.text('Face Danger'), findsOneWidget);
      expect(find.text('Oracle Rolls'), findsOneWidget);
      expect(find.text('Test Oracle'), findsOneWidget);
    });
    
    testWidgets('calls onCharacterTap when character chip is tapped', (WidgetTester tester) async {
      String? tappedCharacterId;
      
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget with callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
                onCharacterTap: (id) {
                  tappedCharacterId = id;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the header to expand
      await tester.tap(find.text('Linked Items'));
      await tester.pump();
      
      // Tap the character chip
      await tester.tap(find.text('johnny'));
      await tester.pump();
      
      // Verify the callback was called with the correct ID
      expect(tappedCharacterId, equals(testCharacter.id));
    });
    
    testWidgets('calls onLocationTap when location chip is tapped', (WidgetTester tester) async {
      String? tappedLocationId;
      
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget with callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
                onLocationTap: (id) {
                  tappedLocationId = id;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the header to expand
      await tester.tap(find.text('Linked Items'));
      await tester.pump();
      
      // Tap the location chip
      await tester.tap(find.text('Test Location'));
      await tester.pump();
      
      // Verify the callback was called with the correct ID
      expect(tappedLocationId, equals(testLocation.id));
    });
    
    testWidgets('calls onMoveRollTap when move roll is tapped', (WidgetTester tester) async {
      MoveRoll? tappedMoveRoll;
      
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget with callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
                onMoveRollTap: (moveRoll) {
                  tappedMoveRoll = moveRoll;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the header to expand
      await tester.tap(find.text('Linked Items'));
      await tester.pump();
      
      // Tap the move roll
      await tester.tap(find.text('Face Danger'));
      await tester.pump();
      
      // Verify the callback was called with a move roll
      expect(tappedMoveRoll, isNotNull);
      expect(tappedMoveRoll!.moveName, equals('Face Danger'));
    });
    
    testWidgets('calls onOracleRollTap when oracle roll is tapped', (WidgetTester tester) async {
      OracleRoll? tappedOracleRoll;
      
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget with callback
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: testEntry,
                onOracleRollTap: (oracleRoll) {
                  tappedOracleRoll = oracleRoll;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the header to expand
      await tester.tap(find.text('Linked Items'));
      await tester.pump();
      
      // Tap the oracle roll
      await tester.tap(find.text('Test Oracle'));
      await tester.pump();
      
      // Verify the callback was called with an oracle roll
      expect(tappedOracleRoll, isNotNull);
      expect(tappedOracleRoll!.oracleName, equals('Test Oracle'));
    });
    
    testWidgets('does not render when there are no linked items', (WidgetTester tester) async {
      // Create an empty journal entry
      final emptyEntry = JournalEntry(
        content: 'Test content with no links',
      );
      
      // Create a mock provider
      final mockProvider = MockGameProvider();
      mockProvider.setCurrentGameForTest(testGame);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameProvider>.value(
              value: mockProvider,
              child: LinkedItemsSummary(
                journalEntry: emptyEntry,
              ),
            ),
          ),
        ),
      );
      
      // Verify the widget is not rendered
      expect(find.text('Linked Items'), findsNothing);
    });
  });
}
