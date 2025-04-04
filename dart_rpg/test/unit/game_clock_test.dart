import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/clock.dart';

void main() {
  group('Game - Clock Operations', () {
    late Game game;
    
    setUp(() {
      game = Game(
        name: 'Test Game',
      );
    });
    
    test('adds a clock', () {
      expect(game.clocks.isEmpty, true);
      
      final clock = Clock(
        title: 'Test Clock',
        segments: 4,
        type: ClockType.campaign,
      );
      
      game.addClock(clock);
      
      expect(game.clocks.length, 1);
      expect(game.clocks.first.title, 'Test Clock');
    });
    
    test('gets all clocks', () {
      expect(game.getAllClocks().isEmpty, true);
      
      final clock1 = Clock(
        title: 'Clock 1',
        segments: 4,
        type: ClockType.campaign,
      );
      
      final clock2 = Clock(
        title: 'Clock 2',
        segments: 6,
        type: ClockType.tension,
      );
      
      game.addClock(clock1);
      game.addClock(clock2);
      
      final allClocks = game.getAllClocks();
      expect(allClocks.length, 2);
      expect(allClocks[0].title, 'Clock 1');
      expect(allClocks[1].title, 'Clock 2');
    });
    
    test('gets clocks by type', () {
      final campaignClock = Clock(
        title: 'Campaign Clock',
        segments: 4,
        type: ClockType.campaign,
      );
      
      final tensionClock = Clock(
        title: 'Tension Clock',
        segments: 6,
        type: ClockType.tension,
      );
      
      final traceClock = Clock(
        title: 'Trace Clock',
        segments: 8,
        type: ClockType.trace,
      );
      
      game.addClock(campaignClock);
      game.addClock(tensionClock);
      game.addClock(traceClock);
      
      final campaignClocks = game.getClocksByType(ClockType.campaign);
      expect(campaignClocks.length, 1);
      expect(campaignClocks.first.title, 'Campaign Clock');
      
      final tensionClocks = game.getClocksByType(ClockType.tension);
      expect(tensionClocks.length, 1);
      expect(tensionClocks.first.title, 'Tension Clock');
      
      final traceClocks = game.getClocksByType(ClockType.trace);
      expect(traceClocks.length, 1);
      expect(traceClocks.first.title, 'Trace Clock');
    });
    
    test('serializes and deserializes clocks', () {
      final clock1 = Clock(
        title: 'Clock 1',
        segments: 4,
        type: ClockType.campaign,
        progress: 2,
      );
      
      final clock2 = Clock(
        title: 'Clock 2',
        segments: 6,
        type: ClockType.tension,
        progress: 3,
      );
      
      game.addClock(clock1);
      game.addClock(clock2);
      
      final json = game.toJson();
      final deserializedGame = Game.fromJson(json);
      
      expect(deserializedGame.clocks.length, 2);
      
      final deserializedClock1 = deserializedGame.clocks[0];
      expect(deserializedClock1.title, 'Clock 1');
      expect(deserializedClock1.segments, 4);
      expect(deserializedClock1.type, ClockType.campaign);
      expect(deserializedClock1.progress, 2);
      
      final deserializedClock2 = deserializedGame.clocks[1];
      expect(deserializedClock2.title, 'Clock 2');
      expect(deserializedClock2.segments, 6);
      expect(deserializedClock2.type, ClockType.tension);
      expect(deserializedClock2.progress, 3);
    });
  });
}
