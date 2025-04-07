import '../models/oracle.dart';
import '../providers/datasworn_provider.dart';
import 'logging_service.dart';

/// A utility class for parsing oracle markdown references in text.
class OracleMarkdownParser {
  static final LoggingService _logger = LoggingService();
  
  /// Regular expression to match table_columns markdown syntax
  static final RegExp tableColumnsPattern = RegExp(
    r'\{\{table_columns>move:(.*?)\}\}',
    caseSensitive: false,
  );
  
  /// Parse text and extract oracle table references
  static List<String> parseOracleReferences(String text) {
    final matches = tableColumnsPattern.allMatches(text);
    final references = matches.map((match) => match.group(1) ?? '').toList();
    
    _logger.debug(
      'Parsed oracle references: $references from text: "$text"',
      tag: 'OracleMarkdownParser',
    );
    
    return references;
  }
  
  /// Check if text contains any oracle table references
  static bool containsOracleReferences(String text) {
    final hasMatch = tableColumnsPattern.hasMatch(text);
    
    _logger.debug(
      'Contains oracle references: $hasMatch in text: "$text"',
      tag: 'OracleMarkdownParser',
    );
    
    return hasMatch;
  }
  
  /// Get oracles for a move reference
  /// 
  /// This method takes a move reference (e.g., "fe_runners/exploration/explore_the_system")
  /// and returns a map of oracle keys to oracle tables.
  static Map<String, OracleTable> getOraclesForMoveReference(
    String moveRef,
    DataswornProvider provider,
  ) {
    _logger.debug(
      'Getting oracles for move reference: $moveRef',
      tag: 'OracleMarkdownParser',
    );
    
    // Find the move by ID
    final move = provider.findMoveById(moveRef);
    if (move == null) {
      _logger.warning(
        'Move not found for reference: $moveRef',
        tag: 'OracleMarkdownParser',
      );
      return {};
    }
    
    // Get the oracles from the move
    final Map<String, OracleTable> oracleTables = {};
    for (final entry in move.oracles.entries) {
      final key = entry.key;
      final moveOracle = entry.value;
      
      // Convert MoveOracle to OracleTable
      final oracleTable = moveOracle.toOracleTable();
      oracleTables[key] = oracleTable;
      
      _logger.debug(
        'Found oracle: $key (${oracleTable.name}) for move: ${move.name}',
        tag: 'OracleMarkdownParser',
      );
    }
    
    return oracleTables;
  }
}
