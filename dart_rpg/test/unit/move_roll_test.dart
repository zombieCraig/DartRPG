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

      test('toJson includes moveId at top level', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          moveId: 'fe_runners/adventure/face_danger',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
          rollType: 'action_roll',
        );

        final json = moveRoll.toJson();
        expect(json['moveId'], equals('fe_runners/adventure/face_danger'));
      });

      test('toJson does NOT include moveDescription', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          moveId: 'fe_runners/adventure/face_danger',
          moveDescription: 'Some old description',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
          rollType: 'action_roll',
        );

        final json = moveRoll.toJson();
        expect(json.containsKey('moveDescription'), isFalse);
      });

      test('fromJson reads top-level moveId', () {
        final json = {
          'id': 'test-id',
          'moveName': 'Face Danger',
          'moveId': 'fe_runners/adventure/face_danger',
          'actionDie': 5,
          'challengeDice': [2, 1],
          'outcome': 'strong hit',
          'timestamp': DateTime.now().toIso8601String(),
          'rollType': 'action_roll',
        };

        final moveRoll = MoveRoll.fromJson(json);
        expect(moveRoll.moveId, equals('fe_runners/adventure/face_danger'));
      });

      test('fromJson backward compat: reads moveId from moveData when no top-level moveId', () {
        final json = {
          'id': 'test-id',
          'moveName': 'Face Danger',
          'moveDescription': 'Old stored description',
          'actionDie': 5,
          'challengeDice': [2, 1],
          'outcome': 'strong hit',
          'timestamp': DateTime.now().toIso8601String(),
          'rollType': 'action_roll',
          'moveData': {'moveId': 'fe_runners/adventure/face_danger'},
        };

        final moveRoll = MoveRoll.fromJson(json);
        expect(moveRoll.moveId, equals('fe_runners/adventure/face_danger'));
        expect(moveRoll.moveDescription, equals('Old stored description'));
      });

      test('fromJson backward compat: handles old data with moveDescription but no moveId', () {
        final json = {
          'id': 'test-id',
          'moveName': 'Face Danger',
          'moveDescription': 'Old stored description',
          'actionDie': 5,
          'challengeDice': [2, 1],
          'outcome': 'strong hit',
          'timestamp': DateTime.now().toIso8601String(),
          'rollType': 'action_roll',
        };

        final moveRoll = MoveRoll.fromJson(json);
        expect(moveRoll.moveId, isNull);
        expect(moveRoll.moveDescription, equals('Old stored description'));
      });
    });

    group('resolveDescription', () {
      test('returns move description when move is provided', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          moveId: 'face_danger',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
        );

        // Simulate a Move-like object with a description
        final fakeMove = _FakeMove('Live move description');
        expect(moveRoll.resolveDescription(fakeMove), equals('Live move description'));
      });

      test('returns stored moveDescription when move is null', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          moveDescription: 'Old stored description',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
        );

        expect(moveRoll.resolveDescription(null), equals('Old stored description'));
      });

      test('returns null when both move and moveDescription are null', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
        );

        expect(moveRoll.resolveDescription(null), isNull);
      });

      test('prefers move description over stored moveDescription', () {
        final moveRoll = MoveRoll(
          moveName: 'Face Danger',
          moveDescription: 'Old stored description',
          actionDie: 5,
          challengeDice: [2, 1],
          outcome: 'strong hit',
        );

        final fakeMove = _FakeMove('Live move description');
        expect(moveRoll.resolveDescription(fakeMove), equals('Live move description'));
      });
    });
  });
}

/// Simple fake to test resolveDescription without importing the full Move model.
class _FakeMove {
  final String? description;
  _FakeMove(this.description);
}
