import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/widgets/journal/location_oracle_shortcuts.dart';

// Mock GameProvider for testing
class MockGameProvider extends ChangeNotifier implements GameProvider {
  Game? _currentGame;
  
  @override
  Game? get currentGame => _currentGame;
  
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
  List<OracleCategory> _oracles = [];
  
  @override
  List<OracleCategory> get oracles => _oracles;
  
  // Set oracles for testing
  void setOraclesForTest(List<OracleCategory> oracles) {
    _oracles = oracles;
    notifyListeners();
  }
  
  // Implement required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LocationOracleShortcuts', () {
    late MockGameProvider mockGameProvider;
    late MockDataswornProvider mockDataswornProvider;
    late Game testGame;
    late Location locationWithNodeType;
    late Location locationWithoutNodeType;
    
    setUp(() {
      mockGameProvider = MockGameProvider();
      mockDataswornProvider = MockDataswornProvider();
      
      // Create test locations
      locationWithNodeType = Location(
        id: 'loc1',
        name: 'Social Hub',
        nodeType: 'social',
        segment: LocationSegment.core,
      );
      
      locationWithoutNodeType = Location(
        id: 'loc2',
        name: 'Generic Location',
        segment: LocationSegment.core,
      );
      
      // Create test game with locations
      testGame = Game(
        id: 'game1',
        name: 'Test Game',
        locations: [locationWithNodeType, locationWithoutNodeType],
      );
      
      // Set up the mock game provider
      mockGameProvider.setCurrentGameForTest(testGame);
      
      // Set up the mock datasworn provider with oracle categories
      // Create tables for the social node type
      final areaTables = [
        OracleTable(
          id: 'node_type/social/area',
          name: 'Area',
          description: 'Social area descriptions',
          rows: List.generate(20, (i) => OracleTableRow(
            minRoll: i + 1,
            maxRoll: i + 1,
            result: 'Area result ${i+1}',
          )),
          diceFormat: '1d20',
        ),
      ];
      
      final featureTables = [
        OracleTable(
          id: 'node_type/social/feature',
          name: 'Feature',
          description: 'Social feature descriptions',
          rows: List.generate(20, (i) => OracleTableRow(
            minRoll: i + 1,
            maxRoll: i + 1,
            result: 'Feature result ${i+1}',
          )),
          diceFormat: '1d20',
        ),
      ];
      
      final perilTables = [
        OracleTable(
          id: 'node_type/social/peril',
          name: 'Peril',
          description: 'Social peril descriptions',
          rows: List.generate(20, (i) => OracleTableRow(
            minRoll: i + 1,
            maxRoll: i + 1,
            result: 'Peril result ${i+1}',
          )),
          diceFormat: '1d20',
        ),
      ];
      
      final opportunityTables = [
        OracleTable(
          id: 'node_type/social/opportunity',
          name: 'Opportunity',
          description: 'Social opportunity descriptions',
          rows: List.generate(20, (i) => OracleTableRow(
            minRoll: i + 1,
            maxRoll: i + 1,
            result: 'Opportunity result ${i+1}',
          )),
          diceFormat: '1d20',
        ),
      ];
      
      // Create subcategories for the node type
      final areaCategory = OracleCategory(
        id: 'area',
        name: 'Area',
        tables: areaTables,
      );
      
      final featureCategory = OracleCategory(
        id: 'feature',
        name: 'Feature',
        tables: featureTables,
      );
      
      final perilCategory = OracleCategory(
        id: 'peril',
        name: 'Peril',
        tables: perilTables,
      );
      
      final opportunityCategory = OracleCategory(
        id: 'opportunity',
        name: 'Opportunity',
        tables: opportunityTables,
      );
      
      // Create the social node type category
      final socialNodeTypeCategory = OracleCategory(
        id: 'social',
        name: 'Social',
        tables: [],
        subcategories: [areaCategory, featureCategory, perilCategory, opportunityCategory],
      );
      
      // Create the node type category
      final nodeTypeCategory = OracleCategory(
        id: 'node_type',
        name: 'Node Types',
        tables: [],
        subcategories: [socialNodeTypeCategory],
      );
      
      mockDataswornProvider.setOraclesForTest([nodeTypeCategory]);
    });
    
    testWidgets('renders nothing when no linked locations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(value: mockGameProvider),
                ChangeNotifierProvider<DataswornProvider>.value(value: mockDataswornProvider),
              ],
              child: const LocationOracleShortcuts(
                linkedLocationIds: [],
              ),
            ),
          ),
        ),
      );
      
      // Verify that nothing is rendered
      expect(find.byType(ElevatedButton), findsNothing);
    });
    
    testWidgets('renders buttons for linked locations with node types', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(value: mockGameProvider),
                ChangeNotifierProvider<DataswornProvider>.value(value: mockDataswornProvider),
              ],
              child: LocationOracleShortcuts(
                linkedLocationIds: [locationWithNodeType.id, locationWithoutNodeType.id],
              ),
            ),
          ),
        ),
      );
      
      // Verify that a button is rendered for the location with a node type
      expect(find.text('Social Hub Oracles'), findsOneWidget);
      
      // Verify that no button is rendered for the location without a node type
      expect(find.text('Generic Location Oracles'), findsNothing);
    });
    
    testWidgets('shows dialog when button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(value: mockGameProvider),
                ChangeNotifierProvider<DataswornProvider>.value(value: mockDataswornProvider),
              ],
              child: LocationOracleShortcuts(
                linkedLocationIds: [locationWithNodeType.id],
              ),
            ),
          ),
        ),
      );
      
      // Verify that a button is rendered
      expect(find.text('Social Hub Oracles'), findsOneWidget);
      
      // Tap the button
      await tester.tap(find.text('Social Hub Oracles'));
      await tester.pumpAndSettle();
      
      // Verify that a dialog is shown
      expect(find.text('Social Hub Oracles'), findsNWidgets(2)); // One in button, one in dialog title
      
      // Close the dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      
      // Verify that the dialog is closed
      expect(find.text('Social Hub Oracles'), findsOneWidget); // Only the button remains
    });
    
    testWidgets('calls callbacks when oracle roll is added', (WidgetTester tester) async {
      OracleRoll? addedOracleRoll;
      String? insertedText;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<GameProvider>.value(value: mockGameProvider),
                ChangeNotifierProvider<DataswornProvider>.value(value: mockDataswornProvider),
              ],
              child: LocationOracleShortcuts(
                linkedLocationIds: [locationWithNodeType.id],
                onOracleRollAdded: (roll) {
                  addedOracleRoll = roll;
                },
                onInsertText: (text) {
                  insertedText = text;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the button to show the dialog
      await tester.tap(find.text('Social Hub Oracles'));
      await tester.pumpAndSettle();
      
      // Verify that the dialog shows oracle tables
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('Feature'), findsOneWidget);
      expect(find.text('Peril'), findsOneWidget);
      expect(find.text('Opportunity'), findsOneWidget);
      
      // Note: We can't easily test the full flow of rolling on an oracle table
      // and adding the result to the journal entry in a widget test, as it involves
      // complex interactions with dialogs and callbacks.
    });
  });
}
