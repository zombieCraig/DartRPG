import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../utils/logging_service.dart';

class DataswornParser {
  // Load and parse the Datasworn JSON file
  static Future<Map<String, dynamic>> loadDataswornJson(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    return jsonDecode(jsonString);
  }

  // Parse moves from the Datasworn JSON
  static List<Move> parseMoves(Map<String, dynamic> datasworn) {
    final List<Move> moves = [];
    
    if (datasworn['moves'] != null) {
      datasworn['moves'].forEach((categoryId, categoryJson) {
        if (categoryJson['contents'] != null) {
          categoryJson['contents'].forEach((moveId, moveJson) {
            if (moveJson['type'] == 'move') {
              final move = Move.fromDatasworn(moveJson, moveId);
              move.category = categoryJson['name'];
              moves.add(move);
            }
          });
        }
      });
    }
    
    return moves;
  }

  // Parse oracles from the Datasworn JSON
  static List<OracleCategory> parseOracles(Map<String, dynamic> datasworn) {
    final loggingService = LoggingService();
    final List<OracleCategory> categories = [];
    
    // Process oracles section
    if (datasworn['oracles'] != null) {
      datasworn['oracles'].forEach((categoryId, categoryJson) {
        if (categoryJson['type'] == 'oracle_collection') {
          // Check if this category has collections
          if (categoryJson['collections'] != null && categoryJson['collections'].isNotEmpty) {
            loggingService.debug('Found collections in category: $categoryId', tag: 'DataswornParser');
            
            // Create a category for this collection
            final category = _parseCollectionCategory(categoryJson, categoryId);
            if (category.subcategories.isNotEmpty) {
              categories.add(category);
              loggingService.debug('Added collection category: ${category.name} with ${category.subcategories.length} subcategories', tag: 'DataswornParser');
            }
          } else {
            // Process as a regular category
            final category = OracleCategory.fromDatasworn(categoryJson, categoryId);
            if (category.tables.isNotEmpty || category.subcategories.isNotEmpty) {
              categories.add(category);
            }
          }
        } else if (categoryJson['type'] == 'oracle_rollable') {
          // For oracle_rollable at the top level, create a category with a single table
          final table = OracleTable.fromDatasworn(categoryJson, categoryId);
          final category = OracleCategory(
            id: categoryId,
            name: categoryJson['name'] ?? 'Unknown Category',
            description: categoryJson['summary'],
            tables: [table],
          );
          categories.add(category);
        }
      });
    }
    
    // Process node_type section if it exists
    if (datasworn['node_type'] != null) {
      loggingService.debug('Found node_type section in JSON', tag: 'DataswornParser');
      final nodeTypeJson = datasworn['node_type'];
      final nodeTypeCategory = _parseNodeTypeCategory(nodeTypeJson);
      loggingService.debug('Parsed node_type category: ${nodeTypeCategory.name} with ${nodeTypeCategory.subcategories.length} subcategories', tag: 'DataswornParser');
      categories.add(nodeTypeCategory);
    } else {
      loggingService.debug('No node_type section found in JSON', tag: 'DataswornParser');
      
      // Debug: print all top-level keys in the JSON
      loggingService.debug('Top-level keys in JSON: ${datasworn.keys.join(', ')}', tag: 'DataswornParser');
    }
    
    return categories;
  }
  
