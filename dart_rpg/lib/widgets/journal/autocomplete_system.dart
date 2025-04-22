import '../../models/character.dart';
import '../../models/location.dart';

/// A class for handling autocompletion of character and location references.
class AutocompleteSystem {
  /// Whether character suggestions are currently being shown.
  bool _showCharacterSuggestions = false;
  
  /// Whether location suggestions are currently being shown.
  bool _showLocationSuggestions = false;
  
  /// The current search text for filtering suggestions.
  String _currentSearchText = '';
  
  /// The filtered list of suggestions.
  List<dynamic> _filteredSuggestions = [];
  
  /// The position in the text where the suggestion starts.
  int? _suggestionStartPosition;
  
  /// The current inline suggestion.
  String? _inlineSuggestion;
  
  /// Cache for the last search text to avoid redundant filtering
  String _lastSearchText = '';
  
  /// Cache for the filtered suggestions
  List<dynamic> _cachedSuggestions = [];
  
  /// Performance metrics
  int _lastCheckDuration = 0;
  
  /// Creates a new AutocompleteSystem.
  AutocompleteSystem();
  
  /// Gets the last check duration in milliseconds
  int get lastCheckDuration => _lastCheckDuration;
  
  /// Checks for @ and # characters to trigger autocompletion.
  /// 
  /// Returns true if suggestions should be shown, false otherwise.
  bool checkForMentions({
    required String text,
    required int cursorPosition,
    required List<Character> characters,
    required List<Location> locations,
  }) {
    final stopwatch = Stopwatch()..start();
    
    if (cursorPosition <= 0 || cursorPosition > text.length) {
      _clearInlineSuggestion();
      _lastCheckDuration = stopwatch.elapsedMicroseconds;
      return false;
    }
    
    // Quick check if we're potentially in a mention context
    // Only proceed with more expensive operations if we might be in a mention
    final charAtCursor = cursorPosition < text.length ? text[cursorPosition] : '';
    final charBeforeCursor = cursorPosition > 0 ? text[cursorPosition - 1] : '';
    
    // Special case: If we just typed @ or #, we always want to check for mentions
    final justTypedMentionChar = charBeforeCursor == '@' || charBeforeCursor == '#';
    
    // If we're not in a mention context and didn't just type a mention character, return early
    if (!justTypedMentionChar && 
        !_showCharacterSuggestions && 
        !_showLocationSuggestions) {
      _clearInlineSuggestion();
      _lastCheckDuration = stopwatch.elapsedMicroseconds;
      return false;
    }
    
    // Find the word being typed (from the last space or newline to the cursor)
    // Only compute this if we're potentially in a mention context
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    
    // Only extract the current word if we're potentially in a mention context
    // This avoids unnecessary string operations
    String currentWord;
    if (wordStart < textBeforeCursor.length) {
      currentWord = textBeforeCursor.substring(wordStart);
    } else {
      _clearInlineSuggestion();
      _lastCheckDuration = stopwatch.elapsedMicroseconds;
      return false;
    }
    
    // Check if we're typing @ or # followed by at least one character
    if (currentWord.startsWith('@')) {
      if (currentWord.length > 1) {
        final searchText = currentWord.substring(1).toLowerCase();
        
        // Only update if the search text has changed
        if (searchText != _currentSearchText || _showLocationSuggestions) {
          _currentSearchText = searchText;
          _showCharacterSuggestions = true;
          _showLocationSuggestions = false;
          _suggestionStartPosition = wordStart;
          _updateSuggestions(characters, locations);
        }
        
        _lastCheckDuration = stopwatch.elapsedMicroseconds;
        return true;
      } else {
        // Even if we just have @, we should set up the state for character suggestions
        _showCharacterSuggestions = true;
        _showLocationSuggestions = false;
        _suggestionStartPosition = wordStart;
        _lastCheckDuration = stopwatch.elapsedMicroseconds;
        return true;
      }
    } else if (currentWord.startsWith('#')) {
      if (currentWord.length > 1) {
        final searchText = currentWord.substring(1).toLowerCase();
        
        // Only update if the search text has changed
        if (searchText != _currentSearchText || _showCharacterSuggestions) {
          _currentSearchText = searchText;
          _showCharacterSuggestions = false;
          _showLocationSuggestions = true;
          _suggestionStartPosition = wordStart;
          _updateSuggestions(characters, locations);
        }
        
        _lastCheckDuration = stopwatch.elapsedMicroseconds;
        return true;
      } else {
        // Even if we just have #, we should set up the state for location suggestions
        _showCharacterSuggestions = false;
        _showLocationSuggestions = true;
        _suggestionStartPosition = wordStart;
        _lastCheckDuration = stopwatch.elapsedMicroseconds;
        return true;
      }
    } else {
      _clearInlineSuggestion();
      _lastCheckDuration = stopwatch.elapsedMicroseconds;
      return false;
    }
  }
  
