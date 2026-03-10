import '../../models/clock.dart';
import '../../models/faction.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling faction operations
class FactionService {
  final GameProvider gameProvider;

  FactionService({required this.gameProvider});

  Future<Faction?> createFaction({
    required String name,
    FactionType type = FactionType.corporate,
    FactionInfluence influence = FactionInfluence.established,
    String description = '',
    String leadershipStyle = '',
    List<String>? subtypes,
    String projects = '',
    String quirks = '',
    String rumors = '',
  }) async {
    try {
      return await gameProvider.createFaction(
        name,
        type: type,
        influence: influence,
        description: description,
        leadershipStyle: leadershipStyle,
        subtypes: subtypes,
        projects: projects,
        quirks: quirks,
        rumors: rumors,
      );
    } catch (e) {
      LoggingService().error('Failed to create faction',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> updateFaction({
    required String factionId,
    String? name,
    FactionType? type,
    FactionInfluence? influence,
    String? description,
    String? leadershipStyle,
    List<String>? subtypes,
    String? projects,
    String? quirks,
    String? rumors,
  }) async {
    try {
      await gameProvider.updateFactionDetails(
        factionId,
        name: name,
        type: type,
        influence: influence,
        description: description,
        leadershipStyle: leadershipStyle,
        subtypes: subtypes,
        projects: projects,
        quirks: quirks,
        rumors: rumors,
      );
      return true;
    } catch (e) {
      LoggingService().error('Failed to update faction',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteFaction(String factionId) async {
    try {
      await gameProvider.deleteFaction(factionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to delete faction',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> setFactionRelationships(
    String factionId,
    Map<String, String> relationships,
  ) async {
    try {
      await gameProvider.setFactionRelationships(factionId, relationships);
      return true;
    } catch (e) {
      LoggingService().error('Failed to set faction relationships',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<Clock?> addClockToFaction({
    required String factionId,
    required String title,
    required int segments,
    required ClockType type,
  }) async {
    try {
      return await gameProvider.addClockToFaction(
        factionId, title, segments, type,
      );
    } catch (e) {
      LoggingService().error('Failed to add clock to faction',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> removeClockFromFaction({
    required String factionId,
    required String clockId,
  }) async {
    try {
      await gameProvider.removeClockFromFaction(factionId, clockId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to remove clock from faction',
          tag: 'FactionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
}
