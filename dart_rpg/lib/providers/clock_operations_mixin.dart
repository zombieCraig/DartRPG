import 'package:flutter/foundation.dart';
import '../models/clock.dart';
import '../models/game.dart';
import '../models/session.dart';

/// Mixin that encapsulates all clock-related operations.
///
/// Requires the host class to provide access to game state via
/// [clockGame], [clockSession], and [persistAndNotify].
mixin ClockOperationsMixin on ChangeNotifier {
  Game? get clockGame;
  Session? get clockSession;
  Future<void> persistAndNotify();

  Future<Clock> createClock(
    String title,
    int segments,
    ClockType type,
  ) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    if (![4, 6, 8, 10].contains(segments)) {
      throw Exception('Invalid number of segments. Must be 4, 6, 8, or 10.');
    }

    final clock = Clock(
      title: title,
      segments: segments,
      type: type,
    );

    clockGame!.addClock(clock);
    await persistAndNotify();
    return clock;
  }

  Future<void> updateClockTitle(String clockId, String title) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    final clock = clockGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );

    clock.title = title;
    await persistAndNotify();
  }

  Future<void> advanceClock(String clockId) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    final clock = clockGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );

    clock.advance();

    if (clock.isComplete && clockSession != null) {
      clockSession!.createNewEntry(
        'Clock "${clock.title}" has filled completely.\n'
        'Type: ${clock.type.displayName}\n'
        'Segments: ${clock.progress}/${clock.segments}'
      );
    }

    await persistAndNotify();
  }

  Future<void> resetClock(String clockId) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    final clock = clockGame!.clocks.firstWhere(
      (c) => c.id == clockId,
      orElse: () => throw Exception('Clock not found'),
    );

    clock.reset();
    await persistAndNotify();
  }

  Future<void> deleteClock(String clockId) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    clockGame!.clocks.removeWhere((c) => c.id == clockId);
    await persistAndNotify();
  }

  Future<void> advanceAllClocksOfType(ClockType type) async {
    if (clockGame == null) {
      throw Exception('No game selected');
    }

    final clocks = clockGame!.getClocksByType(type);
    bool anyCompleted = false;

    for (final clock in clocks) {
      if (!clock.isComplete) {
        clock.advance();
        if (clock.isComplete) {
          anyCompleted = true;
        }
      }
    }

    if (anyCompleted && clockSession != null) {
      final completedClocks = clocks.where((c) => c.isComplete && c.completedAt != null);

      if (completedClocks.isNotEmpty) {
        final clockNames = completedClocks.map((c) => '"${c.title}"').join(', ');
        clockSession!.createNewEntry(
          'The following ${type.displayName} clocks have filled completely: $clockNames'
        );
      }
    }

    await persistAndNotify();
  }
}