  // Parse a category with collections
  static OracleCategory _parseCollectionCategory(Map<String, dynamic> categoryJson, String categoryId) {
    final loggingService = LoggingService();
    final String name = categoryJson['name'] ?? 'Unknown Category';
    final String? description = categoryJson['summary'];
    
    loggingService.debug('Parsing collection category: $name', tag: 'DataswornParser');
    
    List<OracleCategory> subcategories = [];
    
    // Process collections
    if (categoryJson['collections'] != null) {
      loggingService.debug('Found collections with ${categoryJson['collections'].length} items', tag: 'DataswornParser');
      
      categoryJson['collections'].forEach((subcategoryId, subcategoryJson) {
        loggingService.debug('Processing subcategory: $subcategoryId, type: ${subcategoryJson['type']}', tag: 'DataswornParser');
        
        if (subcategoryJson['type'] == 'oracle_collection') {
          final subcategory = _parseCollectionSubcategory(subcategoryJson, subcategoryId);
          loggingService.debug('Parsed subcategory: ${subcategory.name} with ${subcategory.tables.length} tables', tag: 'DataswornParser');
          
          if (subcategory.tables.isNotEmpty || subcategory.subcategories.isNotEmpty) {
            subcategories.add(subcategory);
            loggingService.debug('Added subcategory: ${subcategory.name}', tag: 'DataswornParser');
          }
        }
      });
    }
    
    loggingService.debug('Finished parsing collection category with ${subcategories.length} subcategories', tag: 'DataswornParser');
    
    return OracleCategory(
      id: categoryId,
      name: name,
      description: description,
      tables: [],
      subcategories: subcategories,
    );
  }
  
  // Parse a subcategory within a collection
  static OracleCategory _parseCollectionSubcategory(Map<String, dynamic> subcategoryJson, String subcategoryId) {
    final loggingService = LoggingService();
    final String name = subcategoryJson['name'] ?? 'Unknown Subcategory';
    final String? description = subcategoryJson['summary'];
    
    loggingService.debug('Parsing subcategory: $name (ID: $subcategoryId)', tag: 'DataswornParser');
    
    List<OracleTable> tables = [];
    
    // Process tables in subcategory
    if (subcategoryJson['contents'] != null) {
      loggingService.debug('Found contents in subcategory with ${subcategoryJson['contents'].length} items', tag: 'DataswornParser');
      
      subcategoryJson['contents'].forEach((tableId, tableJson) {
        loggingService.debug('Processing table: $tableId, type: ${tableJson['type']}', tag: 'DataswornParser');
        
        if (tableJson['type'] == 'oracle_rollable') {
          final table = OracleTable.fromDatasworn(tableJson, tableId);
          tables.add(table);
          loggingService.debug('Added table: ${table.name}', tag: 'DataswornParser');
        }
      });
    }
    
    loggingService.debug('Finished parsing subcategory with ${tables.length} tables', tag: 'DataswornParser');
    
    return OracleCategory(
      id: subcategoryId,
      name: name,
      description: description,
      tables: tables,
    );
  }
  
  // Create a Node Type category with subcategories for each node type
  static OracleCategory? _createNodeTypeCategory(Map<String, dynamic> datasworn) {
    final loggingService = LoggingService();
    
    // Check if the oracles section exists
    if (datasworn['oracles'] == null) {
      return null;
    }
    
    // Check if the node_type section exists within the oracles section
    if (datasworn['oracles']['node_type'] == null) {
      loggingService.debug('node_type section not found within oracles', tag: 'DataswornParser');
      return null;
    }
    
    final nodeTypeJson = datasworn['oracles']['node_type'];
    
    
    if (nodeTypeJson['contents'] != null) {
      nodeTypeJson['contents'].forEach((tableId, tableJson) {
        if (tableId == 'core_segment_node_type') {
        }
      });
    }
    
    // Create subcategories for each node type
    List<OracleCategory> nodeTypeSubcategories = [];
    
    // Node types to process
    final nodeTypes = [
      {'id': 'social', 'name': 'Social / Communications'},
      {'id': 'commerce', 'name': 'Commerce'},
      {'id': 'gaming', 'name': 'Gaming'},
      {'id': 'entertainment', 'name': 'Entertainment'},
      {'id': 'education', 'name': 'Education'},
      {'id': 'news', 'name': 'News & Media'},
      {'id': 'science', 'name': 'Science & Research'},
    ];
    
    for (final nodeType in nodeTypes) {
      final subcategory = _createNodeTypeSubcategory(datasworn, nodeType['id']!, nodeType['name']!);
      if (subcategory != null) {
        nodeTypeSubcategories.add(subcategory);
        loggingService.debug('Added subcategory: ${subcategory.name} with ${subcategory.tables.length} tables', tag: 'DataswornParser');
      }
    }
    
    if (nodeTypeSubcategories.isEmpty) {
      loggingService.debug('No node type subcategories created', tag: 'DataswornParser');
      return null;
    }
    
    return OracleCategory(
      id: 'node_type',
      name: 'Node Type',
      description: 'Different types of nodes that can be found in the network',
      tables: [],
      subcategories: nodeTypeSubcategories,
      isNodeType: true,
    );
  }
  
