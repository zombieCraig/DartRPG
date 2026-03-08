import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/connection.dart';
import 'package:dart_rpg/models/quest.dart';

void main() {
  group('Connection model', () {
    test('creates with default values', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
      );

      expect(connection.name, 'Zero');
      expect(connection.characterId, 'char1');
      expect(connection.role, 'Fixer');
      expect(connection.rank, QuestRank.dangerous);
      expect(connection.progress, 0);
      expect(connection.progressTicks, 0);
      expect(connection.status, ConnectionStatus.active);
      expect(connection.notes, '');
      expect(connection.id, isNotEmpty);
    });

    test('progress tracks work correctly', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
      );

      // Add ticks for rank (dangerous = 8 ticks = 2 boxes)
      connection.addTicksForRank();
      expect(connection.progressTicks, 8);
      expect(connection.progress, 2);

      // Add another rank's worth
      connection.addTicksForRank();
      expect(connection.progressTicks, 16);
      expect(connection.progress, 4);

      // Remove ticks for rank
      connection.removeTicksForRank();
      expect(connection.progressTicks, 8);
      expect(connection.progress, 2);
    });

    test('addTick and removeTick work', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.troublesome,
      );

      connection.addTick();
      expect(connection.progressTicks, 1);

      connection.addTick();
      connection.addTick();
      connection.addTick();
      expect(connection.progressTicks, 4);
      expect(connection.progress, 1);

      connection.removeTick();
      expect(connection.progressTicks, 3);
      expect(connection.progress, 0); // Less than 4 ticks = 0 full boxes
    });

    test('progress clamps at 0 and 40', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.troublesome,
      );

      connection.removeTick();
      expect(connection.progressTicks, 0);

      connection.updateProgressTicks(50);
      expect(connection.progressTicks, 40);
      expect(connection.progress, 10);
    });

    test('getTicksInBox works correctly', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.troublesome,
        progressTicks: 6, // 1 full box + 2 ticks
      );

      expect(connection.getTicksInBox(0), 4); // full
      expect(connection.getTicksInBox(1), 2); // partial
      expect(connection.getTicksInBox(2), 0); // empty
      expect(connection.isBoxFull(0), true);
      expect(connection.isBoxFull(1), false);
    });

    test('bond() sets status and timestamp', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
      );

      expect(connection.bondedAt, isNull);
      connection.bond();
      expect(connection.status, ConnectionStatus.bonded);
      expect(connection.bondedAt, isNotNull);
    });

    test('lose() sets status and timestamp', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
      );

      expect(connection.lostAt, isNull);
      connection.lose();
      expect(connection.status, ConnectionStatus.lost);
      expect(connection.lostAt, isNotNull);
    });

    test('JSON round-trip preserves all fields', () {
      final original = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.formidable,
        progressTicks: 12,
        notes: 'Trusted ally',
      );

      final json = original.toJson();
      final restored = Connection.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.characterId, original.characterId);
      expect(restored.role, original.role);
      expect(restored.rank, original.rank);
      expect(restored.progressTicks, original.progressTicks);
      expect(restored.progress, original.progress);
      expect(restored.status, original.status);
      expect(restored.notes, original.notes);
    });

    test('JSON round-trip preserves bonded status', () {
      final connection = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
      );
      connection.bond();

      final json = connection.toJson();
      final restored = Connection.fromJson(json);

      expect(restored.status, ConnectionStatus.bonded);
      expect(restored.bondedAt, isNotNull);
    });

    test('clone() creates independent copy', () {
      final original = Connection(
        name: 'Zero',
        characterId: 'char1',
        role: 'Fixer',
        rank: QuestRank.dangerous,
        progressTicks: 8,
      );

      final clone = original.clone();
      clone.name = 'Modified';
      clone.addTicksForRank();

      expect(original.name, 'Zero');
      expect(original.progressTicks, 8);
      expect(clone.name, 'Modified');
      expect(clone.progressTicks, 16);
    });

    test('getTicksForRank returns correct values', () {
      expect(
        Connection(name: 'a', characterId: 'c', role: 'r', rank: QuestRank.troublesome).getTicksForRank(),
        12,
      );
      expect(
        Connection(name: 'a', characterId: 'c', role: 'r', rank: QuestRank.dangerous).getTicksForRank(),
        8,
      );
      expect(
        Connection(name: 'a', characterId: 'c', role: 'r', rank: QuestRank.formidable).getTicksForRank(),
        4,
      );
      expect(
        Connection(name: 'a', characterId: 'c', role: 'r', rank: QuestRank.extreme).getTicksForRank(),
        2,
      );
      expect(
        Connection(name: 'a', characterId: 'c', role: 'r', rank: QuestRank.epic).getTicksForRank(),
        1,
      );
    });
  });

  group('ConnectionStatus', () {
    test('has correct display names', () {
      expect(ConnectionStatus.active.displayName, 'Active');
      expect(ConnectionStatus.bonded.displayName, 'Bonded');
      expect(ConnectionStatus.lost.displayName, 'Lost');
    });
  });
}
