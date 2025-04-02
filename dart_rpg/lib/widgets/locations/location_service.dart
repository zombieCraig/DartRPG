import '../../models/location.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling location operations
class LocationService {
  /// The game provider
  final GameProvider gameProvider;
  
  /// Creates a new LocationService
  LocationService({
    required this.gameProvider,
  });
  
  /// Create a new location
  Future<Location?> createLocation({
    required String name,
    String? description,
    LocationSegment segment = LocationSegment.core,
    String? connectToLocationId,
    double? x,
    double? y,
  }) async {
    try {
      return await gameProvider.createLocation(
        name,
        description: description,
        segment: segment,
        connectToLocationId: connectToLocationId,
        x: x,
        y: y,
      );
    } catch (e) {
      LoggingService().error(
        'Failed to create location',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
  
  /// Update a location
  Future<bool> updateLocation({
    required String locationId,
    required String name,
    String? description,
    String? imageUrl,
    LocationSegment? segment,
  }) async {
    try {
      // Get the current location
      final location = gameProvider.currentGame?.locations.firstWhere(
        (l) => l.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      
      if (location == null) {
        return false;
      }
      
      // Update the location properties
      location.name = name;
      location.description = description;
      location.imageUrl = imageUrl;
      
      // Update segment if provided and different
      if (segment != null && segment != location.segment) {
        await gameProvider.updateLocationSegment(locationId, segment);
      }
      
      // Save the changes
      await gameProvider.saveGame();
      
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update location',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Delete a location
  Future<bool> deleteLocation(String locationId) async {
    try {
      final location = gameProvider.currentGame?.locations.firstWhere(
        (l) => l.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      
      if (location == null || gameProvider.currentGame == null) {
        return false;
      }
      
      // Remove all connections first
      for (final connectedId in List.from(location.connectedLocationIds)) {
        await disconnectLocations(locationId, connectedId);
      }
      
      // Then remove the location
      gameProvider.currentGame!.locations.removeWhere((l) => l.id == locationId);
      await gameProvider.saveGame();
      
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to delete location',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Connect two locations
  Future<bool> connectLocations(String sourceId, String targetId) async {
    try {
      await gameProvider.connectLocations(sourceId, targetId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to connect locations',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Disconnect two locations
  Future<bool> disconnectLocations(String sourceId, String targetId) async {
    try {
      await gameProvider.disconnectLocations(sourceId, targetId);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to disconnect locations',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Get valid connections for a location
  List<Location> getValidConnectionsForLocation(String locationId) {
    try {
      return gameProvider.getValidConnectionsForLocation(locationId);
    } catch (e) {
      LoggingService().error(
        'Failed to get valid connections',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return [];
    }
  }
  
  /// Update location segment
  Future<bool> updateLocationSegment(String locationId, LocationSegment segment) async {
    try {
      await gameProvider.updateLocationSegment(locationId, segment);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update location segment',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Update location position
  Future<bool> updateLocationPosition(String locationId, double x, double y) async {
    try {
      await gameProvider.updateLocationPosition(locationId, x, y);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update location position',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Update location scale
  Future<bool> updateLocationScale(String locationId, double scale) async {
    try {
      await gameProvider.updateLocationScale(locationId, scale);
      return true;
    } catch (e) {
      LoggingService().error(
        'Failed to update location scale',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }
  
  /// Get a location by ID
  Location? getLocationById(String locationId) {
    try {
      return gameProvider.currentGame?.locations.firstWhere(
        (l) => l.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
    } catch (e) {
      LoggingService().error(
        'Failed to get location by ID',
        tag: 'LocationService',
        error: e,
        stackTrace: StackTrace.current,
      );
      return null;
    }
  }
  
  /// Get all locations
  List<Location> getAllLocations() {
    return gameProvider.currentGame?.locations ?? [];
  }
  
  /// Get locations filtered by search query
  List<Location> getFilteredLocations(String searchQuery) {
    if (searchQuery.isEmpty) {
      return getAllLocations();
    }
    
    final query = searchQuery.toLowerCase();
    return getAllLocations().where((loc) => 
      loc.name.toLowerCase().contains(query) ||
      (loc.description != null && loc.description!.toLowerCase().contains(query))
    ).toList();
  }
  
  /// Check if a location is the rig location
  bool isRigLocation(String locationId) {
    return gameProvider.currentGame?.rigLocation?.id == locationId;
  }
  
  /// Check if two segments are adjacent (can be connected)
  bool areSegmentsAdjacent(LocationSegment segment1, LocationSegment segment2) {
    if (segment1 == segment2) return true;
    
    switch (segment1) {
      case LocationSegment.core:
        return segment2 == LocationSegment.corpNet;
      case LocationSegment.corpNet:
        return segment2 == LocationSegment.core || segment2 == LocationSegment.govNet;
      case LocationSegment.govNet:
        return segment2 == LocationSegment.corpNet || segment2 == LocationSegment.darkNet;
      case LocationSegment.darkNet:
        return segment2 == LocationSegment.govNet;
    }
  }
}
