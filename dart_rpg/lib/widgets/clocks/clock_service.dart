import '../../models/clock.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling clock operations
class ClockService {
  /// The game provider
  final GameProvider gameProvider;
  
  /// Creates a new ClockService
  ClockService({
    required this.gameProvider,
  });
  
  /// Create a new clock
  Future<Clock?> createClock({
    required String title,
    required int segments,
    required ClockType type,
  }) async {
    try {
      return await gameProvider.createClock(
        title,
        segments,
        type,
      );
    } catch (e) {
      LoggingService().error(
        'Failed to create clock',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
  
  /// Update a clock's title
  Future<bool> updateClockTitle(String clockId, String title) async {
    try {
      await gameProvider.updateClockTitle(clockId, title);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update clock title',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Advance a clock by one segment
  Future<bool> advanceClock(String clockId) async {
    try {
      await gameProvider.advanceClock(clockId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to advance clock',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Reset a clock's progress
  Future<bool> resetClock(String clockId) async {
    try {
      await gameProvider.resetClock(clockId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to reset clock',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Delete a clock
  Future<bool> deleteClock(String clockId) async {
    try {
      await gameProvider.deleteClock(clockId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to delete clock',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Advance all clocks of a specific type
  Future<bool> advanceAllClocksOfType(ClockType type) async {
    try {
      await gameProvider.advanceAllClocksOfType(type);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to advance all clocks of type',
        tag: 'ClockService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
}