  // Create a subcategory for a specific node type
  static OracleCategory? _createNodeTypeSubcategory(Map<String, dynamic> datasworn, String nodeTypeId, String nodeTypeName) {
    final loggingService = LoggingService();
    List<OracleTable> tables = [];
    
    // Table types to look for
    final tableTypes = ['area', 'feature', 'peril', 'opportunity'];
    
    for (final tableType in tableTypes) {
      final path = 'node_type/$nodeTypeId/$tableType';
      OracleTable? table = _findTableByPath(datasworn, path);
      
      if (table != null) {
        tables.add(table);
        loggingService.debug('Found table: ${table.name} for node type: $nodeTypeName', tag: 'DataswornParser');
      }
    }
    
    if (tables.isEmpty) {
      loggingService.debug('No tables found for node type: $nodeTypeName', tag: 'DataswornParser');
      return null;
    }
    
    return OracleCategory(
      id: 'node_type_$nodeTypeId',
      name: nodeTypeName,
      description: 'Tables for the $nodeTypeName node type',
      tables: tables,
    );
  }
  
  // Find a table by its path in the JSON
  static OracleTable? _findTableByPath(Map<String, dynamic> datasworn, String path) {
    final loggingService = LoggingService();
    
    // Check if the oracles section exists
    if (datasworn['oracles'] == null) {
      return null;
    }
    
    // Check if the node_type section exists within the oracles section
    if (datasworn['oracles']['node_type'] == null) {
      return null;
    }
    
    // Split the path into parts
    final parts = path.split('/');
    if (parts.length < 3) {
      return null;
    }
    
    final nodeTypeId = parts[1];
    final tableType = parts[2];
    
    // Check if the node_type section has contents
    if (datasworn['oracles']['node_type']['contents'] == null) {
      return null;
    }
    
    // Check if the node type exists within the contents
    if (datasworn['oracles']['node_type']['contents'][nodeTypeId] == null) {
      return null;
    }
    
    // Check if the table type exists within the node type
    if (datasworn['oracles']['node_type']['contents'][nodeTypeId][tableType] == null) {
      return null;
    }
    
    // Create the table
    final tableJson = datasworn['oracles']['node_type']['contents'][nodeTypeId][tableType];
    final tableId = 'node_type/$nodeTypeId/$tableType';
    
    try {
      final table = OracleTable.fromDatasworn(tableJson, tableId);
      loggingService.debug('Created table: ${table.name} from path: $path', tag: 'DataswornParser');
      return table;
    } catch (e) {
      loggingService.error('Failed to create table from path: $path', tag: 'DataswornParser', error: e);
      return null;
    }
  }
  
  // Helper method to parse the node_type category
  static OracleCategory _parseNodeTypeCategory(Map<String, dynamic> nodeTypeJson) {
    final loggingService = LoggingService();
    final String name = nodeTypeJson['name'] ?? 'Node Types';
    final String? description = nodeTypeJson['summary'];
    
    loggingService.debug('Parsing node_type category: $name', tag: 'DataswornParser');
    
    List<OracleCategory> subcategories = [];
    
    // Process subcategories in node_type
    if (nodeTypeJson['contents'] != null) {
      loggingService.debug('Found contents in node_type with ${nodeTypeJson['contents'].length} items', tag: 'DataswornParser');
      
      nodeTypeJson['contents'].forEach((subcategoryId, subcategoryJson) {
        loggingService.debug('Processing subcategory: $subcategoryId, type: ${subcategoryJson['type']}', tag: 'DataswornParser');
        
        if (subcategoryJson['type'] == 'oracle_collection') {
          final subcategory = _parseNodeTypeSubcategory(subcategoryJson, subcategoryId);
          loggingService.debug('Parsed subcategory: ${subcategory.name} with ${subcategory.tables.length} tables', tag: 'DataswornParser');
          
          if (subcategory.tables.isNotEmpty || subcategory.subcategories.isNotEmpty) {
            subcategories.add(subcategory);
            loggingService.debug('Added subcategory: ${subcategory.name}', tag: 'DataswornParser');
          }
        }
      });
    } else {
      loggingService.debug('No contents found in node_type', tag: 'DataswornParser');
    }
    
    loggingService.debug('Finished parsing node_type category with ${subcategories.length} subcategories', tag: 'DataswornParser');
    
    return OracleCategory(
      id: 'node_type',
      name: name,
      description: description,
      tables: [],
      subcategories: subcategories,
      isNodeType: true,
    );
  }
  
