import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../models/character.dart';

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
    final List<OracleCategory> categories = [];
    
    if (datasworn['oracles'] != null) {
      datasworn['oracles'].forEach((categoryId, categoryJson) {
        if (categoryJson['type'] == 'oracle_collection') {
          final category = OracleCategory.fromDatasworn(categoryJson, categoryId);
          if (category.tables.isNotEmpty) {
            categories.add(category);
          }
        }
      });
    }
    
    return categories;
  }

  // Parse assets from the Datasworn JSON
  static List<Asset> parseAssets(Map<String, dynamic> datasworn) {
    final List<Asset> assets = [];
    
    if (datasworn['assets'] != null) {
      datasworn['assets'].forEach((categoryId, categoryJson) {
        final String category = categoryJson['name'] ?? 'Unknown';
        
        if (categoryJson['contents'] != null) {
          categoryJson['contents'].forEach((assetId, assetJson) {
            if (assetJson['type'] == 'asset') {
              final name = assetJson['name'] ?? 'Unknown Asset';
              String description = '';
              
              // Try to extract description from abilities
              if (assetJson['abilities'] != null && assetJson['abilities'] is List) {
                final abilities = assetJson['abilities'] as List;
                if (abilities.isNotEmpty && abilities[0]['text'] != null) {
                  description = abilities[0]['text'];
                }
              }
              
              assets.add(Asset(
                id: assetId,
                name: name,
                category: category,
                description: description,
              ));
            }
          });
        }
      });
    }
    
    return assets;
  }
}
