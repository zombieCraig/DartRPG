import '../utils/logging_service.dart';

/// A utility class for converting text to leet speak.
class LeetSpeakConverter {
  /// Converts a string to leet speak.
  /// 
  /// Common substitutions:
  /// - a → 4
  /// - e → 3
  /// - i → 1
  /// - o → 0
  /// - t → 7
  /// - s → 5
  /// - spaces → _
  /// 
  /// Avoids using disallowed characters like @, #, or [].
  static String convert(String input) {
    if (input.isEmpty) {
      return input;
    }
    
    final loggingService = LoggingService();
    loggingService.debug('Converting to leet speak: $input', tag: 'LeetSpeakConverter');
    
    // Define character substitutions
    final Map<String, String> substitutions = {
      'a': '4',
      'e': '3',
      'i': '1',
      'o': '0',
      't': '7',
      's': '5',
      ' ': '_',
      'b': '8',
      'g': '6',
      'l': '1',
      'z': '2',
    };
    
    // Convert to lowercase for consistent substitutions
    String result = input.toLowerCase();
    
    // Apply substitutions
    substitutions.forEach((original, replacement) {
      result = result.replaceAll(original, replacement);
    });
    
    // Remove any disallowed characters
    result = result.replaceAll(RegExp(r'[@#\[\]()]'), '');
    
    loggingService.debug('Converted result: $result', tag: 'LeetSpeakConverter');
    
    return result;
  }
}
