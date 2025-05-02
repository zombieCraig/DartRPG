import 'package:flutter/material.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../models/node_type_info.dart';
import '../models/truth.dart';
import '../utils/datasworn_parser.dart';
import '../utils/logging_service.dart';

class DataswornProvider extends ChangeNotifier {
  List<Move> _moves = [];
  List<OracleCategory> _oracles = [];
  List<Asset> _assets = [];
  List<Truth> _truths = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSource;
  bool _customOraclesLoaded = false;

  List<Move> get moves => _moves;
  List<OracleCategory> get oracles => _oracles;
  List<Asset> get assets => _assets;
  List<Truth> get truths => _truths;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSource => _currentSource;
  bool get customOraclesLoaded => _customOraclesLoaded;

  // Load data from a Datasworn JSON file
  Future<void> loadDatasworn(String assetPath) async {
    final loggingService = LoggingService();
    loggingService.debug('Loading Datasworn data from: $assetPath', tag: 'DataswornProvider');
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final datasworn = await DataswornParser.loadDataswornJson(assetPath);
      loggingService.debug('Successfully loaded JSON data', tag: 'DataswornProvider');
      
      _moves = DataswornParser.parseMoves(datasworn);
      loggingService.debug('Parsed ${_moves.length} moves', tag: 'DataswornProvider');
      
      _oracles = DataswornParser.parseOracles(datasworn);
      loggingService.debug('Parsed ${_oracles.length} oracle categories', tag: 'DataswornProvider');
      
      // Log oracle categories and their tables
      for (final category in _oracles) {
        loggingService.debug('Oracle category: ${category.name} with ${category.tables.length} tables and ${category.subcategories.length} subcategories', tag: 'DataswornProvider');
        
        // Log subcategories if any
        for (final subcategory in category.subcategories) {
          loggingService.debug('  Subcategory: ${subcategory.name} with ${subcategory.tables.length} tables', tag: 'DataswornProvider');
          
          // Log tables in subcategory
          for (final table in subcategory.tables) {
            loggingService.debug('    Table: ${table.name}', tag: 'DataswornProvider');
          }
        }
        
        // Log tables in category
        for (final table in category.tables) {
          loggingService.debug('  Table: ${table.name}', tag: 'DataswornProvider');
        }
      }
      
      _assets = DataswornParser.parseAssets(datasworn);
      loggingService.debug('Parsed ${_assets.length} assets', tag: 'DataswornProvider');
      
      _truths = DataswornParser.parseTruths(datasworn);
      loggingService.debug('Parsed ${_truths.length} truths', tag: 'DataswornProvider');
      
      _currentSource = assetPath;
      
      _isLoading = false;
      notifyListeners();
      
      loggingService.debug('Datasworn data loaded successfully', tag: 'DataswornProvider');
    } catch (e) {
      loggingService.error('Failed to load Datasworn data: ${e.toString()}', tag: 'DataswornProvider');
      _isLoading = false;
      _error = 'Failed to load Datasworn data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Load custom oracles from the custom_oracles.json file
  Future<void> loadCustomOracles() async {
    final loggingService = LoggingService();
    loggingService.debug('Loading custom oracles', tag: 'DataswornProvider');
    
    if (_customOraclesLoaded) {
      loggingService.debug('Custom oracles already loaded, skipping', tag: 'DataswornProvider');
      return;
    }
    
    try {
      final customData = await DataswornParser.loadDataswornJson('assets/data/custom_oracles.json');
      loggingService.debug('Successfully loaded custom oracles JSON data', tag: 'DataswornProvider');
      
      final customOracles = DataswornParser.parseCustomOracles(customData);
      loggingService.debug('Parsed ${customOracles.length} custom oracle categories', tag: 'DataswornProvider');
      
      // Log custom oracle categories and their tables
      for (final category in customOracles) {
        loggingService.debug('Custom oracle category: ${category.name} with ${category.tables.length} tables and ${category.subcategories.length} subcategories', tag: 'DataswornProvider');
        
        // Log subcategories if any
        for (final subcategory in category.subcategories) {
          loggingService.debug('  Custom subcategory: ${subcategory.name} with ${subcategory.tables.length} tables', tag: 'DataswornProvider');
          
          // Log tables in subcategory
          for (final table in subcategory.tables) {
            loggingService.debug('    Custom table: ${table.name}', tag: 'DataswornProvider');
          }
        }
        
        // Log tables in category
        for (final table in category.tables) {
          loggingService.debug('  Custom table: ${table.name}', tag: 'DataswornProvider');
        }
      }
      
      // Merge custom oracles with existing oracles
      _oracles.addAll(customOracles);
      loggingService.debug('Merged ${customOracles.length} custom oracle categories with existing oracles', tag: 'DataswornProvider');
      
      _customOraclesLoaded = true;
      notifyListeners();
      
      loggingService.debug('Custom oracles loaded successfully', tag: 'DataswornProvider');
    } catch (e) {
      loggingService.error('Failed to load custom oracles: ${e.toString()}', tag: 'DataswornProvider');
      // Don't set _error here, as we don't want to show an error to the user if custom oracles fail to load
      // The app should still function with just the standard oracles
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
    final loggingService = LoggingService();
    loggingService.debug('Finding oracle table by ID: $id', tag: 'DataswornProvider');
    
    // First, search in top-level categories
    for (final category in _oracles) {
      try {
        final table = category.tables.firstWhere((table) => table.id == id);
        loggingService.debug('Found table in category ${category.name}', tag: 'DataswornProvider');
        return table;
      } catch (e) {
        // Continue to next category
      }
      
      // Search in subcategories
      for (final subcategory in category.subcategories) {
        try {
          final table = subcategory.tables.firstWhere((table) => table.id == id);
          loggingService.debug('Found table in subcategory ${subcategory.name}', tag: 'DataswornProvider');
          return table;
        } catch (e) {
          // Continue to next subcategory
        }
      }
    }
    
    loggingService.debug('Oracle table not found with ID: $id', tag: 'DataswornProvider');
    return null;
  }
  
  // Find an oracle table by name
  OracleTable? findOracleTableByName(String name) {
    final loggingService = LoggingService();
    loggingService.debug('Finding oracle table by name: $name', tag: 'DataswornProvider');
    
    // First, search in top-level categories
    for (final category in _oracles) {
      try {
        final table = category.tables.firstWhere(
          (table) => table.name.toLowerCase() == name.toLowerCase()
        );
        loggingService.debug('Found table in category ${category.name}', tag: 'DataswornProvider');
        return table;
      } catch (e) {
        // Continue to next category
      }
      
      // Search in subcategories
      for (final subcategory in category.subcategories) {
        try {
          final table = subcategory.tables.firstWhere(
            (table) => table.name.toLowerCase() == name.toLowerCase()
          );
          loggingService.debug('Found table in subcategory ${subcategory.name}', tag: 'DataswornProvider');
          return table;
        } catch (e) {
          // Continue to next subcategory
        }
      }
    }
    
    // If exact match not found, try contains match
    for (final category in _oracles) {
      try {
        final table = category.tables.firstWhere(
          (table) => table.name.toLowerCase().contains(name.toLowerCase())
        );
        loggingService.debug('Found table with partial name match in category ${category.name}', tag: 'DataswornProvider');
        return table;
      } catch (e) {
        // Continue to next category
      }
      
      // Search in subcategories
      for (final subcategory in category.subcategories) {
        try {
          final table = subcategory.tables.firstWhere(
            (table) => table.name.toLowerCase().contains(name.toLowerCase())
          );
          loggingService.debug('Found table with partial name match in subcategory ${subcategory.name}', tag: 'DataswornProvider');
          return table;
        } catch (e) {
          // Continue to next subcategory
        }
      }
    }
    
    loggingService.debug('Oracle table not found with name: $name', tag: 'DataswornProvider');
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
  
  // Find a truth by ID
  Truth? findTruthById(String id) {
    try {
      return _truths.firstWhere((truth) => truth.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get all node types from oracle collections
  List<NodeTypeInfo> getAllNodeTypes() {
    final loggingService = LoggingService();
    final List<NodeTypeInfo> nodeTypes = [];
    
    // Log all top-level categories to help with debugging
    loggingService.debug(
      'Oracle categories: ${_oracles.map((c) => "${c.id}: ${c.name} (${c.subcategories.length} subcategories)").join(", ")}',
      tag: 'DataswornProvider',
    );
    
    // Method 1: Find the node_type category by ID
    try {
      final nodeTypeCategory = _oracles.firstWhere(
        (category) => category.id == 'node_type',
      );
      
      loggingService.debug(
        'Found node_type category by ID: ${nodeTypeCategory.name} with ${nodeTypeCategory.subcategories.length} subcategories',
        tag: 'DataswornProvider',
      );
      
      // Add all subcategories as node types
      for (final subcategory in nodeTypeCategory.subcategories) {
        // Extract the key from the subcategory ID
        final key = subcategory.id;
        
        nodeTypes.add(NodeTypeInfo(
          key: key,
          displayName: subcategory.name,
        ));
        
        loggingService.debug(
          'Added node type: ${subcategory.name} (${subcategory.id})',
          tag: 'DataswornProvider',
        );
      }
    } catch (e) {
      loggingService.warning(
        'No node_type category found by ID: ${e.toString()}',
        tag: 'DataswornProvider',
      );
      
      // Method 2: Try to find by name if ID search failed
      try {
        final nodeTypeCategory = _oracles.firstWhere(
          (category) => category.name.toLowerCase().contains('node type'),
        );
        
        loggingService.debug(
          'Found node_type category by name: ${nodeTypeCategory.name} with ${nodeTypeCategory.subcategories.length} subcategories',
          tag: 'DataswornProvider',
        );
        
        // Add all subcategories as node types
        for (final subcategory in nodeTypeCategory.subcategories) {
          nodeTypes.add(NodeTypeInfo(
            key: subcategory.id,
            displayName: subcategory.name,
          ));
          
          loggingService.debug(
            'Added node type: ${subcategory.name} (${subcategory.id})',
            tag: 'DataswornProvider',
          );
        }
      } catch (e2) {
        loggingService.warning(
          'No node_type category found by name: ${e2.toString()}',
          tag: 'DataswornProvider',
        );
      }
    }
    
    // Sort alphabetically by display name
    nodeTypes.sort((a, b) => a.displayName.compareTo(b.displayName));
    
    loggingService.debug(
      'Returning ${nodeTypes.length} node types',
      tag: 'DataswornProvider',
    );
    
    return nodeTypes;
  }
}
