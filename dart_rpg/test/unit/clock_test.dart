import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/clock.dart';

void main() {
  group('Clock', () {
    test('creates with default values', () {
      final clock = Clock(
        title: 'Test Clock',
        segments: 4,
        type: ClockType.campaign,
      );
      
      expect(clock.title, 'Test Clock');
      expect(clock.segments, 4);
      expect(clock.type, ClockType.campaign);
      expect(clock.progress, 0);
      expect(clock.isComplete, false);
      expect(clock.completedAt, null);
      expect(clock.id.isNotEmpty, true);
    });
    
    test('creates with custom values', () {
      final clock = Clock(
        id: 'custom-id',
        title: 'Test Clock',
        segments: 6,
        type: ClockType.tension,
        progress: 3,
      );
      
      expect(clock.id, 'custom-id');
      expect(clock.title, 'Test Clock');
      expect(clock.segments, 6);
      expect(clock.type, ClockType.tension);
      expect(clock.progress, 3);
      expect(clock.isComplete, false);
    });
    
    test('advances progress', () {
      final clock = Clock(
        title: 'Test Clock',
        segments: 4,
        type: ClockType.campaign,
      );
      
      expect(clock.progress, 0);
      
      clock.advance();
      expect(clock.progress, 1);
      expect(clock.isComplete, false);
      
      clock.advance();
      expect(clock.progress, 2);
      expect(clock.isComplete, false);
      
      clock.advance();
      expect(clock.progress, 3);
      expect(clock.isComplete, false);
      
      clock.advance();
      expect(clock.progress, 4);
      expect(clock.isComplete, true);
      expect(clock.completedAt, isNotNull);
      
      // Should not advance beyond max segments
      clock.advance();
      expect(clock.progress, 4);
    });
    
    test('resets progress', () {
      final clock = Clock(
        title: 'Test Clock',
        segments: 4,
        type: ClockType.campaign,
        progress: 3,
      );
      
      expect(clock.progress, 3);
      
      clock.reset();
      expect(clock.progress, 0);
      expect(clock.isComplete, false);
      expect(clock.completedAt, null);
    });
    
    test('serializes to and from JSON', () {
      final originalClock = Clock(
        title: 'Test Clock',
        segments: 8,
        type: ClockType.trace,
        progress: 5,
      );
      
      final json = originalClock.toJson();
      final deserializedClock = Clock.fromJson(json);
      
      expect(deserializedClock.id, originalClock.id);
      expect(deserializedClock.title, originalClock.title);
      expect(deserializedClock.segments, originalClock.segments);
      expect(deserializedClock.type, originalClock.type);
      expect(deserializedClock.progress, originalClock.progress);
      expect(deserializedClock.isComplete, originalClock.isComplete);
      
      // If completedAt is null in the original, it should be null in the deserialized
      expect(deserializedClock.completedAt, originalClock.completedAt);
      
      // Test with a completed clock
      final completedClock = Clock(
        title: 'Completed Clock',
        segments: 4,
        type: ClockType.campaign,
        progress: 4,
      );
      completedClock.completedAt = DateTime.now();
      
      final completedJson = completedClock.toJson();
      final deserializedCompletedClock = Clock.fromJson(completedJson);
      
      expect(deserializedCompletedClock.isComplete, true);
      expect(deserializedCompletedClock.completedAt, isNotNull);
    });
    
    test('ClockType has correct display names', () {
      expect(ClockType.campaign.displayName, 'Campaign');
      expect(ClockType.tension.displayName, 'Tension');
      expect(ClockType.trace.displayName, 'Trace');
    });
    
    test('ClockType has correct icons', () {
      expect(ClockType.campaign.icon, isNotNull);
      expect(ClockType.tension.icon, isNotNull);
      expect(ClockType.trace.icon, isNotNull);
    });
    
    test('ClockType has correct colors', () {
      expect(ClockType.campaign.color, isNotNull);
      expect(ClockType.tension.color, isNotNull);
      expect(ClockType.trace.color, isNotNull);
    });
  });
}
