import '../providers/datasworn_provider.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../utils/logging_service.dart';

class DataswornLink {
  final String displayText;
  final String linkType; // 'oracle_collection', 'asset', or 'move'
  final String path;

  DataswornLink({
    required this.displayText, 
    required this.linkType,
    required this.path
  });
}

class DataswornLinkParser {
  static final LoggingService _logger = LoggingService();
  
  // Regular expression to match markdown links with datasworn protocol
  // Updated to handle oracle_collection, asset, and move links
  static final RegExp linkPattern = RegExp(
    r'\[(.*?)\]\(datasworn:(oracle_collection|asset|move):(.*?)\)',
    caseSensitive: false,
  );

  // Parse text and extract datasworn links
  static List<DataswornLink> parseLinks(String text) {
    final matches = linkPattern.allMatches(text);
    final links = matches.map((match) {
      final displayText = match.group(1) ?? '';
      final linkType = match.group(2) ?? 'oracle_collection'; // Default to oracle
      final path = match.group(3) ?? '';
      
      _logger.debug(
        'Match groups: ${match.groupCount} groups',
        tag: 'DataswornLinkParser',
      );
      for (int i = 0; i <= match.groupCount; i++) {
        _logger.debug(
          '  Group $i: ${match.group(i)}',
          tag: 'DataswornLinkParser',
        );
      }
      
      return DataswornLink(
        displayText: displayText,
        linkType: linkType,
        path: path
      );
    }).toList();
    
    _logger.debug(
      'parseLinks: text="$text", found ${links.length} links',
      tag: 'DataswornLinkParser',
    );
    for (int i = 0; i < links.length; i++) {
      _logger.debug(
        '  Link $i: displayText="${links[i].displayText}", linkType="${links[i].linkType}", path="${links[i].path}"',
        tag: 'DataswornLinkParser',
      );
    }
    
    return links;
  }

  // Check if text contains any datasworn links
  static bool containsLinks(String text) {
    final hasMatch = linkPattern.hasMatch(text);
    _logger.debug(
      'containsLinks: text="$text", hasMatch=$hasMatch',
      tag: 'DataswornLinkParser',
    );
    return hasMatch;
  }

  // Find an oracle table by its path
  static OracleTable? findOracleByPath(DataswornProvider provider, String path) {
    // Split the path into parts
    final parts = path.split('/');
    if (parts.isEmpty) return null;

    // The last part is the table ID
    final tableId = parts.last;
    
    // Enable debug logging
    const bool debugLogging = true;
    if (debugLogging) {
      _logOracleSearch(path, tableId);
    }
    
    OracleTable? result;
    
    // Special case for node_type paths: they might need modifications
    if (path.contains('node_type')) {
      // Try the original path first
      result = _findTableByExactPath(provider, path);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle by exact node_type path: ${result.id}',
          tag: 'DataswornLinkParser',
        );
      }
      
      // If not found, try with /collections/ inserted before the last segment
      if (result == null) {
        final parts = path.split('/');
        if (parts.length >= 3) {
          final lastPart = parts.removeLast();
          parts.add('collections');
          parts.add(lastPart);
          final pathWithCollections = parts.join('/');
          
          _logger.debug(
            'Trying path with /collections/ inserted: $pathWithCollections',
            tag: 'DataswornLinkParser',
          );
          result = _findTableByExactPath(provider, pathWithCollections);
          if (result != null && debugLogging) {
            _logger.debug(
              'Found oracle by inserting /collections/: $pathWithCollections',
              tag: 'DataswornLinkParser',
            );
          }
        }
      }
      
