import 'dart:developer' as developer;
import '../providers/datasworn_provider.dart';
import '../models/oracle.dart';

class DataswornLink {
  final String displayText;
  final String path;

  DataswornLink({required this.displayText, required this.path});
}

class DataswornLinkParser {
  // Regular expression to match markdown links with datasworn protocol
  static final RegExp linkPattern = RegExp(
    r'\[(.*?)\]\(datasowrn:oracle_collection:(.*?)\)',
    caseSensitive: false,
  );

  // Parse text and extract datasworn links
  static List<DataswornLink> parseLinks(String text) {
    final matches = linkPattern.allMatches(text);
    return matches.map((match) {
      final displayText = match.group(1) ?? '';
      final path = match.group(2) ?? '';
      return DataswornLink(displayText: displayText, path: path);
    }).toList();
  }

  // Check if text contains any datasworn links
  static bool containsLinks(String text) {
    return linkPattern.hasMatch(text);
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
        developer.log('Found oracle by exact node_type path: ${result.id}');
      }
      
      // If not found, try with /collections/ inserted before the last segment
      if (result == null) {
        final parts = path.split('/');
        if (parts.length >= 3) {
          final lastPart = parts.removeLast();
          parts.add('collections');
          parts.add(lastPart);
          final pathWithCollections = parts.join('/');
          
          developer.log('Trying path with /collections/ inserted: $pathWithCollections');
          result = _findTableByExactPath(provider, pathWithCollections);
          if (result != null && debugLogging) {
            developer.log('Found oracle by inserting /collections/: $pathWithCollections');
          }
        }
      }
      
