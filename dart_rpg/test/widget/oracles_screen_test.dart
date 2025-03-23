import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/screens/oracles_screen.dart';

void main() {
  // Create test oracle data
  List<OracleCategory> createTestOracles() {
    return [
      OracleCategory(
        id: 'category-1',
        name: 'Test Category 1',
        description: 'Test description 1',
        tables: [
          OracleTable(
            id: 'table-1-1',
            name: 'Test Table 1-1',
            description: 'Test description 1-1',
            rows: [
              OracleTableRow(minRoll: 1, maxRoll: 50, result: 'Result 1'),
              OracleTableRow(minRoll: 51, maxRoll: 100, result: 'Result 2'),
            ],
            diceFormat: '1d100',
          ),
          OracleTable(
            id: 'table-1-2',
            name: 'Test Table 1-2',
            description: 'Test description 1-2',
            rows: [
              OracleTableRow(minRoll: 1, maxRoll: 3, result: 'Result A'),
              OracleTableRow(minRoll: 4, maxRoll: 6, result: 'Result B'),
            ],
            diceFormat: '1d6',
          ),
        ],
      ),
      OracleCategory(
        id: 'category-2',
        name: 'Test Category 2',
        description: 'Test description 2',
        tables: [
          OracleTable(
            id: 'table-2-1',
            name: 'Test Table 2-1',
            description: 'Test description 2-1',
            rows: [
              OracleTableRow(minRoll: 1, maxRoll: 10, result: 'Result X'),
              OracleTableRow(minRoll: 11, maxRoll: 20, result: 'Result Y'),
            ],
            diceFormat: '1d20',
          ),
        ],
      ),
    ];
  }
  
  group('OracleCategoryScreen', () {
    testWidgets('displays all tables in the category', (WidgetTester tester) async {
      // Setup
      final testCategory = createTestOracles()[0];
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: OracleCategoryScreen(category: testCategory),
        ),
      );
      
      // Verify
      expect(find.text('Test Category 1'), findsOneWidget); // In AppBar
      expect(find.text('Test Table 1-1'), findsOneWidget);
      expect(find.text('Test Table 1-2'), findsOneWidget);
    });
  });
  
  group('OracleTableScreen', () {
    testWidgets('displays table details correctly', (WidgetTester tester) async {
      // Setup
      final testTable = createTestOracles()[0].tables[0];
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: OracleTableScreen(table: testTable),
        ),
      );
      
      // Verify
      expect(find.text('Test Table 1-1'), findsOneWidget); // In AppBar
      expect(find.text('Test description 1-1'), findsOneWidget);
      expect(find.text('1-50'), findsOneWidget);
      expect(find.text('Result 1'), findsOneWidget);
      expect(find.text('51-100'), findsOneWidget);
      expect(find.text('Result 2'), findsOneWidget);
    });
  });
}
