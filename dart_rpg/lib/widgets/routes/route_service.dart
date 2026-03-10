import '../../models/location.dart';
import '../../models/network_route.dart';
import '../../models/quest.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling route operations
class RouteService {
  final GameProvider gameProvider;

  RouteService({required this.gameProvider});

  Future<NetworkRoute?> createRoute({
    required String name,
    required String characterId,
    required LocationSegment origin,
    required LocationSegment destination,
    required QuestRank rank,
    String notes = '',
  }) async {
    try {
      return await gameProvider.createRoute(
        name, characterId, origin, destination, rank,
        notes: notes,
      );
    } catch (e) {
      LoggingService().error('Failed to create route',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> updateRoute({
    required String routeId,
    required String name,
    required LocationSegment origin,
    required LocationSegment destination,
    required QuestRank rank,
    required String notes,
  }) async {
    try {
      await gameProvider.updateRouteDetails(
        routeId,
        name: name,
        origin: origin,
        destination: destination,
        rank: rank,
      );
      await gameProvider.updateRouteNotes(routeId, notes);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update route',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<Map<String, dynamic>?> makeProgressRoll(String routeId) async {
    try {
      return await gameProvider.makeRouteProgressRoll(routeId);
    } catch (e) {
      LoggingService().error('Failed to make progress roll',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> completeRoute(String routeId) async {
    try {
      await gameProvider.completeRoute(routeId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to complete route',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> burnRoute(String routeId) async {
    try {
      await gameProvider.burnRoute(routeId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to burn route',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteRoute(String routeId) async {
    try {
      await gameProvider.deleteRoute(routeId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to delete route',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> addTicksForRank(String routeId) async {
    try {
      await gameProvider.addRouteTicksForRank(routeId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to add ticks for rank',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> removeTicksForRank(String routeId) async {
    try {
      await gameProvider.removeRouteTicksForRank(routeId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to remove ticks for rank',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> updateProgress(String routeId, int progress) async {
    try {
      await gameProvider.updateRouteProgress(routeId, progress);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update route progress',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> updateNotes(String routeId, String notes) async {
    try {
      await gameProvider.updateRouteNotes(routeId, notes);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update route notes',
          tag: 'RouteService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
}
