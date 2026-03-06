import 'package:flutter/foundation.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/models/move.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/character.dart';
import 'package:dart_rpg/models/truth.dart';

/// Shared mock DataswornProvider for widget tests.
///
/// Uses `noSuchMethod` to stub unimplemented methods, so only the
/// properties/methods actually exercised in tests need overrides.
class MockDataswornProvider extends ChangeNotifier implements DataswornProvider {
  final List<Move> _moves = [];
  final List<OracleCategory> _oracles = [];
  final List<Asset> _assets = [];
  final List<Truth> _truths = [];

  @override
  List<Move> get moves => _moves;

  @override
  List<OracleCategory> get oracles => _oracles;

  @override
  List<Asset> get assets => _assets;

  @override
  List<Truth> get truths => _truths;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  String? get currentSource => null;

  /// Add test moves.
  void addTestMoves(List<Move> moves) {
    _moves.clear();
    _moves.addAll(moves);
    notifyListeners();
  }

  /// Add test oracle categories.
  void addTestOracles(List<OracleCategory> oracles) {
    _oracles.clear();
    _oracles.addAll(oracles);
    notifyListeners();
  }

  /// Add test assets.
  void addTestAssets(List<Asset> assets) {
    _assets.clear();
    _assets.addAll(assets);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
