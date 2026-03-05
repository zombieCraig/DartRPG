import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/session.dart';
import 'package:dart_rpg/models/clock.dart';
import 'package:dart_rpg/providers/clock_operations_mixin.dart';

/// A minimal host for the mixin that tracks persistence calls.
class TestClockHost extends ChangeNotifier with ClockOperationsMixin {
  Game? _game;
  Session? _session;
  int persistCallCount = 0;

  @override
  Game? get clockGame => _game;

  @override
  Session? get clockSession => _session;

  @override
  Future<void> persistAndNotify() async {
    persistCallCount++;
    notifyListeners();
  }

  void setGame(Game game) => _game = game;
  void setSession(Session session) => _session = session;
}

void main() {
  late TestClockHost host;
  late Game game;
  late Session session;

  setUp(() {
    host = TestClockHost();
    game = Game(name: 'Test Game');
    session = Session(title: 'Test Session', gameId: game.id);
    host.setGame(game);
    host.setSession(session);
  });

  group('ClockOperationsMixin', () {
    test('createClock adds a clock and persists', () async {
      final clock = await host.createClock('My Clock', 4, ClockType.campaign);

      expect(clock.title, 'My Clock');
      expect(clock.segments, 4);
      expect(clock.type, ClockType.campaign);
      expect(game.clocks.length, 1);
      expect(host.persistCallCount, 1);
    });

    test('createClock rejects invalid segment count', () async {
      expect(
        () => host.createClock('Bad', 5, ClockType.campaign),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid number of segments'),
        )),
      );
    });

    test('createClock throws when no game selected', () async {
      host.setGame(Game(name: 'temp'));
      // Clear the game reference
      host = TestClockHost(); // no game set
      expect(
        () => host.createClock('X', 4, ClockType.tension),
        throwsA(isA<Exception>()),
      );
    });

    test('advanceClock increments progress and persists', () async {
      final clock = await host.createClock('C', 4, ClockType.tension);
      host.persistCallCount = 0;

      await host.advanceClock(clock.id);

      expect(clock.progress, 1);
      expect(host.persistCallCount, 1);
    });

    test('advanceClock creates journal entry on completion', () async {
      final clock = await host.createClock('C', 4, ClockType.tension);
      // Advance to 3/4
      clock.progress = 3;

      await host.advanceClock(clock.id);

      expect(clock.isComplete, true);
      expect(session.entries.length, 1);
      expect(session.entries.first.content, contains('filled completely'));
    });

    test('resetClock sets progress to 0', () async {
      final clock = await host.createClock('C', 6, ClockType.campaign);
      clock.progress = 4;

      await host.resetClock(clock.id);

      expect(clock.progress, 0);
      expect(clock.completedAt, isNull);
    });

    test('deleteClock removes the clock', () async {
      final clock = await host.createClock('C', 4, ClockType.trace);
      expect(game.clocks.length, 1);

      await host.deleteClock(clock.id);

      expect(game.clocks.length, 0);
    });

    test('updateClockTitle changes title', () async {
      final clock = await host.createClock('Old', 4, ClockType.campaign);

      await host.updateClockTitle(clock.id, 'New');

      expect(clock.title, 'New');
    });

    test('advanceAllClocksOfType advances only matching type', () async {
      await host.createClock('C1', 4, ClockType.campaign);
      await host.createClock('T1', 4, ClockType.tension);
      host.persistCallCount = 0;

      await host.advanceAllClocksOfType(ClockType.campaign);

      final campaignClocks = game.getClocksByType(ClockType.campaign);
      final tensionClocks = game.getClocksByType(ClockType.tension);

      expect(campaignClocks.first.progress, 1);
      expect(tensionClocks.first.progress, 0);
      expect(host.persistCallCount, 1);
    });

    test('advanceAllClocksOfType creates journal entry on completion', () async {
      final clock = await host.createClock('C1', 4, ClockType.campaign);
      clock.progress = 3;

      await host.advanceAllClocksOfType(ClockType.campaign);

      expect(clock.isComplete, true);
      expect(session.entries.length, 1);
      expect(session.entries.first.content, contains('filled completely'));
    });
  });
}