      // If still not found, try appending "/area"
      if (result == null) {
        final pathWithArea = '$path/area';
        _logger.debug(
          'Trying path with /area appended: $pathWithArea',
          tag: 'DataswornLinkParser',
        );
        result = _findTableByExactPath(provider, pathWithArea);
        if (result != null && debugLogging) {
          _logger.debug(
            'Found oracle by appending /area: $pathWithArea',
            tag: 'DataswornLinkParser',
          );
        }
      }
    } else {
      // First attempt: Try to find the table by the exact path
      result = _findTableByExactPath(provider, path);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle by exact path: ${result.id}',
          tag: 'DataswornLinkParser',
        );
      }
    }
    
    // Second attempt: Try to find the table by the last part of the path
    if (result == null) {
      result = _findTableByLastPart(provider, tableId);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle by last part: ${result.id}',
          tag: 'DataswornLinkParser',
        );
      }
    }
    
    // Third attempt: If the path contains "oracle_collection", try to find it under "oracles"
    if (result == null && path.contains('oracle_collection')) {
      // For paths like "fe_runners/node_type/social", look for "oracles/social"
      result = _findTableUnderOracles(provider, tableId);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle under oracles path: ${result.id}',
          tag: 'DataswornLinkParser',
        );
      }
    }
    
    // Fourth attempt: Try to find it under "oracles/node_type/collections/{oracle name}"
    if (result == null) {
      result = _findTableUnderNodeTypeCollections(provider, tableId);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle under node_type/collections: ${result.id}',
          tag: 'DataswornLinkParser',
        );
      }
    }
    
    // Fifth attempt: If it's a node_type path, try with "/feature" appended
    if (result == null && path.contains('node_type')) {
      final pathWithFeature = '$path/feature';
      _logger.debug(
        'Trying path with /feature appended: $pathWithFeature',
        tag: 'DataswornLinkParser',
      );
      result = _findTableByExactPath(provider, pathWithFeature);
      if (result != null && debugLogging) {
        _logger.debug(
          'Found oracle by appending /feature: $pathWithFeature',
          tag: 'DataswornLinkParser',
        );
      }
      
      // If still not found, try with /collections/ inserted and /area appended
      if (result == null) {
        final parts = path.split('/');
        if (parts.length >= 3) {
          final lastPart = parts.removeLast();
          parts.add('collections');
          parts.add(lastPart);
          final pathWithCollectionsAndArea = '${parts.join('/')}/area';
          
          _logger.debug(
            'Trying path with /collections/ inserted and /area appended: $pathWithCollectionsAndArea',
            tag: 'DataswornLinkParser',
          );
          result = _findTableByExactPath(provider, pathWithCollectionsAndArea);
          if (result != null && debugLogging) {
            _logger.debug(
              'Found oracle by inserting /collections/ and appending /area: $pathWithCollectionsAndArea',
              tag: 'DataswornLinkParser',
            );
          }
        }
      }
    }
    
    if (result == null && debugLogging) {
      _logger.debug(
        'Oracle not found for path: $path',
        tag: 'DataswornLinkParser',
      );
      _logAvailableOracles(provider);
    }
    
    return result;
  }
  
  // Log information about the oracle search
  static void _logOracleSearch(String path, String tableId) {
    _logger.debug(
      'Searching for oracle with path: $path',
      tag: 'DataswornLinkParser',
    );
    _logger.debug(
      'Table ID extracted: $tableId',
      tag: 'DataswornLinkParser',
    );
  }
  
  // Log available oracles for debugging
  static void _logAvailableOracles(DataswornProvider provider) {
    _logger.debug(
      'Available oracles:',
      tag: 'DataswornLinkParser',
    );
    for (final category in provider.oracles) {
      _logger.debug(
        '  Category: ${category.id} (${category.name})',
        tag: 'DataswornLinkParser',
      );
      for (final table in category.tables) {
        _logger.debug(
          '    Table: ${table.id} (${table.name})',
          tag: 'DataswornLinkParser',
        );
      }
    }
  }
  
  // Try to find a table by exact path match
  static OracleTable? _findTableByExactPath(DataswornProvider provider, String path) {
    for (final category in provider.oracles) {
      for (final table in category.tables) {
        if (table.id == path || table.id.endsWith('/$path')) {
          return table;
        }
      }
    }
    return null;
  }
  
  // Try to find a table by the last part of the path
  static OracleTable? _findTableByLastPart(DataswornProvider provider, String tableId) {
    for (final category in provider.oracles) {
      // Check if the category ID matches
      if (category.id.endsWith(tableId)) {
        // If the category matches and has tables, return the first table
        if (category.tables.isNotEmpty) {
          return category.tables.first;
        }
      }
      
      // Check all tables in the category
      for (final table in category.tables) {
        if (table.id.endsWith(tableId)) {
          return table;
        }
      }
    }
    return null;
  }
  
  // Try to find a table under the "oracles" path
  static OracleTable? _findTableUnderOracles(DataswornProvider provider, String tableId) {
    final lowerTableId = tableId.toLowerCase();
    
    // First, look for a category that directly matches the tableId
    for (final category in provider.oracles) {
      final lowerCategoryName = category.name.toLowerCase();
      final lowerCategoryId = category.id.toLowerCase();
      
      // Check for exact category match
      if (lowerCategoryName == lowerTableId || 
          lowerCategoryId.endsWith('/$lowerTableId') ||
          lowerCategoryId.endsWith(lowerTableId)) {
        if (category.tables.isNotEmpty) {
          _logger.debug(
            'Found exact category match: ${category.id} (${category.name})',
            tag: 'DataswornLinkParser',
          );
          return category.tables.first;
        }
      }
    }
    
    // Look for tables under a category that might match our target
    for (final category in provider.oracles) {
      // Check if this category might be related to our target
      if (category.id.toLowerCase().contains(lowerTableId) || 
          category.name.toLowerCase().contains(lowerTableId)) {
        if (category.tables.isNotEmpty) {
          _logger.debug(
            'Found related category: ${category.id} (${category.name})',
            tag: 'DataswornLinkParser',
          );
          return category.tables.first;
        }
      }
      
      // Check all tables in the category
      for (final table in category.tables) {
        if (table.id.toLowerCase().contains(lowerTableId) || 
            table.name.toLowerCase().contains(lowerTableId)) {
          _logger.debug(
            'Found related table: ${table.id} (${table.name})',
            tag: 'DataswornLinkParser',
          );
          return table;
        }
      }
    }
    
    // Try a more aggressive search by looking for any partial match
    for (final category in provider.oracles) {
      for (final table in category.tables) {
        // Check if any part of the table name or ID contains our target
        if (table.name.toLowerCase().contains(lowerTableId) || 
            table.id.toLowerCase().contains(lowerTableId)) {
          _logger.debug(
            'Found partial match: ${table.id} (${table.name})',
            tag: 'DataswornLinkParser',
          );
          return table;
        }
      }
    }
    
    return null;
  }
  
  // Try to find a table under "oracles/node_type/collections/{oracle name}"
  static OracleTable? _findTableUnderNodeTypeCollections(DataswornProvider provider, String tableId) {
    final lowerTableId = tableId.toLowerCase();
    
    _logger.debug(
      'Searching specifically for oracle in node_type/collections with ID: $tableId',
      tag: 'DataswornLinkParser',
    );
    
    // First, try to find a direct match in a path containing node_type/collections
    String specificPath = 'oracles/node_type/collections/$tableId';
    _logger.debug(
      'Looking for specific path: $specificPath',
      tag: 'DataswornLinkParser',
    );
    
    // Look for categories or tables with paths containing node_type/collections
    for (final category in provider.oracles) {
      final categoryId = category.id;
      
      // Log all categories to help with debugging
      _logger.debug(
        'Checking category: $categoryId',
        tag: 'DataswornLinkParser',
      );
      
      // Check if this category is under node_type/collections
      if (categoryId.toLowerCase().contains('node_type') && 
          categoryId.toLowerCase().contains('collection')) {
        _logger.debug(
          'Found node_type/collections category: $categoryId',
          tag: 'DataswornLinkParser',
        );
        
        // Check if this category matches our target directly
        if (categoryId.toLowerCase().contains(lowerTableId)) {
          if (category.tables.isNotEmpty) {
            _logger.debug(
              'Found exact match in node_type collection: $categoryId',
              tag: 'DataswornLinkParser',
            );
            return category.tables.first;
          }
        }
        
        // Check all tables in this category
        for (final table in category.tables) {
          _logger.debug(
            'Checking table: ${table.id}',
            tag: 'DataswornLinkParser',
          );
          
          // Check for direct match
          if (table.id.toLowerCase().contains(lowerTableId)) {
            _logger.debug(
              'Found direct table match in node_type collection: ${table.id}',
              tag: 'DataswornLinkParser',
            );
            return table;
          }
          
          // Check for name match
          if (table.name.toLowerCase().contains(lowerTableId)) {
            _logger.debug(
              'Found table name match in node_type collection: ${table.name}',
              tag: 'DataswornLinkParser',
            );
            return table;
          }
        }
      }
    }
    
    // If we still haven't found it, try a more aggressive approach
    _logger.debug(
      'Trying more aggressive search for node_type/collections',
      tag: 'DataswornLinkParser',
    );
    
    // Look for any category that might be related to node_type
    for (final category in provider.oracles) {
      if (category.id.toLowerCase().contains('node') || 
          category.id.toLowerCase().contains('type') ||
          category.name.toLowerCase().contains('node')) {
        
        _logger.debug(
          'Found potential node-related category: ${category.id}',
          tag: 'DataswornLinkParser',
        );
        
        // Check if any table in this category matches our target
        for (final table in category.tables) {
          if (table.name.toLowerCase().contains(lowerTableId) || 
              table.id.toLowerCase().contains(lowerTableId)) {
            _logger.debug(
              'Found related table in node category: ${table.id}',
              tag: 'DataswornLinkParser',
            );
            return table;
          }
        }
      }
    }
    
    _logger.debug(
      'No match found in node_type/collections',
      tag: 'DataswornLinkParser',
    );
    return null;
  }
  
  // Find an asset by its path
  static Asset? findAssetByPath(DataswornProvider provider, String path) {
    // Enable debug logging
    const bool debugLogging = true;
    if (debugLogging) {
      _logger.debug(
        'Searching for asset with path: $path',
        tag: 'DataswornLinkParser',
      );
    }
    
    // First try direct match with the full path
    Asset? asset = provider.findAssetById(path);
    if (asset != null && debugLogging) {
      _logger.debug(
        'Found asset by exact path: ${asset.id}',
        tag: 'DataswornLinkParser',
      );
      return asset;
    }
    
    // If not found, try with just the last part of the path
    final parts = path.split('/');
    if (parts.isNotEmpty) {
      final assetId = parts.last;
      asset = provider.findAssetById(assetId);
      if (asset != null && debugLogging) {
        _logger.debug(
          'Found asset by last part: ${asset.id}',
          tag: 'DataswornLinkParser',
        );
        return asset;
      }
    }
    
    // If still not found, try a more flexible approach
    // For paths like "fe_runners/path/admin", try to find an asset with "admin" in the name
    if (parts.isNotEmpty) {
      final assetName = parts.last;
      for (final a in provider.assets) {
        if (a.name.toLowerCase().contains(assetName.toLowerCase())) {
          if (debugLogging) {
            _logger.debug(
              'Found asset by name match: ${a.id} (${a.name})',
              tag: 'DataswornLinkParser',
            );
          }
          return a;
        }
      }
    }
    
    // If we still haven't found it, try a more aggressive approach
    // Look for any asset that might be related to the path
    for (final a in provider.assets) {
      if (a.id.toLowerCase().contains(path.toLowerCase()) || 
          path.toLowerCase().contains(a.id.toLowerCase())) {
        if (debugLogging) {
          _logger.debug(
            'Found asset by partial ID match: ${a.id} (${a.name})',
            tag: 'DataswornLinkParser',
          );
        }
        return a;
      }
    }
    
    if (debugLogging) {
      _logger.debug(
        'Asset not found for path: $path',
        tag: 'DataswornLinkParser',
      );
      _logAvailableAssets(provider);
    }
    
    return null;
  }
  
  // Log available assets for debugging
  static void _logAvailableAssets(DataswornProvider provider) {
    _logger.debug(
      'Available assets:',
      tag: 'DataswornLinkParser',
    );
    for (final asset in provider.assets) {
      _logger.debug(
        '  Asset: ${asset.id} (${asset.name}) - ${asset.category}',
        tag: 'DataswornLinkParser',
      );
    }
  }
}
