import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/oracle.dart';

void main() {
  group('OracleTable.fromDatasworn with table_text2', () {
    test('should parse table_text2 oracle type correctly', () {
      // Create a sample JSON for a table_text2 oracle
      final json = {
        'name': 'Faction Type',
        'oracle_type': 'table_text2',
        'type': 'oracle_rollable',
        'column_labels': {
          'roll': 'Roll',
          'text': 'Result',
          'text2': 'Summary'
        },
        'rows': [
          {
            'roll': {
              'min': 1,
              'max': 40
            },
            'text': 'Corporate Faction',
            'text2': 'Corporate Conglomerate',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.0'
          },
          {
            'roll': {
              'min': 41,
              'max': 70
            },
            'text': 'Political Faction',
            'text2': 'Political party or government group',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.1'
          },
          {
            'roll': {
              'min': 71,
              'max': 100
            },
            'text': 'Underground Guild',
            'text2': 'Specialist or fringe groups',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.2'
          }
        ],
        'dice': '1d100',
        '_id': 'oracle_rollable:fe_runners/faction/type'
      };

      // Parse the JSON into an OracleTable
      final table = OracleTable.fromDatasworn(json, 'fe_runners/faction/type');

      // Verify the table properties
      expect(table.id, equals('fe_runners/faction/type'));
      expect(table.name, equals('Faction Type'));
      expect(table.diceFormat, equals('1d100'));
      expect(table.oracleType, equals('table_text2'));
      expect(table.text2Label, equals('Summary'));

      // Verify the rows
      expect(table.rows.length, equals(3));
      
      // Check the first row
      expect(table.rows[0].minRoll, equals(1));
      expect(table.rows[0].maxRoll, equals(40));
      expect(table.rows[0].result, equals('Corporate Faction'));
      expect(table.rows[0].text2, equals('Corporate Conglomerate'));
      
      // Check the second row
      expect(table.rows[1].minRoll, equals(41));
      expect(table.rows[1].maxRoll, equals(70));
      expect(table.rows[1].result, equals('Political Faction'));
      expect(table.rows[1].text2, equals('Political party or government group'));
      
      // Check the third row
      expect(table.rows[2].minRoll, equals(71));
      expect(table.rows[2].maxRoll, equals(100));
      expect(table.rows[2].result, equals('Underground Guild'));
      expect(table.rows[2].text2, equals('Specialist or fringe groups'));
    });

    test('getResult should return the correct result for a roll', () {
      // Create a sample JSON for a table_text2 oracle
      final json = {
        'name': 'Faction Type',
        'oracle_type': 'table_text2',
        'type': 'oracle_rollable',
        'column_labels': {
          'roll': 'Roll',
          'text': 'Result',
          'text2': 'Summary'
        },
        'rows': [
          {
            'roll': {
              'min': 1,
              'max': 40
            },
            'text': 'Corporate Faction',
            'text2': 'Corporate Conglomerate',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.0'
          },
          {
            'roll': {
              'min': 41,
              'max': 70
            },
            'text': 'Political Faction',
            'text2': 'Political party or government group',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.1'
          },
          {
            'roll': {
              'min': 71,
              'max': 100
            },
            'text': 'Underground Guild',
            'text2': 'Specialist or fringe groups',
            '_id': 'oracle_rollable.row:fe_runners/faction/type.2'
          }
        ],
        'dice': '1d100',
        '_id': 'oracle_rollable:fe_runners/faction/type'
      };

      // Parse the JSON into an OracleTable
      final table = OracleTable.fromDatasworn(json, 'fe_runners/faction/type');

      // Test getResult for different rolls
      expect(table.getResult(1), equals('Corporate Faction'));
      expect(table.getResult(40), equals('Corporate Faction'));
      expect(table.getResult(41), equals('Political Faction'));
      expect(table.getResult(70), equals('Political Faction'));
      expect(table.getResult(71), equals('Underground Guild'));
      expect(table.getResult(100), equals('Underground Guild'));
    });
  });
}
