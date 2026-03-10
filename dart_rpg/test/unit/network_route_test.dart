import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/network_route.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/quest.dart';

void main() {
  group('NetworkRoute model', () {
    test('creates with default values', () {
      final route = NetworkRoute(
        name: 'Back Door',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );

      expect(route.name, 'Back Door');
      expect(route.characterId, 'char1');
      expect(route.origin, LocationSegment.core);
      expect(route.destination, LocationSegment.corpNet);
      expect(route.rank, QuestRank.dangerous);
      expect(route.progress, 0);
      expect(route.progressTicks, 0);
      expect(route.status, RouteStatus.active);
      expect(route.notes, '');
      expect(route.id, isNotEmpty);
    });

    test('routeLabel returns formatted label', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.darkNet,
        rank: QuestRank.troublesome,
      );

      expect(route.routeLabel, 'Core → DarkNet');
    });

    test('same-segment route is valid', () {
      final route = NetworkRoute(
        name: 'Internal Route',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.core,
        rank: QuestRank.troublesome,
      );

      expect(route.routeLabel, 'Core → Core');
      expect(route.origin, route.destination);
    });

    test('progress tracks work correctly', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );

      // Add ticks for rank (dangerous = 8 ticks = 2 boxes)
      route.addTicksForRank();
      expect(route.progressTicks, 8);
      expect(route.progress, 2);

      // Add another rank's worth
      route.addTicksForRank();
      expect(route.progressTicks, 16);
      expect(route.progress, 4);

      // Remove ticks for rank
      route.removeTicksForRank();
      expect(route.progressTicks, 8);
      expect(route.progress, 2);
    });

    test('addTick and removeTick work', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.troublesome,
      );

      route.addTick();
      expect(route.progressTicks, 1);

      route.addTick();
      route.addTick();
      route.addTick();
      expect(route.progressTicks, 4);
      expect(route.progress, 1);

      route.removeTick();
      expect(route.progressTicks, 3);
      expect(route.progress, 0);
    });

    test('progress clamps at 0 and 40', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.troublesome,
      );

      route.removeTick();
      expect(route.progressTicks, 0);

      route.updateProgressTicks(50);
      expect(route.progressTicks, 40);
      expect(route.progress, 10);
    });

    test('getTicksInBox works correctly', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.troublesome,
        progressTicks: 6, // 1 full box + 2 ticks
      );

      expect(route.getTicksInBox(0), 4); // full
      expect(route.getTicksInBox(1), 2); // partial
      expect(route.getTicksInBox(2), 0); // empty
      expect(route.isBoxFull(0), true);
      expect(route.isBoxFull(1), false);
    });

    test('complete() sets status and timestamp', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );

      expect(route.completedAt, isNull);
      route.complete();
      expect(route.status, RouteStatus.completed);
      expect(route.completedAt, isNotNull);
    });

    test('burn() sets status and timestamp', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );

      expect(route.burnedAt, isNull);
      route.burn();
      expect(route.status, RouteStatus.burned);
      expect(route.burnedAt, isNotNull);
    });

    test('JSON round-trip preserves all fields', () {
      final original = NetworkRoute(
        name: 'Back Door',
        characterId: 'char1',
        origin: LocationSegment.govNet,
        destination: LocationSegment.darkNet,
        rank: QuestRank.formidable,
        progressTicks: 12,
        notes: 'Secret route',
      );

      final json = original.toJson();
      final restored = NetworkRoute.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.characterId, original.characterId);
      expect(restored.origin, original.origin);
      expect(restored.destination, original.destination);
      expect(restored.rank, original.rank);
      expect(restored.progressTicks, original.progressTicks);
      expect(restored.progress, original.progress);
      expect(restored.status, original.status);
      expect(restored.notes, original.notes);
    });

    test('JSON round-trip preserves completed status', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );
      route.complete();

      final json = route.toJson();
      final restored = NetworkRoute.fromJson(json);

      expect(restored.status, RouteStatus.completed);
      expect(restored.completedAt, isNotNull);
    });

    test('JSON round-trip preserves burned status', () {
      final route = NetworkRoute(
        name: 'Test',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
      );
      route.burn();

      final json = route.toJson();
      final restored = NetworkRoute.fromJson(json);

      expect(restored.status, RouteStatus.burned);
      expect(restored.burnedAt, isNotNull);
    });

    test('clone() creates independent copy', () {
      final original = NetworkRoute(
        name: 'Back Door',
        characterId: 'char1',
        origin: LocationSegment.core,
        destination: LocationSegment.corpNet,
        rank: QuestRank.dangerous,
        progressTicks: 8,
      );

      final clone = original.clone();
      clone.name = 'Modified';
      clone.addTicksForRank();

      expect(original.name, 'Back Door');
      expect(original.progressTicks, 8);
      expect(clone.name, 'Modified');
      expect(clone.progressTicks, 16);
    });

    test('getTicksForRank returns correct values', () {
      expect(
        NetworkRoute(name: 'a', characterId: 'c', origin: LocationSegment.core, destination: LocationSegment.core, rank: QuestRank.troublesome).getTicksForRank(),
        12,
      );
      expect(
        NetworkRoute(name: 'a', characterId: 'c', origin: LocationSegment.core, destination: LocationSegment.core, rank: QuestRank.dangerous).getTicksForRank(),
        8,
      );
      expect(
        NetworkRoute(name: 'a', characterId: 'c', origin: LocationSegment.core, destination: LocationSegment.core, rank: QuestRank.formidable).getTicksForRank(),
        4,
      );
      expect(
        NetworkRoute(name: 'a', characterId: 'c', origin: LocationSegment.core, destination: LocationSegment.core, rank: QuestRank.extreme).getTicksForRank(),
        2,
      );
      expect(
        NetworkRoute(name: 'a', characterId: 'c', origin: LocationSegment.core, destination: LocationSegment.core, rank: QuestRank.epic).getTicksForRank(),
        1,
      );
    });
  });

  group('RouteStatus', () {
    test('has correct display names', () {
      expect(RouteStatus.active.displayName, 'Active');
      expect(RouteStatus.completed.displayName, 'Completed');
      expect(RouteStatus.burned.displayName, 'Burned');
    });
  });

  group('LocationSegment icon extension', () {
    test('all segments have icons', () {
      for (final segment in LocationSegment.values) {
        expect(segment.icon, isNotNull);
      }
    });
  });
}