  /// Clears the current inline suggestion.
  void _clearInlineSuggestion() {
    _inlineSuggestion = null;
    _suggestionStartPosition = null;
    _showCharacterSuggestions = false;
    _showLocationSuggestions = false;
    _filteredSuggestions = [];
  }
  
  /// Updates the list of suggestions based on the current search text.
  void _updateSuggestions(List<Character> characters, List<Location> locations) {
    // If the search text hasn't changed, use cached results
    if (_lastSearchText == _currentSearchText && _filteredSuggestions.isNotEmpty) {
      return;
    }
    
    _lastSearchText = _currentSearchText;
    
    if (_showCharacterSuggestions) {
      // Match on handle if available, otherwise name
      // Limit to 10 suggestions for performance
      _filteredSuggestions = characters
          .where((c) {
            final handle = c.handle ?? c.getHandle();
            return handle.toLowerCase().contains(_currentSearchText) ||
                   c.name.toLowerCase().contains(_currentSearchText);
          })
          .take(10)
          .toList();
    } else if (_showLocationSuggestions) {
      // Limit to 10 suggestions for performance
      _filteredSuggestions = locations
          .where((l) => l.name.toLowerCase().contains(_currentSearchText))
          .take(10)
          .toList();
    } else {
      _filteredSuggestions = [];
    }
    
    if (_filteredSuggestions.isEmpty) {
      _clearInlineSuggestion();
      return;
    }
    
    // Update inline suggestion
    if (_filteredSuggestions.isNotEmpty && _suggestionStartPosition != null) {
      final suggestion = _filteredSuggestions.first;
      String completionText;
      
      if (_showCharacterSuggestions) {
        final character = suggestion as Character;
        final handle = character.handle ?? character.getHandle();
        completionText = handle;
      } else {
        completionText = suggestion.name;
      }
      
      _inlineSuggestion = completionText;
    }
    
    // Cache the results
    _cachedSuggestions = List.from(_filteredSuggestions);
  }
  
  /// Inserts a mention at the current cursor position.
  /// 
  /// Returns a map with the new text and the new cursor position.
  Map<String, dynamic> insertMention(
    dynamic entity,
    String text,
    int cursorPosition,
  ) {
    // Create the mention text
    String mentionText;
    String entityId;
    
    if (entity is Character) {
      final handle = entity.handle ?? entity.getHandle();
      mentionText = '@$handle';
      entityId = entity.id;
    } else {
      mentionText = '#${entity.name}';
      entityId = entity.id;
    }
    
    // Handle empty text or cursor at position 0
    if (text.isEmpty || cursorPosition == 0) {
      return {
        'text': mentionText + (text.isEmpty ? '' : text),
        'cursorPosition': mentionText.length,
        'entityId': entityId,
        'isCharacter': entity is Character,
      };
    }
    
    // Find the start of the current word
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    
    // Ensure wordStart is valid and within the text
    if (wordStart < 0 || wordStart > text.length || wordStart > cursorPosition) {
      // Just insert at cursor position if we can't find a valid word start
      final newText = text.substring(0, cursorPosition) + mentionText + text.substring(cursorPosition);
      final newCursorPosition = cursorPosition + mentionText.length;
      
      // Clear the suggestion
      _clearInlineSuggestion();
      
      return {
        'text': newText,
        'cursorPosition': newCursorPosition,
        'entityId': entityId,
        'isCharacter': entity is Character,
      };
    }
    
    // Replace the current word with the mention
    final newText = text.replaceRange(wordStart, cursorPosition, mentionText);
    final newCursorPosition = wordStart + mentionText.length;
    
    // Clear the suggestion
    _clearInlineSuggestion();
    
    return {
      'text': newText,
      'cursorPosition': newCursorPosition,
      'entityId': entityId,
      'isCharacter': entity is Character,
    };
  }
  
  /// Handles tab or enter key press for autocompletion.
  /// 
  /// Returns a map with the new text and the new cursor position if a suggestion
  /// was selected, null otherwise.
  Map<String, dynamic>? handleTabOrEnterKey(String text, int cursorPosition) {
    if ((_showCharacterSuggestions || _showLocationSuggestions) &&
        _filteredSuggestions.isNotEmpty &&
        _inlineSuggestion != null) {
      return insertMention(_filteredSuggestions.first, text, cursorPosition);
    }
    
    return null;
  }
  
  /// Gets the current inline suggestion.
  String? get inlineSuggestion => _inlineSuggestion;
  
  /// Gets the position in the text where the suggestion starts.
  int? get suggestionStartPosition => _suggestionStartPosition;
  
  /// Gets the current search text.
  String get currentSearchText => _currentSearchText;
  
  /// Gets whether character suggestions are currently being shown.
  bool get showCharacterSuggestions => _showCharacterSuggestions;
  
  /// Gets whether location suggestions are currently being shown.
  bool get showLocationSuggestions => _showLocationSuggestions;
  
  /// Gets the filtered list of suggestions.
  List<dynamic> get filteredSuggestions => List.unmodifiable(_filteredSuggestions);
  
  /// Resets the autocomplete system.
  void reset() {
    _clearInlineSuggestion();
  }
}
