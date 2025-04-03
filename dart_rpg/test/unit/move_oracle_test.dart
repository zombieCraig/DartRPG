import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/move.dart';
import 'package:dart_rpg/models/move_oracle.dart';

void main() {
  group('MoveOracle', () {
    test('should parse from JSON correctly', () {
      // Sample oracle JSON from the ask_the_oracle move
      final oracleJson = {
        'name': 'Almost Certain',
        'match': {
          'text': 'On a match, envision an extreme result or twist.'
        },
        'oracle_type': 'column_text',
        'type': 'oracle_rollable',
        'rows': [
          {
            'roll': {
              'min': 1,
              'max': 90
            },
            'text': 'Yes',
            '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.0'
          },
          {
            'roll': {
              'min': 91,
              'max': 100
            },
            'text': 'No',
            '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.1'
          }
        ],
        'dice': '1d100',
        '_id': 'move.oracle_rollable:fe_runners/fate/ask_the_oracle.almost_certain'
      };

      final moveOracle = MoveOracle.fromJson('almost_certain', oracleJson);

      // Verify the parsed data
      expect(moveOracle.key, equals('almost_certain'));
      expect(moveOracle.name, equals('Almost Certain'));
      expect(moveOracle.matchText, equals('On a match, envision an extreme result or twist.'));
      expect(moveOracle.oracleType, equals('column_text'));
      expect(moveOracle.dice, equals('1d100'));
      expect(moveOracle.id, equals('move.oracle_rollable:fe_runners/fate/ask_the_oracle.almost_certain'));
      
      // Verify the rows
      expect(moveOracle.rows.length, equals(2));
      expect(moveOracle.rows[0].minRoll, equals(1));
      expect(moveOracle.rows[0].maxRoll, equals(90));
      expect(moveOracle.rows[0].result, equals('Yes'));
      expect(moveOracle.rows[1].minRoll, equals(91));
      expect(moveOracle.rows[1].maxRoll, equals(100));
      expect(moveOracle.rows[1].result, equals('No'));
    });

    test('should convert to OracleTable correctly', () {
      // Sample oracle JSON from the ask_the_oracle move
      final oracleJson = {
        'name': 'Almost Certain',
        'match': {
          'text': 'On a match, envision an extreme result or twist.'
        },
        'oracle_type': 'column_text',
        'type': 'oracle_rollable',
        'rows': [
          {
            'roll': {
              'min': 1,
              'max': 90
            },
            'text': 'Yes',
            '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.0'
          },
          {
            'roll': {
              'min': 91,
              'max': 100
            },
            'text': 'No',
            '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.1'
          }
        ],
        'dice': '1d100',
        '_id': 'move.oracle_rollable:fe_runners/fate/ask_the_oracle.almost_certain'
      };

      final moveOracle = MoveOracle.fromJson('almost_certain', oracleJson);
      final oracleTable = moveOracle.toOracleTable();

      // Verify the converted OracleTable
      expect(oracleTable.id, equals('move.oracle_rollable:fe_runners/fate/ask_the_oracle.almost_certain'));
      expect(oracleTable.name, equals('Almost Certain'));
      expect(oracleTable.description, equals('On a match, envision an extreme result or twist.'));
      expect(oracleTable.diceFormat, equals('1d100'));
      expect(oracleTable.oracleType, equals('column_text'));
      
      // Verify the rows
      expect(oracleTable.rows.length, equals(2));
      expect(oracleTable.rows[0].minRoll, equals(1));
      expect(oracleTable.rows[0].maxRoll, equals(90));
      expect(oracleTable.rows[0].result, equals('Yes'));
      expect(oracleTable.rows[1].minRoll, equals(91));
      expect(oracleTable.rows[1].maxRoll, equals(100));
      expect(oracleTable.rows[1].result, equals('No'));
    });
  });

  group('Move with embedded oracles', () {
    test('should parse oracles from JSON correctly', () {
      // Sample move JSON with embedded oracles
      final moveJson = {
        'id': 'move:fe_runners/fate/ask_the_oracle',
        'name': 'Ask the Oracle',
        'description': 'When you seek to resolve questions, reveal details, discover locations, determine how other characters respond, or trigger encounters or events, you may...',
        'moveCategory': 'fate',
        'oracles': {
          'almost_certain': {
            'name': 'Almost Certain',
            'match': {
              'text': 'On a match, envision an extreme result or twist.'
            },
            'oracle_type': 'column_text',
            'type': 'oracle_rollable',
            'rows': [
              {
                'roll': {
                  'min': 1,
                  'max': 90
                },
                'text': 'Yes',
                '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.0'
              },
              {
                'roll': {
                  'min': 91,
                  'max': 100
                },
                'text': 'No',
                '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.almost_certain.1'
              }
            ],
            'dice': '1d100',
            '_id': 'move.oracle_rollable:fe_runners/fate/ask_the_oracle.almost_certain'
          },
          'likely': {
            'name': 'Likely',
            'match': {
              'text': 'On a match, envision an extreme result or twist.'
            },
            'oracle_type': 'column_text',
            'type': 'oracle_rollable',
            'rows': [
              {
                'roll': {
                  'min': 1,
                  'max': 75
                },
                'text': 'Yes',
                '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.likely.0'
              },
              {
                'roll': {
                  'min': 76,
                  'max': 100
                },
                'text': 'No',
                '_id': 'move.oracle_rollable.row:fe_runners/fate/ask_the_oracle.likely.1'
              }
            ],
            'dice': '1d100',
            '_id': 'move.oracle_rollable:fe_runners/fate/ask_the_oracle.likely'
          }
        }
      };

      final move = Move.fromJson(moveJson);

      // Verify the move has oracles
      expect(move.hasEmbeddedOracles, isTrue);
      expect(move.oracles.length, equals(2));
      
      // Verify the oracle keys
      expect(move.oracles.keys.contains('almost_certain'), isTrue);
      expect(move.oracles.keys.contains('likely'), isTrue);
      
      // Verify the oracle properties
      final almostCertainOracle = move.oracles['almost_certain']!;
      expect(almostCertainOracle.name, equals('Almost Certain'));
      expect(almostCertainOracle.matchText, equals('On a match, envision an extreme result or twist.'));
      expect(almostCertainOracle.rows.length, equals(2));
      
      final likelyOracle = move.oracles['likely']!;
      expect(likelyOracle.name, equals('Likely'));
      expect(likelyOracle.matchText, equals('On a match, envision an extreme result or twist.'));
      expect(likelyOracle.rows.length, equals(2));
    });
  });
}
