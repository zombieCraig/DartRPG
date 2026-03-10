import '../../models/connection.dart';
import '../../models/quest.dart';
import '../../providers/game_provider.dart';
import '../../utils/logging_service.dart';

/// A service for handling connection operations
class ConnectionService {
  final GameProvider gameProvider;

  ConnectionService({required this.gameProvider});

  Future<Connection?> createConnection({
    required String name,
    required String characterId,
    required QuestRank rank,
    required String role,
    String notes = '',
  }) async {
    try {
      return await gameProvider.createConnection(
        name, characterId, rank, role,
        notes: notes,
      );
    } catch (e) {
      LoggingService().error('Failed to create connection',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> updateConnection({
    required String connectionId,
    required String name,
    required String role,
    required QuestRank rank,
    required String notes,
  }) async {
    try {
      await gameProvider.updateConnectionDetails(
        connectionId,
        name: name,
        role: role,
        rank: rank,
      );
      await gameProvider.updateConnectionNotes(connectionId, notes);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update connection',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<Map<String, dynamic>?> makeProgressRoll(String connectionId) async {
    try {
      return await gameProvider.makeConnectionProgressRoll(connectionId);
    } catch (e) {
      LoggingService().error('Failed to make progress roll',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<bool> bondConnection(String connectionId) async {
    try {
      await gameProvider.bondConnection(connectionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to bond connection',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> loseConnection(String connectionId) async {
    try {
      await gameProvider.loseConnection(connectionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to lose connection',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> deleteConnection(String connectionId) async {
    try {
      await gameProvider.deleteConnection(connectionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to delete connection',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> addTicksForRank(String connectionId) async {
    try {
      await gameProvider.addConnectionTicksForRank(connectionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to add ticks for rank',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> removeTicksForRank(String connectionId) async {
    try {
      await gameProvider.removeConnectionTicksForRank(connectionId);
      return true;
    } catch (e) {
      LoggingService().error('Failed to remove ticks for rank',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> updateProgress(String connectionId, int progress) async {
    try {
      await gameProvider.updateConnectionProgress(connectionId, progress);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update connection progress',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<bool> updateNotes(String connectionId, String notes) async {
    try {
      await gameProvider.updateConnectionNotes(connectionId, notes);
      return true;
    } catch (e) {
      LoggingService().error('Failed to update connection notes',
          tag: 'ConnectionService', error: e, stackTrace: StackTrace.current);
      return false;
    }
  }
}
