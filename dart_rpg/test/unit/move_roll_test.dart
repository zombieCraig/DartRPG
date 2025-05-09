import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/journal_entry.dart';

void main() {
  group('MoveRoll', () {
    group('getFormattedText', () {
      test('formats action roll with strong hit correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          stat: 'Edge',
          statValue: 3,
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
          rollType: 'action_roll',
        );
        
        expect(moveRoll.getFormattedText(), equals('[Face Danger - Strong Hit]'));
      });
      
      test('formats action roll with weak hit correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'Secure an Advantage',
          stat: 'Wits',
          statValue: 2,
          actionDie: 3,
          challengeDice: [3, 2],
          outcome: 'weak hit',
          rollType: 'action_roll',
        );
        
        expect(moveRoll.getFormattedText(), equals('[Secure an Advantage - Weak Hit]'));
      });
      
      test('formats action roll with miss correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'Strike',
          stat: 'Iron',
          statValue: 2,
          actionDie: 1,
          challengeDice: [5, 6],
          outcome: 'miss',
          rollType: 'action_roll',
        );
        
        expect(moveRoll.getFormattedText(), equals('[Strike - Miss]'));
      });
      
      test('formats progress roll correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'Fulfill Your Vow',
          actionDie: 4,
          challengeDice: [3, 2],
          outcome: 'strong hit',
          rollType: 'progress_roll',
          progressValue: 8,
        );
        
        expect(moveRoll.getFormattedText(), equals('[Fulfill Your Vow - Strong Hit]'));
      });
      
      test('formats no-roll move correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'End the Session',
          actionDie: 0,
          challengeDice: [0, 0],
          outcome: 'no outcome',
          rollType: 'no_roll',
        );
        
        expect(moveRoll.getFormattedText(), equals('[End the Session]'));
      });
      
      test('handles multi-word outcomes correctly', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          stat: 'Edge',
          statValue: 3,
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit with a match',
          rollType: 'action_roll',
          isMatch: true,
        );
        
        expect(moveRoll.getFormattedText(), equals('[Face Danger - Strong Hit With A Match]'));
      });
    });
    
    group('serialization', () {
      test('correctly serializes and deserializes isMatch property', () {
        final originalMoveRoll = MoveRoll(
          moveName: 'Face Danger',
          stat: 'Edge',
          statValue: 3,
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit with a match',
          rollType: 'action_roll',
          isMatch: true,
        );
        
        // Serialize to JSON
        final json = originalMoveRoll.toJson();
        
        // Verify isMatch is included in the JSON
        expect(json.containsKey('isMatch'), isTrue);
        expect(json['isMatch'], isTrue);
        
        // Deserialize from JSON
        final deserializedMoveRoll = MoveRoll.fromJson(json);
        
        // Verify isMatch is correctly deserialized
        expect(deserializedMoveRoll.isMatch, isTrue);
        expect(deserializedMoveRoll.outcome, equals('strong hit with a match'));
      });
      
      test('defaults isMatch to false when not provided in JSON', () {
        final json = {
          'id': 'test-id',
          'moveName': 'Face Danger',
          'stat': 'Edge',
          'statValue': 3,
          'actionDie': 5,
          'challengeDice': [2, 1],
          'outcome': 'strong hit',
          'timestamp': DateTime.now().toIso8601String(),
          'rollType': 'action_roll',
          // isMatch is intentionally omitted
        };
        
        final moveRoll = MoveRoll.fromJson(json);
        
        // Verify isMatch defaults to false
        expect(moveRoll.isMatch, isFalse);
      });
    });
  });
}
