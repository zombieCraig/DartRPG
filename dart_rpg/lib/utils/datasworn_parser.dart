import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../models/character.dart';
import '../models/truth.dart';
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
  
  // Parse custom oracles from the custom_oracles.json file
  static List<OracleCategory> parseCustomOracles(Map<String, dynamic> customData) {
    final loggingService = LoggingService();
    final List<OracleCategory> categories = [];
    
    loggingService.debug('Parsing custom oracles', tag: 'DataswornParser');
    loggingService.debug('Top-level keys in custom data: ${customData.keys.join(', ')}', tag: 'DataswornParser');
    
    // Process custom_oracles section
    if (customData['custom_oracles'] != null) {
      customData['custom_oracles'].forEach((categoryId, categoryJson) {
        loggingService.debug('Processing custom oracle category: $categoryId', tag: 'DataswornParser');
        
        if (categoryJson['type'] == 'oracle_collection') {
          // Check if this category has contents
          if (categoryJson['contents'] != null && categoryJson['contents'].isNotEmpty) {
            loggingService.debug('Found contents in custom category: $categoryId with ${categoryJson['contents'].length} items', tag: 'DataswornParser');
            
            // Create tables for this category
            List<OracleTable> tables = [];
            List<OracleCategory> subcategories = [];
            
            categoryJson['contents'].forEach((tableId, tableJson) {
              loggingService.debug('Processing custom table: $tableId, type: ${tableJson['type']}', tag: 'DataswornParser');
              
              if (tableJson['type'] == 'oracle_rollable') {
                final table = OracleTable.fromDatasworn(tableJson, tableId);
                tables.add(table);
                loggingService.debug('Added custom table: ${table.name}', tag: 'DataswornParser');
              } else if (tableJson['type'] == 'oracle_collection') {
                // Handle subcategories if needed
                final subcategory = OracleCategory.fromDatasworn(tableJson, tableId);
                if (subcategory.tables.isNotEmpty || subcategory.subcategories.isNotEmpty) {
                  subcategories.add(subcategory);
                  loggingService.debug('Added custom subcategory: ${subcategory.name}', tag: 'DataswornParser');
                }
              }
            });
            
            // Create the category
            final category = OracleCategory(
              id: categoryId,
              name: categoryJson['name'] ?? 'Unknown Category',
              description: categoryJson['summary'],
              tables: tables,
              subcategories: subcategories,
            );
            
            if (category.tables.isNotEmpty || category.subcategories.isNotEmpty) {
              categories.add(category);
              loggingService.debug('Added custom category: ${category.name} with ${category.tables.length} tables and ${category.subcategories.length} subcategories', tag: 'DataswornParser');
            }
          } else if (categoryJson['collections'] != null && categoryJson['collections'].isNotEmpty) {
            loggingService.debug('Found collections in custom category: $categoryId', tag: 'DataswornParser');
            
            // Create a category for this collection
            final category = _parseCollectionCategory(categoryJson, categoryId);
            if (category.subcategories.isNotEmpty) {
              categories.add(category);
              loggingService.debug('Added custom collection category: ${category.name} with ${category.subcategories.length} subcategories', tag: 'DataswornParser');
            }
          }
        }
      });
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

  // Parse asset controls from the JSON
  static Map<String, AssetControl> parseAssetControls(Map<String, dynamic> controlsJson) {
    final loggingService = LoggingService();
    Map<String, AssetControl> controls = {};
    
    controlsJson.forEach((key, value) {
      if (value is Map) {
        try {
          final fieldType = value['field_type']?.toString() ?? 'condition_meter';
          
          // Warn if field_type is not condition_meter
          if (fieldType != 'condition_meter') {
            loggingService.warning(
              'Unsupported control field type "$fieldType" for control "$key"',
              tag: 'DataswornParser',
            );
          }
          
          // Parse nested controls if they exist
          Map<String, AssetControl> nestedControls = {};
          if (value['controls'] != null && value['controls'] is Map) {
            value['controls'].forEach((nestedKey, nestedValue) {
              if (nestedValue is Map) {
                try {
                  nestedControls[nestedKey.toString()] = AssetControl.fromJson(
                    Map<String, dynamic>.from(nestedValue)
                  );
                } catch (e) {
                  loggingService.error(
                    'Failed to parse nested control "$nestedKey": ${e.toString()}',
                    tag: 'DataswornParser',
                  );
                }
              }
            });
          }
          
          // Create the control
          controls[key.toString()] = AssetControl(
            label: value['label']?.toString() ?? key.toString(),
            max: value['max'] is num ? (value['max'] as num).toInt() : 5,
            value: value['value'] is num ? (value['value'] as num).toInt() : 0,
            fieldType: fieldType,
            min: value['min'] is num ? (value['min'] as num).toInt() : 0,
            rollable: value['rollable'] == true,
            moves: value['moves'] != null ? Map<String, dynamic>.from(value['moves']) : {},
            controls: nestedControls,
          );
          
          loggingService.debug(
            'Parsed control: ${controls[key.toString()]?.label ?? key} with ${nestedControls.length} nested controls',
            tag: 'DataswornParser',
          );
        } catch (e) {
          loggingService.error(
            'Failed to parse control "$key": ${e.toString()}',
            tag: 'DataswornParser',
          );
        }
      }
    });
      
    return controls;
  }

  // Parse truths from the Datasworn JSON
  static List<Truth> parseTruths(Map<String, dynamic> datasworn) {
    final loggingService = LoggingService();
    final List<Truth> truths = [];
    
    if (datasworn.containsKey('truths')) {
      loggingService.debug('Found truths section in JSON', tag: 'DataswornParser');
      final truthsJson = datasworn['truths'] as Map<String, dynamic>;
      
      truthsJson.forEach((truthId, truthJson) {
        if (truthJson['type'] == 'truth') {
          try {
            final truth = Truth.fromJson(truthId, truthJson);
            truths.add(truth);
            loggingService.debug('Parsed truth: ${truth.name} with ${truth.options.length} options', tag: 'DataswornParser');
          } catch (e) {
            loggingService.error(
              'Failed to parse truth "$truthId": ${e.toString()}',
              tag: 'DataswornParser',
              error: e,
              stackTrace: StackTrace.current
            );
          }
        }
      });
      
      loggingService.debug('Parsed ${truths.length} truths', tag: 'DataswornParser');
    } else {
      loggingService.debug('No truths section found in JSON', tag: 'DataswornParser');
    }
    
    return truths;
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
              
              // Parse options if they exist
              Map<String, AssetOption> options = {};
              if (assetJson['options'] != null && assetJson['options'] is Map) {
                final optionsJson = assetJson['options'] as Map;
                
                optionsJson.forEach((key, value) {
                  if (value is Map) {
                    final fieldType = value['field_type']?.toString() ?? 'text';
                    final label = value['label']?.toString() ?? key.toString();
                    final optionValue = value['value'];
                    
                    // Add the option
                    options[key.toString()] = AssetOption(
                      fieldType: fieldType,
                      label: label,
                      value: optionValue?.toString(),
                    );
                    
                    // Log warning for unsupported field types
                    if (fieldType != 'text') {
                      loggingService.warning(
                        'Unsupported field type "$fieldType" for option "$key" in asset "$name"',
                        tag: 'DataswornParser',
                      );
                    }
                  }
                });
              }
              
              // Parse controls if they exist
              Map<String, AssetControl> controls = {};
              if (assetJson['controls'] != null && assetJson['controls'] is Map) {
                controls = parseAssetControls(Map<String, dynamic>.from(assetJson['controls'] as Map));
              }
              
              loggingService.debug(
                'Parsed asset: $name with ${abilities.length} abilities, ${options.length} options, and ${controls.length} controls',
                tag: 'DataswornParser',
              );
              
              assets.add(Asset(
                id: assetId,
                name: name,
                category: category,
                description: description,
                abilities: abilities,
                options: options,
                controls: controls,
              ));
            }
          });
        }
      });
    }
    
    return assets;
  }
}