      // If still not found, try appending "/area"
      if (result == null) {
        final pathWithArea = '$path/area';
        developer.log('Trying path with /area appended: $pathWithArea');
        result = _findTableByExactPath(provider, pathWithArea);
        if (result != null && debugLogging) {
          developer.log('Found oracle by appending /area: $pathWithArea');
        }
      }
    } else {
      // First attempt: Try to find the table by the exact path
      result = _findTableByExactPath(provider, path);
      if (result != null && debugLogging) {
        developer.log('Found oracle by exact path: ${result.id}');
      }
    }
    
    // Second attempt: Try to find the table by the last part of the path
    if (result == null) {
      result = _findTableByLastPart(provider, tableId);
      if (result != null && debugLogging) {
        developer.log('Found oracle by last part: ${result.id}');
      }
    }
    
    // Third attempt: If the path contains "oracle_collection", try to find it under "oracles"
    if (result == null && path.contains('oracle_collection')) {
      // For paths like "fe_runners/node_type/social", look for "oracles/social"
      result = _findTableUnderOracles(provider, tableId);
      if (result != null && debugLogging) {
        developer.log('Found oracle under oracles path: ${result.id}');
      }
    }
    
    // Fourth attempt: Try to find it under "oracles/node_type/collections/{oracle name}"
    if (result == null) {
      result = _findTableUnderNodeTypeCollections(provider, tableId);
      if (result != null && debugLogging) {
        developer.log('Found oracle under node_type/collections: ${result.id}');
      }
    }
    
    // Fifth attempt: If it's a node_type path, try with "/feature" appended
    if (result == null && path.contains('node_type')) {
      final pathWithFeature = '$path/feature';
      developer.log('Trying path with /feature appended: $pathWithFeature');
      result = _findTableByExactPath(provider, pathWithFeature);
      if (result != null && debugLogging) {
        developer.log('Found oracle by appending /feature: $pathWithFeature');
      }
      
      // If still not found, try with /collections/ inserted and /area appended
      if (result == null) {
        final parts = path.split('/');
        if (parts.length >= 3) {
          final lastPart = parts.removeLast();
          parts.add('collections');
          parts.add(lastPart);
          final pathWithCollectionsAndArea = '${parts.join('/')}/area';
          
          developer.log('Trying path with /collections/ inserted and /area appended: $pathWithCollectionsAndArea');
          result = _findTableByExactPath(provider, pathWithCollectionsAndArea);
          if (result != null && debugLogging) {
            developer.log('Found oracle by inserting /collections/ and appending /area: $pathWithCollectionsAndArea');
          }
        }
      }
    }
    
    if (result == null && debugLogging) {
      developer.log('Oracle not found for path: $path');
      _logAvailableOracles(provider);
    }
    
    return result;
  }
  
  // Log information about the oracle search
  static void _logOracleSearch(String path, String tableId) {
    developer.log('Searching for oracle with path: $path');
    developer.log('Table ID extracted: $tableId');
  }
  
  // Log available oracles for debugging
  static void _logAvailableOracles(DataswornProvider provider) {
    developer.log('Available oracles:');
    for (final category in provider.oracles) {
      developer.log('  Category: ${category.id} (${category.name})');
      for (final table in category.tables) {
        developer.log('    Table: ${table.id} (${table.name})');
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
          developer.log('Found exact category match: ${category.id} (${category.name})');
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
          developer.log('Found related category: ${category.id} (${category.name})');
          return category.tables.first;
        }
      }
      
      // Check all tables in the category
      for (final table in category.tables) {
        if (table.id.toLowerCase().contains(lowerTableId) || 
            table.name.toLowerCase().contains(lowerTableId)) {
          developer.log('Found related table: ${table.id} (${table.name})');
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
          developer.log('Found partial match: ${table.id} (${table.name})');
          return table;
        }
      }
    }
    
    return null;
  }
  
  // Try to find a table under "oracles/node_type/collections/{oracle name}"
  static OracleTable? _findTableUnderNodeTypeCollections(DataswornProvider provider, String tableId) {
    final lowerTableId = tableId.toLowerCase();
    
    developer.log('Searching specifically for oracle in node_type/collections with ID: $tableId');
    
    // First, try to find a direct match in a path containing node_type/collections
    String specificPath = 'oracles/node_type/collections/$tableId';
    developer.log('Looking for specific path: $specificPath');
    
    // Look for categories or tables with paths containing node_type/collections
    for (final category in provider.oracles) {
      final categoryId = category.id;
      
      // Log all categories to help with debugging
      developer.log('Checking category: $categoryId');
      
      // Check if this category is under node_type/collections
      if (categoryId.toLowerCase().contains('node_type') && 
          categoryId.toLowerCase().contains('collection')) {
        developer.log('Found node_type/collections category: $categoryId');
        
        // Check if this category matches our target directly
        if (categoryId.toLowerCase().contains(lowerTableId)) {
          if (category.tables.isNotEmpty) {
            developer.log('Found exact match in node_type collection: $categoryId');
            return category.tables.first;
          }
        }
        
        // Check all tables in this category
        for (final table in category.tables) {
          developer.log('Checking table: ${table.id}');
          
          // Check for direct match
          if (table.id.toLowerCase().contains(lowerTableId)) {
            developer.log('Found direct table match in node_type collection: ${table.id}');
            return table;
          }
          
          // Check for name match
          if (table.name.toLowerCase().contains(lowerTableId)) {
            developer.log('Found table name match in node_type collection: ${table.name}');
            return table;
          }
        }
      }
    }
    
    // If we still haven't found it, try a more aggressive approach
    developer.log('Trying more aggressive search for node_type/collections');
    
    // Look for any category that might be related to node_type
    for (final category in provider.oracles) {
      if (category.id.toLowerCase().contains('node') || 
          category.id.toLowerCase().contains('type') ||
          category.name.toLowerCase().contains('node')) {
        
        developer.log('Found potential node-related category: ${category.id}');
        
        // Check if any table in this category matches our target
        for (final table in category.tables) {
          if (table.name.toLowerCase().contains(lowerTableId) || 
              table.id.toLowerCase().contains(lowerTableId)) {
            developer.log('Found related table in node category: ${table.id}');
            return table;
          }
        }
      }
    }
    
    developer.log('No match found in node_type/collections');
    return null;
  }
}
