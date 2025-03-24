import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/location.dart';

void main() {
  group('Game - Location Management', () {
    late Game game;
    late Location locationA;
    late Location locationB;
    late Location locationC;
    
    setUp(() {
      // Create a game with three locations in different segments
      game = Game(name: 'Test Game');
      
      // Clear default locations (rig)
      game.locations.clear();
      
      // Create test locations
      locationA = Location(
        id: 'loc-a',
        name: 'Location A',
        segment: LocationSegment.core,
      );
      
      locationB = Location(
        id: 'loc-b',
        name: 'Location B',
        segment: LocationSegment.corpNet,
      );
      
      locationC = Location(
        id: 'loc-c',
        name: 'Location C',
        segment: LocationSegment.govNet,
      );
      
      // Add locations to game
      game.locations.add(locationA);
      game.locations.add(locationB);
      game.locations.add(locationC);
    });
    
    group('connectLocations', () {
      test('connects two locations bidirectionally', () {
        game.connectLocations(locationA.id, locationB.id);
        
        expect(locationA.connectedLocationIds, contains(locationB.id));
        expect(locationB.connectedLocationIds, contains(locationA.id));
      });
      
      test('throws exception when source location not found', () {
        expect(
          () => game.connectLocations('non-existent', locationB.id),
          throwsException,
        );
      });
      
      test('throws exception when target location not found', () {
        expect(
          () => game.connectLocations(locationA.id, 'non-existent'),
          throwsException,
        );
      });
      
      test('throws exception when connecting non-adjacent segments', () {
        // Core and GovNet are not adjacent
        expect(
          () => game.connectLocations(locationA.id, locationC.id),
          throwsException,
        );
      });
      
      test('allows connection between same segments', () {
        // Create another core location
        final locationD = Location(
          id: 'loc-d',
          name: 'Location D',
          segment: LocationSegment.core,
        );
        game.locations.add(locationD);
        
        // Connect two core locations
        game.connectLocations(locationA.id, locationD.id);
        
        expect(locationA.connectedLocationIds, contains(locationD.id));
        expect(locationD.connectedLocationIds, contains(locationA.id));
      });
      
      test('does nothing when trying to connect to self', () {
        game.connectLocations(locationA.id, locationA.id);
        
        expect(locationA.connectedLocationIds, isEmpty);
      });
    });
    
    group('disconnectLocations', () {
      setUp(() {
        // Pre-connect locations for disconnect tests
        locationA.addConnection(locationB.id);
        locationB.addConnection(locationA.id);
      });
      
      test('disconnects two locations bidirectionally', () {
        game.disconnectLocations(locationA.id, locationB.id);
        
        expect(locationA.connectedLocationIds, isNot(contains(locationB.id)));
        expect(locationB.connectedLocationIds, isNot(contains(locationA.id)));
      });
      
      test('throws exception when source location not found', () {
        expect(
          () => game.disconnectLocations('non-existent', locationB.id),
          throwsException,
        );
      });
      
      test('throws exception when target location not found', () {
        expect(
          () => game.disconnectLocations(locationA.id, 'non-existent'),
          throwsException,
        );
      });
      
      test('does nothing when trying to disconnect from self', () {
        game.disconnectLocations(locationA.id, locationA.id);
        
        // Should still be connected to locationB
        expect(locationA.connectedLocationIds, contains(locationB.id));
        expect(locationB.connectedLocationIds, contains(locationA.id));
      });
    });
    
    group('areSegmentsAdjacent', () {
      test('returns true for same segment', () {
        expect(game.areSegmentsAdjacent(LocationSegment.core, LocationSegment.core), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.corpNet, LocationSegment.corpNet), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.govNet, LocationSegment.govNet), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.darkNet, LocationSegment.darkNet), isTrue);
      });
      
      test('returns true for adjacent segments', () {
        // Core <-> CorpNet
        expect(game.areSegmentsAdjacent(LocationSegment.core, LocationSegment.corpNet), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.corpNet, LocationSegment.core), isTrue);
        
        // CorpNet <-> GovNet
        expect(game.areSegmentsAdjacent(LocationSegment.corpNet, LocationSegment.govNet), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.govNet, LocationSegment.corpNet), isTrue);
        
        // GovNet <-> DarkNet
        expect(game.areSegmentsAdjacent(LocationSegment.govNet, LocationSegment.darkNet), isTrue);
        expect(game.areSegmentsAdjacent(LocationSegment.darkNet, LocationSegment.govNet), isTrue);
      });
      
      test('returns false for non-adjacent segments', () {
        // Core <-> GovNet
        expect(game.areSegmentsAdjacent(LocationSegment.core, LocationSegment.govNet), isFalse);
        expect(game.areSegmentsAdjacent(LocationSegment.govNet, LocationSegment.core), isFalse);
        
        // Core <-> DarkNet
        expect(game.areSegmentsAdjacent(LocationSegment.core, LocationSegment.darkNet), isFalse);
        expect(game.areSegmentsAdjacent(LocationSegment.darkNet, LocationSegment.core), isFalse);
        
        // CorpNet <-> DarkNet
        expect(game.areSegmentsAdjacent(LocationSegment.corpNet, LocationSegment.darkNet), isFalse);
        expect(game.areSegmentsAdjacent(LocationSegment.darkNet, LocationSegment.corpNet), isFalse);
      });
    });
    
    group('getValidConnectionsForLocation', () {
      test('returns locations with adjacent segments', () {
        // Create additional locations
        final locationD = Location(
          id: 'loc-d',
          name: 'Location D',
          segment: LocationSegment.core,
        );
        
        final locationE = Location(
          id: 'loc-e',
          name: 'Location E',
          segment: LocationSegment.darkNet,
        );
        
        game.locations.add(locationD);
        game.locations.add(locationE);
        
        // Get valid connections for locationA (Core)
        final validForA = game.getValidConnectionsForLocation(locationA.id);
        
        // Should include locationB (CorpNet) and locationD (Core)
        expect(validForA.length, equals(2));
        expect(validForA.any((loc) => loc.id == locationB.id), isTrue);
        expect(validForA.any((loc) => loc.id == locationD.id), isTrue);
        
        // Should not include locationC (GovNet) or locationE (DarkNet)
        expect(validForA.any((loc) => loc.id == locationC.id), isFalse);
        expect(validForA.any((loc) => loc.id == locationE.id), isFalse);
      });
      
      test('excludes already connected locations', () {
        // Connect locationA and locationB
        game.connectLocations(locationA.id, locationB.id);
        
        // Get valid connections for locationA
        final validForA = game.getValidConnectionsForLocation(locationA.id);
        
        // Should not include locationB (already connected)
        expect(validForA.any((loc) => loc.id == locationB.id), isFalse);
      });
      
      test('throws exception when location not found', () {
        expect(
          () => game.getValidConnectionsForLocation('non-existent'),
          throwsException,
        );
      });
    });
    
    group('createRigLocation', () {
      test('creates rig location in core segment', () {
        final newGame = Game(name: 'Empty Game');
        
        // Clear locations and create rig
        newGame.locations.clear();
        newGame.createRigLocation();
        
        expect(newGame.locations.length, equals(1));
        expect(newGame.locations.first.name, equals('Your Rig'));
        expect(newGame.locations.first.segment, equals(LocationSegment.core));
        expect(newGame.rigLocation, equals(newGame.locations.first));
      });
      
      test('rig location is automatically created for new games', () {
        final newGame = Game(name: 'New Game', locations: []);
        
        expect(newGame.locations.length, equals(1));
        expect(newGame.locations.first.name, equals('Your Rig'));
        expect(newGame.rigLocation, equals(newGame.locations.first));
      });
    });
  });
}
