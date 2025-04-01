import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/journal_entry.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/utils/datasworn_link_parser.dart';
import 'package:dart_rpg/utils/oracle_reference_processor.dart';

void main() {
  group('OracleReferenceProcessor', () {
    late DataswornProvider mockDataswornProvider;
    
    setUp(() {
      // Create a mock DataswornProvider
      mockDataswornProvider = MockDataswornProvider();
    });
    
    test('processOracleReferences should process simple oracle references', () async {
      // Arrange
      const text = 'This is a test with an [Action](oracle_rollable:fe_runners/core/action) reference.';
      
      // Act
      final result = await OracleReferenceProcessor.processOracleReferences(
        text,
        mockDataswornProvider,
      );
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['processedText'], isA<String>());
      expect(result['rolls'], isA<List<OracleRoll>>());
      expect(result['rolls'], hasLength(1));
      expect(result['processedText'], contains('Hack'));
      expect(result['processedText'], isNot(contains('[Action](oracle_rollable:fe_runners/core/action)')));
    });
    
    test('processOracleReferences should process nested oracle references', () async {
      // Arrange
      const text = 'This is a test with a nested [Action + Theme](oracle_rollable:fe_runners/social/character_goals) reference.';
      
      // Act
      final result = await OracleReferenceProcessor.processOracleReferences(
        text,
        mockDataswornProvider,
      );
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['processedText'], isA<String>());
      expect(result['rolls'], isA<List<OracleRoll>>());
      expect(result['rolls'].length, greaterThan(1)); // Should have multiple rolls
      expect(result['processedText'], contains('Hack')); // From the action oracle
      expect(result['processedText'], contains('Security')); // From the theme oracle
      expect(result['processedText'], isNot(contains('[Action + Theme](oracle_rollable:fe_runners/social/character_goals)')));
    });
    
    test('processOracleReferences should handle datasworn: prefix', () async {
      // Arrange
      const text = 'This is a test with a [Action](datasworn:oracle_rollable:fe_runners/core/action) reference.';
      
      // Act
      final result = await OracleReferenceProcessor.processOracleReferences(
        text,
        mockDataswornProvider,
      );
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['processedText'], isA<String>());
      expect(result['rolls'], isA<List<OracleRoll>>());
      expect(result['rolls'], hasLength(1));
      expect(result['processedText'], contains('Hack'));
      expect(result['processedText'], isNot(contains('[Action](datasworn:oracle_rollable:fe_runners/core/action)')));
    });
    
    test('getOracleRollsForJournalEntry should return processed text and rolls', () async {
      // Arrange
      const text = 'This is a test with an [Action](oracle_rollable:fe_runners/core/action) and [Theme](oracle_rollable:fe_runners/core/theme) reference.';
      
      // Act
      final result = await OracleReferenceProcessor.getOracleRollsForJournalEntry(
        text,
        mockDataswornProvider,
      );
      
      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['processedText'], isA<String>());
      expect(result['rolls'], isA<List<OracleRoll>>());
      expect(result['rolls'], hasLength(2));
      expect(result['processedText'], contains('Hack')); // From the action oracle
      expect(result['processedText'], contains('Security')); // From the theme oracle
    });
  });
}

/// A mock DataswornProvider for testing
class MockDataswornProvider extends DataswornProvider {
  @override
  List<OracleCategory> get oracles => [
    OracleCategory(
      id: 'fe_runners/core',
      name: 'Core',
      tables: [
        OracleTable(
          id: 'fe_runners/core/action',
          name: 'Action',
          diceFormat: '1d6',
          rows: [
            OracleTableRow(minRoll: 1, maxRoll: 6, result: 'Hack'),
          ],
        ),
        OracleTable(
          id: 'fe_runners/core/theme',
          name: 'Theme',
          diceFormat: '1d6',
          rows: [
            OracleTableRow(minRoll: 1, maxRoll: 6, result: 'Security'),
          ],
        ),
      ],
    ),
    OracleCategory(
      id: 'fe_runners/social',
      name: 'Social',
      tables: [
        OracleTable(
          id: 'fe_runners/social/character_goals',
          name: 'Character Goals',
          diceFormat: '1d100',
          rows: [
            OracleTableRow(
              minRoll: 1, 
              maxRoll: 100, 
              result: '[Action](oracle_rollable:fe_runners/core/action) + [Theme](oracle_rollable:fe_runners/core/theme)',
            ),
          ],
        ),
      ],
    ),
  ];
  
  @override
  OracleTable? findOracleById(String id) {
    for (final category in oracles) {
      for (final table in category.tables) {
        if (table.id == id) {
          return table;
        }
      }
    }
    return null;
  }
}