  // Helper method to parse subcategories within node_type
  static OracleCategory _parseNodeTypeSubcategory(Map<String, dynamic> subcategoryJson, String subcategoryId) {
    final loggingService = LoggingService();
    final String name = subcategoryJson['name'] ?? 'Unknown Subcategory';
    final String? description = subcategoryJson['summary'];
    
    loggingService.debug('Parsing subcategory: $name (ID: $subcategoryId)', tag: 'DataswornParser');
    
    List<OracleTable> tables = [];
    
    // Process tables in subcategory
    if (subcategoryJson['contents'] != null) {
      loggingService.debug('Found contents in subcategory with ${subcategoryJson['contents'].length} items', tag: 'DataswornParser');
      
      subcategoryJson['contents'].forEach((tableId, tableJson) {
        loggingService.debug('Processing table: $tableId, type: ${tableJson['type']}', tag: 'DataswornParser');
        
        if (tableJson['type'] == 'oracle_rollable') {
          final table = OracleTable.fromDatasworn(tableJson, tableId);
          tables.add(table);
          loggingService.debug('Added table: ${table.name}', tag: 'DataswornParser');
        }
      });
    } else {
      loggingService.debug('No contents found in subcategory', tag: 'DataswornParser');
    }
    
    loggingService.debug('Finished parsing subcategory with ${tables.length} tables', tag: 'DataswornParser');
    
    return OracleCategory(
      id: subcategoryId,
      name: name,
      description: description,
      tables: tables,
    );
  }

  // Parse assets from the Datasworn JSON
  static List<Asset> parseAssets(Map<String, dynamic> datasworn) {
    final loggingService = LoggingService();
    final List<Asset> assets = [];
    
    if (datasworn['assets'] != null) {
      datasworn['assets'].forEach((categoryId, categoryJson) {
        final String category = categoryJson['name'] ?? 'Unknown';
        
        if (categoryJson['contents'] != null) {
          categoryJson['contents'].forEach((assetId, assetJson) {
            if (assetJson['type'] == 'asset') {
              final name = assetJson['name'] ?? 'Unknown Asset';
              String? description = assetJson['description'];
              String? color = assetJson['color'];
              
              // Create list of abilities
              List<AssetAbility> abilities = [];
              
              // Parse abilities if they exist
              if (assetJson['abilities'] != null && assetJson['abilities'] is List) {
                final abilitiesJson = assetJson['abilities'] as List;
                
                for (var abilityJson in abilitiesJson) {
                  if (abilityJson is Map && abilityJson['text'] != null) {
                    abilities.add(AssetAbility(
                      text: abilityJson['text'],
                      enabled: abilityJson['enabled'] ?? false,
                    ));
                  }
                }
                
                // If no description was provided, use the first ability text as description
                if ((description == null || description.isEmpty) && abilities.isNotEmpty) {
                  description = abilities[0].text;
                }
              }
              
              loggingService.debug(
                'Parsed asset: $name with ${abilities.length} abilities',
                tag: 'DataswornParser',
              );
              
              assets.add(Asset(
                id: assetId,
                name: name,
                category: category,
                description: description,
                abilities: abilities,
              ));
            }
          });
        }
      });
    }
    
    return assets;
  }
}
