import 'package:flutter/material.dart';
import '../models/oracle.dart';
import '../models/journal_entry.dart'; // Import for OracleRoll
import '../utils/dice_roller.dart';
import '../utils/oracle_reference_processor.dart';
import '../providers/datasworn_provider.dart';
import '../utils/logging_service.dart';

/// Service for handling oracle rolls and results.
class OracleService {
  /// Finds an oracle table by key anywhere in the hierarchy.
  static OracleTable? findOracleTableByKeyAnywhere(String key, DataswornProvider dataswornProvider) {
    final loggingService = LoggingService();
    loggingService.debug('Finding oracle table by key anywhere: $key', tag: 'OracleService');
    
    // Recursively search through all categories and subcategories
    for (final category in dataswornProvider.oracles) {
      final table = _findTableAnywhere(category, key);
      if (table != null) {
        return table;
      }
    }
    
    return null;
  }

  /// Helper method to recursively find a table in a category or its subcategories.
  static OracleTable? _findTableAnywhere(OracleCategory category, String key) {
    // Check tables in this category
    for (final table in category.tables) {
      if (table.id == key || 
          table.id.endsWith('/$key') || 
          table.name.toLowerCase() == key.toLowerCase()) {
        return table;
      }
    }
    
    // Check subcategories
    for (final subcategory in category.subcategories) {
      final table = _findTableAnywhere(subcategory, key);
      if (table != null) {
        return table;
      }
    }
    
    return null;
  }

  /// Rolls on an oracle table and returns the result.
  static Map<String, dynamic> rollOnOracleTable(OracleTable table) {
    if (table.rows.isEmpty) {
      return {
        'success': false,
        'error': 'This oracle has no table entries',
      };
    }
    
    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    final dice = rollResult['dice'] as List<int>;
    
    // Find the matching table entry
    OracleTableRow? matchingRow;
    for (final row in table.rows) {
      if (row.matchesRoll(total)) {
        matchingRow = row;
        break;
      }
    }
    
    if (matchingRow == null) {
      return {
        'success': false,
        'error': 'No result found for roll: $total',
      };
    }
    
    // Create an OracleRoll object
    final oracleRoll = OracleRoll(
      oracleName: table.name,
      oracleTable: table.id,
      dice: dice,
      result: matchingRow.result,
    );
    
    return {
      'success': true,
      'oracleRoll': oracleRoll,
      'total': total,
      'dice': dice,
    };
  }
  
  /// Processes oracle references in the result text.
  static Future<Map<String, dynamic>> processOracleReferences(
    String text,
    DataswornProvider dataswornProvider,
  ) async {
    // Log the processing attempt
    final loggingService = LoggingService();
    loggingService.debug(
      'Processing oracle references in text: $text',
      tag: 'OracleService',
    );
    
    try {
      // Process the references
      final processResult = await OracleReferenceProcessor.processOracleReferences(
        text,
        dataswornProvider,
      );
      
      final processedText = processResult['processedText'] as String;
      final nestedRolls = processResult['rolls'] as List<OracleRoll>;
      
      return {
        'success': true,
        'processedText': processedText,
        'nestedRolls': nestedRolls,
      };
    } catch (e, stackTrace) {
      // Log the error
      loggingService.error(
        'Error processing oracle references',
        tag: 'OracleService',
        error: e,
        stackTrace: stackTrace,
      );
      
      return {
        'success': false,
        'error': e.toString(),
        'processedText': text, // Return the original text
        'nestedRolls': <OracleRoll>[],
      };
    }
  }
  
  /// Gets the color for an oracle category.
  static Color getCategoryColor(String categoryName) {
    // Generate a color based on the category name
    final hash = categoryName.hashCode;
    return Color(0xFF000000 + (hash & 0x00FFFFFF)).withAlpha(204); // 0.8 opacity = 204 alpha
  }
}
