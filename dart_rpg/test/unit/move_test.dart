import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/move.dart';

void main() {
  group('Move', () {
    group('hasPlayerChoice', () {
      test('returns true when move has player_choice method', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'player_choice',
              'text': 'Test choice',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                }
              ]
            }
          ],
        );
        
        expect(move.hasPlayerChoice(), isTrue);
      });
      
      test('returns false when move has no player_choice method', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'other_method',
              'text': 'Test condition'
            }
          ],
        );
        
        expect(move.hasPlayerChoice(), isFalse);
      });
      
      test('returns false when move has empty trigger conditions', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [],
        );
        
        expect(move.hasPlayerChoice(), isFalse);
      });
    });
    
    group('getAvailableOptions', () {
      test('returns options from player_choice conditions', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'player_choice',
              'text': 'Option 1',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                }
              ]
            },
            {
              'method': 'player_choice',
              'text': 'Option 2',
              'roll_options': [
                {
                  'using': 'condition_meter',
                  'condition_meter': 'health'
                }
              ]
            }
          ],
        );
        
        final options = move.getAvailableOptions();
        expect(options.length, equals(2));
        
        expect(options[0]['using'], equals('stat'));
        expect(options[0]['stat'], equals('shadow'));
        
        expect(options[1]['using'], equals('condition_meter'));
        expect(options[1]['condition_meter'], equals('health'));
      });
      
      test('returns options from roll options when no player_choice conditions', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          rollOptions: [
            {
              'using': 'stat',
              'stat': 'edge'
            }
          ],
        );
        
        final options = move.getAvailableOptions();
        expect(options.length, equals(1));
        expect(options[0]['using'], equals('stat'));
        expect(options[0]['stat'], equals('edge'));
      });
      
      test('returns stat property when no player_choice or roll options', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          stat: 'iron',
        );
        
        final options = move.getAvailableOptions();
        expect(options.length, equals(1));
        expect(options[0]['using'], equals('stat'));
        expect(options[0]['stat'], equals('iron'));
      });
    });
    
    group('getAvailableStats', () {
      test('returns stats from player_choice conditions', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'player_choice',
              'text': 'Option 1',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                }
              ]
            },
            {
              'method': 'player_choice',
              'text': 'Option 2',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'heart'
                }
              ]
            },
            {
              'method': 'player_choice',
              'text': 'Option 3',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'wits'
                }
              ]
            }
          ],
        );
        
        final stats = move.getAvailableStats();
        expect(stats, containsAll(['shadow', 'heart', 'wits']));
        expect(stats.length, equals(3));
      });
      
      test('returns stats from roll options when no player_choice conditions', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          rollOptions: [
            {
              'using': 'stat',
              'stat': 'edge'
            }
          ],
        );
        
        final stats = move.getAvailableStats();
        expect(stats, contains('edge'));
        expect(stats.length, equals(1));
      });
      
      test('returns stat property when no player_choice or roll options', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          stat: 'iron',
        );
        
        final stats = move.getAvailableStats();
        expect(stats, contains('iron'));
        expect(stats.length, equals(1));
      });
      
      test('returns default stats when no other stats available', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
        );
        
        final stats = move.getAvailableStats();
        expect(stats, containsAll(['Edge', 'Heart', 'Iron', 'Shadow', 'Wits']));
        expect(stats.length, equals(5));
      });
      
      test('parses the Gain Entry move correctly', () {
        // Create a move based on the Gain Entry JSON example
        final move = Move(
          id: 'gain_entry',
          name: 'Gain Entry',
          triggerConditions: [
            {
              'method': 'player_choice',
              'text': 'Find a backdoor of vulnerability to the system',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                }
              ]
            },
            {
              'method': 'player_choice',
              'text': 'Social engineering, faking ID',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'heart'
                }
              ]
            },
            {
              'method': 'player_choice',
              'text': 'Use the system against itself, find a gap',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'wits'
                }
              ]
            }
          ],
        );
        
        expect(move.hasPlayerChoice(), isTrue);
        
        final stats = move.getAvailableStats();
        expect(stats, containsAll(['shadow', 'heart', 'wits']));
        expect(stats.length, equals(3));
        expect(stats, isNot(contains('edge')));
        expect(stats, isNot(contains('iron')));
      });
    });
    
    group('special methods', () {
      test('hasHighestMethod returns true when move has highest method', () {
        final move = Move(
          id: 'endure_harm',
          name: 'Endure Harm',
          triggerConditions: [
            {
              'method': 'highest',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'iron'
                },
                {
                  'using': 'condition_meter',
                  'condition_meter': 'health'
                }
              ]
            }
          ],
        );
        
        expect(move.hasHighestMethod(), isTrue);
        expect(move.hasLowestMethod(), isFalse);
        expect(move.hasSpecialMethod(), isTrue);
        expect(move.getSpecialMethod(), equals('highest'));
      });
      
      test('hasLowestMethod returns true when move has lowest method', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'lowest',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                },
                {
                  'using': 'condition_meter',
                  'condition_meter': 'spirit'
                }
              ]
            }
          ],
        );
        
        expect(move.hasHighestMethod(), isFalse);
        expect(move.hasLowestMethod(), isTrue);
        expect(move.hasSpecialMethod(), isTrue);
        expect(move.getSpecialMethod(), equals('lowest'));
      });
      
      test('getAvailableOptions handles highest method correctly', () {
        final move = Move(
          id: 'endure_harm',
          name: 'Endure Harm',
          triggerConditions: [
            {
              'method': 'highest',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'iron'
                },
                {
                  'using': 'condition_meter',
                  'condition_meter': 'health'
                }
              ]
            }
          ],
        );
        
        final options = move.getAvailableOptions();
        expect(options.length, equals(2));
        
        // Options should have the method field added
        expect(options[0]['method'], equals('highest'));
        expect(options[1]['method'], equals('highest'));
        
        expect(options[0]['using'], equals('stat'));
        expect(options[0]['stat'], equals('iron'));
        
        expect(options[1]['using'], equals('condition_meter'));
        expect(options[1]['condition_meter'], equals('health'));
      });
      
      test('getAvailableOptions handles lowest method correctly', () {
        final move = Move(
          id: 'test_move',
          name: 'Test Move',
          triggerConditions: [
            {
              'method': 'lowest',
              'roll_options': [
                {
                  'using': 'stat',
                  'stat': 'shadow'
                },
                {
                  'using': 'condition_meter',
                  'condition_meter': 'spirit'
                }
              ]
            }
          ],
        );
        
        final options = move.getAvailableOptions();
        expect(options.length, equals(2));
        
        // Options should have the method field added
        expect(options[0]['method'], equals('lowest'));
        expect(options[1]['method'], equals('lowest'));
        
        expect(options[0]['using'], equals('stat'));
        expect(options[0]['stat'], equals('shadow'));
        
        expect(options[1]['using'], equals('condition_meter'));
        expect(options[1]['condition_meter'], equals('spirit'));
      });
    });
  });
}
