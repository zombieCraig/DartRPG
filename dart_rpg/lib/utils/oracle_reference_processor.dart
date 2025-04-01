import '../providers/datasworn_provider.dart';
import '../models/oracle.dart';
import '../models/journal_entry.dart'; // Import for OracleRoll class
import '../utils/datasworn_link_parser.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';

/// A utility class for processing oracle references in text.
/// This class handles finding oracle references, rolling on the referenced oracles,
/// and replacing the references with the results.
class OracleReferenceProcessor {
  static final LoggingService _logger = LoggingService();
  
  /// Process text with oracle references and return processed text and rolls.
  /// 
  /// This method finds all oracle references in the text, rolls on the referenced
  /// oracles, and replaces the references with the results. It also returns a list
  /// of all oracle rolls performed.
  /// 
  /// [text] The text to process
  /// [provider] The DataswornProvider to use for finding oracles
  /// [maxDepth] The maximum depth of nested references to process (default: 3)
  /// 
  /// Returns a map with 'processedText' (the text with references replaced) and
  /// 'rolls' (a list of OracleRoll objects for all rolls performed)
  static Future<Map<String, dynamic>> processOracleReferences(
    String text,
    DataswornProvider provider, {
    int maxDepth = 3,
  }) async {
    final List<OracleRoll> rolls = [];
    String processedText = text;
    
    // Process references recursively
    processedText = await _processReferencesRecursively(
      text, 
      provider, 
      rolls,
      0,
      maxDepth,
    );
    
    return {
      'processedText': processedText,
      'rolls': rolls,
    };
  }
  
  /// Recursive helper method to process oracle references.
  /// 
  /// This method processes oracle references in the text recursively, up to the
  /// specified maximum depth. It rolls on each referenced oracle and replaces
  /// the reference with the result. If the result contains further references,
  /// those are processed recursively.
  /// 
  /// [text] The text to process
  /// [provider] The DataswornProvider to use for finding oracles
  /// [rolls] A list to store all oracle rolls performed
  /// [currentDepth] The current recursion depth
  /// [maxDepth] The maximum recursion depth
  /// 
  /// Returns the processed text with references replaced
  static Future<String> _processReferencesRecursively(
    String text,
    DataswornProvider provider,
    List<OracleRoll> rolls,
    int currentDepth,
    int maxDepth,
  ) async {
    // Check if we've reached the maximum recursion depth
    if (currentDepth >= maxDepth) {
      _logger.warning(
        'Maximum recursion depth reached ($maxDepth). Stopping recursion.',
        tag: 'OracleReferenceProcessor',
      );
      return text;
    }
    
    // Check if the text contains any oracle references
    if (!DataswornLinkParser.containsLinks(text)) {
      return text;
    }
    
    // Parse the text to find oracle references
    final links = DataswornLinkParser.parseLinks(text);
    if (links.isEmpty) {
      return text;
    }
    
    String processedText = text;
    
    // Process each link
    for (final link in links) {
      // Skip non-oracle links
      if (link.linkType != 'oracle_rollable') {
        continue;
      }
      
      // Find the referenced oracle
      final oracle = DataswornLinkParser.findOracleByPath(provider, link.path);
      if (oracle == null) {
        _logger.warning(
          'Oracle not found: ${link.path}',
          tag: 'OracleReferenceProcessor',
        );
        continue;
      }
      
      // Roll on the oracle
      final rollResult = DiceRoller.rollOracle(oracle.diceFormat);
      final total = rollResult['total'] as int;
      
      // Find the matching row
      OracleTableRow? matchingRow;
      for (final row in oracle.rows) {
        if (row.matchesRoll(total)) {
          matchingRow = row;
          break;
        }
      }
      
      if (matchingRow == null) {
        _logger.warning(
          'No matching row found for roll $total on oracle ${oracle.name}',
          tag: 'OracleReferenceProcessor',
        );
        continue;
      }
      
      // Create an OracleRoll object
      final oracleRoll = OracleRoll(
        oracleName: oracle.name,
        oracleTable: oracle.id,
        dice: [total],
        result: matchingRow.result,
      );
      
      // Add the roll to the list
      rolls.add(oracleRoll);
      
      // Process nested references in the result
      String processedResult = matchingRow.result;
      if (DataswornLinkParser.containsLinks(processedResult)) {
        // Process nested references recursively
        processedResult = await _processReferencesRecursively(
          processedResult,
          provider,
          rolls,
          currentDepth + 1,
          maxDepth,
        );
      }
      
      // Replace the reference with the processed result
      final pattern = RegExp(
        r'\[' + RegExp.escape(link.displayText) + r'\]' +
        r'\((datasworn:)?' + RegExp.escape(link.linkType) + r':' + 
        RegExp.escape(link.path) + r'\)',
        caseSensitive: false,
      );
      
      processedText = processedText.replaceFirst(pattern, processedResult);
    }
    
    return processedText;
  }
  
  /// Get all oracle rolls from a journal entry text.
  ///
  /// This method processes the text to find all oracle references, rolls on them,
  /// and returns a list of OracleRoll objects for all rolls performed.
  ///
  /// [text] The text to process
  /// [provider] The DataswornProvider to use for finding oracles
  ///
  /// Returns a map with 'processedText' (the text with references replaced) and
  /// 'rolls' (a list of OracleRoll objects for all rolls performed)
  static Future<Map<String, dynamic>> getOracleRollsForJournalEntry(
    String text,
    DataswornProvider provider,
  ) async {
    // Use the existing processOracleReferences method to process the text
    return await processOracleReferences(text, provider);
  }

  /// Process a single oracle reference and return the result.
  /// 
  /// This method finds the referenced oracle, rolls on it, and returns the result.
  /// It does not process nested references.
  /// 
  /// [link] The DataswornLink to process
  /// [provider] The DataswornProvider to use for finding oracles
  /// 
  /// Returns a map with 'roll' (the roll value), 'result' (the result text),
  /// and 'oracleRoll' (an OracleRoll object)
  static Future<Map<String, dynamic>?> processSingleOracleReference(
    DataswornLink link,
    DataswornProvider provider,
  ) async {
    // Skip non-oracle links
    if (link.linkType != 'oracle_rollable') {
      return null;
    }
    
    // Find the referenced oracle
    final oracle = DataswornLinkParser.findOracleByPath(provider, link.path);
    if (oracle == null) {
      _logger.warning(
        'Oracle not found: ${link.path}',
        tag: 'OracleReferenceProcessor',
      );
      return null;
    }
    
    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(oracle.diceFormat);
    final total = rollResult['total'] as int;
    
    // Find the matching row
    OracleTableRow? matchingRow;
    for (final row in oracle.rows) {
      if (row.matchesRoll(total)) {
        matchingRow = row;
        break;
      }
    }
    
    if (matchingRow == null) {
      _logger.warning(
        'No matching row found for roll $total on oracle ${oracle.name}',
        tag: 'OracleReferenceProcessor',
      );
      return null;
    }
    
    // Create an OracleRoll object
    final oracleRoll = OracleRoll(
      oracleName: oracle.name,
      oracleTable: oracle.id,
      dice: [total],
      result: matchingRow.result,
    );
    
    return {
      'roll': total,
      'result': matchingRow.result,
      'oracleRoll': oracleRoll,
    };
  }
}
