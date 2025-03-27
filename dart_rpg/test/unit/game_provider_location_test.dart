import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('GameProvider - Location Management', () {
    late GameProvider gameProvider;
    
    setUp(() async {
      // Set up SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Create a GameProvider instance
      gameProvider = GameProvider();
      
      // Create a test game
      await gameProvider.createGame('Test Game');
    });
    
    group('createLocation', () {
      test('creates location with default values', () async {
        final location = await gameProvider.createLocation('Test Location');
        
        expect(location.name, equals('Test Location'));
        expect(location.description, isNull);
        expect(location.segment, equals(LocationSegment.core));
        expect(location.connectedLocationIds, isEmpty);
        
        // Verify location was added to the game
        expect(gameProvider.currentGame!.locations.length, equals(2)); // Rig + new location
        expect(gameProvider.currentGame!.locations.any((loc) => loc.id == location.id), isTrue);
      });
      
      test('creates location with provided values', () async {
        final location = await gameProvider.createLocation(
          'Test Location',
          description: 'Test Description',
          segment: LocationSegment.corpNet,
          x: 10.0,
          y: 20.0,
        );
        
        expect(location.name, equals('Test Location'));
        expect(location.description, equals('Test Description'));
        expect(location.segment, equals(LocationSegment.corpNet));
        expect(location.x, equals(10.0));
        expect(location.y, equals(20.0));
        
        // Verify location was added to the game
        expect(gameProvider.currentGame!.locations.any((loc) => loc.id == location.id), isTrue);
      });
      
      test('connects to existing location when connectToLocationId is provided', () async {
        // Get the rig location
        final rigLocation = gameProvider.currentGame!.rigLocation!;
        
        // Create a new location connected to the rig
        final location = await gameProvider.createLocation(
          'Connected Location',
          connectToLocationId: rigLocation.id,
        );
        
        // Verify connection was created
        expect(rigLocation.connectedLocationIds, contains(location.id));
        expect(location.connectedLocationIds, contains(rigLocation.id));
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.createLocation('Test Location'),
          throwsException,
        );
      });
    });
    
    group('connectLocations', () {
      late Location locationA;
      late Location locationB;
      
      setUp(() async {
        // Create two test locations
        locationA = await gameProvider.createLocation('Location A');
        locationB = await gameProvider.createLocation('Location B');
      });
      
      test('connects two locations', () async {
        await gameProvider.connectLocations(locationA.id, locationB.id);
        
        // Get updated locations from the game
        final updatedA = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == locationA.id);
        final updatedB = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == locationB.id);
        
        expect(updatedA.connectedLocationIds, contains(locationB.id));
        expect(updatedB.connectedLocationIds, contains(locationA.id));
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.connectLocations(locationA.id, locationB.id),
          throwsException,
        );
      });
    });
    
    group('disconnectLocations', () {
      late Location locationA;
      late Location locationB;
      
      setUp(() async {
        // Create two test locations
        locationA = await gameProvider.createLocation('Location A');
        locationB = await gameProvider.createLocation('Location B');
        
        // Connect them
        await gameProvider.connectLocations(locationA.id, locationB.id);
      });
      
      test('disconnects two locations', () async {
        await gameProvider.disconnectLocations(locationA.id, locationB.id);
        
        // Get updated locations from the game
        final updatedA = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == locationA.id);
        final updatedB = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == locationB.id);
        
        expect(updatedA.connectedLocationIds, isNot(contains(locationB.id)));
        expect(updatedB.connectedLocationIds, isNot(contains(locationA.id)));
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.disconnectLocations(locationA.id, locationB.id),
          throwsException,
        );
      });
    });
    
    group('updateLocationPosition', () {
      late Location location;
      
      setUp(() async {
        // Create a test location
        location = await gameProvider.createLocation('Test Location');
      });
      
      test('updates location position', () async {
        await gameProvider.updateLocationPosition(location.id, 10.0, 20.0);
        
        // Get updated location from the game
        final updatedLocation = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == location.id);
        
        expect(updatedLocation.x, equals(10.0));
        expect(updatedLocation.y, equals(20.0));
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.updateLocationPosition(location.id, 10.0, 20.0),
          throwsException,
        );
      });
      
      test('throws exception when location not found', () {
        expect(
          () => gameProvider.updateLocationPosition('non-existent', 10.0, 20.0),
          throwsException,
        );
      });
    });
    
    group('updateLocationScale', () {
      late Location location;
      
      setUp(() async {
        // Create a test location
        location = await gameProvider.createLocation('Test Location');
      });
      
      test('updates location scale', () async {
        await gameProvider.updateLocationScale(location.id, 1.5);
        
        // Get updated location from the game
        final updatedLocation = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == location.id);
        
        expect(updatedLocation.scale, equals(1.5));
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.updateLocationScale(location.id, 1.5),
          throwsException,
        );
      });
      
      test('throws exception when location not found', () {
        expect(
          () => gameProvider.updateLocationScale('non-existent', 1.5),
          throwsException,
        );
      });
    });
    
    group('updateLocationSegment', () {
      late Location locationA;
      late Location locationB;
      
      setUp(() async {
        // Create two test locations
        locationA = await gameProvider.createLocation('Location A', segment: LocationSegment.core);
        locationB = await gameProvider.createLocation('Location B', segment: LocationSegment.corpNet);
        
        // Connect them
        await gameProvider.connectLocations(locationA.id, locationB.id);
      });
      
      test('updates location segment', () async {
        // Update locationA to corpNet (still adjacent to locationB)
        await gameProvider.updateLocationSegment(locationA.id, LocationSegment.corpNet);
        
        // Get updated location from the game
        final updatedLocation = gameProvider.currentGame!.locations.firstWhere((loc) => loc.id == locationA.id);
        
        expect(updatedLocation.segment, equals(LocationSegment.corpNet));
      });
      
      test('throws exception when update would violate connection rules', () async {
        // Try to update locationA to govNet (not adjacent to locationB)
        try {
          await gameProvider.updateLocationSegment(locationA.id, LocationSegment.govNet);
          fail('Expected an exception to be thrown');
        } catch (e) {
          // Exception was thrown as expected
          expect(e, isA<Exception>());
        }
      });
      
      test('throws exception when no game is selected', () async {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.updateLocationSegment(locationA.id, LocationSegment.corpNet),
          throwsException,
        );
      });
      
      test('throws exception when location not found', () {
        expect(
          () => gameProvider.updateLocationSegment('non-existent', LocationSegment.core),
          throwsException,
        );
      });
    });
    
    group('getValidConnectionsForLocation', () {
      late Location locationA;
      late Location locationB;
      late Location locationC;
      
      setUp(() async {
        // Create three test locations in different segments
        locationA = await gameProvider.createLocation('Location A', segment: LocationSegment.core);
        locationB = await gameProvider.createLocation('Location B', segment: LocationSegment.corpNet);
        locationC = await gameProvider.createLocation('Location C', segment: LocationSegment.govNet);
        
        // Connect A and B
        await gameProvider.connectLocations(locationA.id, locationB.id);
      });
      
      test('returns valid connections', () {
        // Get valid connections for locationB
        final validConnections = gameProvider.getValidConnectionsForLocation(locationB.id);
        
        // Should include locationC (govNet is adjacent to corpNet)
        // Should not include locationA (already connected)
        expect(validConnections.any((loc) => loc.id == locationC.id), isTrue);
        expect(validConnections.any((loc) => loc.id == locationA.id), isFalse);
        
        // The rig location might also be a valid connection, so we don't check the exact length
      });
      
      test('returns empty list when no valid connections', () async {
        // Create a darkNet location
        final locationD = await gameProvider.createLocation('Location D', segment: LocationSegment.darkNet);
        
        // Connect C and D
        await gameProvider.connectLocations(locationC.id, locationD.id);
        
        // Get valid connections for locationD
        final validConnections = gameProvider.getValidConnectionsForLocation(locationD.id);
        
        // Should be empty (already connected to locationC, and no other adjacent segments)
        expect(validConnections, isEmpty);
      });
      
      test('throws exception when no game is selected', () {
        // Set current game to null
        gameProvider = GameProvider();
        
        expect(
          () => gameProvider.getValidConnectionsForLocation(locationA.id),
          throwsException,
        );
      });
    });
  });
}
