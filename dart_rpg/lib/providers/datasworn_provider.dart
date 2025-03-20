import 'package:flutter/material.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../utils/datasworn_parser.dart';

class DataswornProvider extends ChangeNotifier {
  List<Move> _moves = [];
  List<OracleCategory> _oracles = [];
  List<Asset> _assets = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSource;

  List<Move> get moves => _moves;
  List<OracleCategory> get oracles => _oracles;
  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSource => _currentSource;

  // Load data from a Datasworn JSON file
  Future<void> loadDatasworn(String assetPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final datasworn = await DataswornParser.loadDataswornJson(assetPath);
      
      _moves = DataswornParser.parseMoves(datasworn);
      _oracles = DataswornParser.parseOracles(datasworn);
      _assets = DataswornParser.parseAssets(datasworn);
      _currentSource = assetPath;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load Datasworn data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get moves by category
  Map<String, List<Move>> getMovesByCategory() {
    final Map<String, List<Move>> movesByCategory = {};
    
    for (final move in _moves) {
      final category = move.category ?? 'Uncategorized';
      if (!movesByCategory.containsKey(category)) {
        movesByCategory[category] = [];
      }
      movesByCategory[category]!.add(move);
    }
    
    return movesByCategory;
  }

  // Get assets by category
  Map<String, List<Asset>> getAssetsByCategory() {
    final Map<String, List<Asset>> assetsByCategory = {};
    
    for (final asset in _assets) {
      final category = asset.category;
      if (!assetsByCategory.containsKey(category)) {
        assetsByCategory[category] = [];
      }
      assetsByCategory[category]!.add(asset);
    }
    
    return assetsByCategory;
  }

  // Find a move by ID
  Move? findMoveById(String id) {
    try {
      return _moves.firstWhere((move) => move.id == id);
    } catch (e) {
      return null;
    }
  }

  // Find an oracle table by ID
  OracleTable? findOracleTableById(String id) {
    for (final category in _oracles) {
      try {
        return category.tables.firstWhere((table) => table.id == id);
      } catch (e) {
        // Continue to next category
      }
    }
    return null;
  }

  // Find an asset by ID
  Asset? findAssetById(String id) {
    try {
      return _assets.firstWhere((asset) => asset.id == id);
    } catch (e) {
      return null;
    }
  }
}
