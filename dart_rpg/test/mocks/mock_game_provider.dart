import 'package:flutter/foundation.dart';
import 'package:dart_rpg/providers/game_provider.dart';
import 'package:dart_rpg/models/game.dart';
import 'package:dart_rpg/models/game_summary.dart';
import 'package:dart_rpg/models/session.dart';

/// Shared mock GameProvider for widget tests.
///
/// Uses `noSuchMethod` to stub unimplemented methods, so only the
/// properties/methods actually exercised in tests need overrides.
class MockGameProvider extends ChangeNotifier implements GameProvider {
  Game? _currentGame;
  Session? _currentSession;

  @override
  Game? get currentGame => _currentGame;

  @override
  Session? get currentSession => _currentSession;

  @override
  List<Game> get games => _currentGame != null ? [_currentGame!] : [];

  @override
  List<GameSummary> get gameSummaries =>
      _currentGame != null ? [GameSummary.fromGame(_currentGame!)] : [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> saveGame() async {}

  /// Set the current game for testing.
  void setCurrentGameForTest(Game game) {
    _currentGame = game;
    notifyListeners();
  }

  /// Set the current session for testing.
  void setCurrentSessionForTest(Session session) {
    _currentSession = session;
    notifyListeners();
  }

  @override
  Future<void> updateBaseRigAssets(dynamic dataswornProvider) async {}

  @override
  Future<void> updateLocationPosition(String locationId, double x, double y) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
