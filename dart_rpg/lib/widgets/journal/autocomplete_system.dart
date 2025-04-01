import 'package:flutter/material.dart';
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
  
  /// Creates a new AutocompleteSystem.
  AutocompleteSystem();
  
  /// Checks for @ and # characters to trigger autocompletion.
  /// 
  /// Returns true if suggestions should be shown, false otherwise.
  bool checkForMentions({
    required String text,
    required int cursorPosition,
    required List<Character> characters,
    required List<Location> locations,
  }) {
    if (cursorPosition <= 0 || cursorPosition > text.length) {
      _clearInlineSuggestion();
      return false;
    }
    
    // Find the word being typed (from the last space or newline to the cursor)
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    final currentWord = textBeforeCursor.substring(wordStart);
    
    // Check if we're typing @ or # followed by at least one character
    if (currentWord.startsWith('@') && currentWord.length > 1) {
      _currentSearchText = currentWord.substring(1).toLowerCase();
      _showCharacterSuggestions = true;
      _showLocationSuggestions = false;
      _suggestionStartPosition = wordStart;
      _updateSuggestions(characters, locations);
      return true;
    } else if (currentWord.startsWith('#') && currentWord.length > 1) {
      _currentSearchText = currentWord.substring(1).toLowerCase();
      _showCharacterSuggestions = false;
      _showLocationSuggestions = true;
      _suggestionStartPosition = wordStart;
      _updateSuggestions(characters, locations);
      return true;
    } else {
      _clearInlineSuggestion();
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
    if (_showCharacterSuggestions) {
      // Match on handle if available, otherwise name
      _filteredSuggestions = characters
          .where((c) {
            final handle = c.handle ?? c.getHandle();
            return handle.toLowerCase().contains(_currentSearchText) ||
                   c.name.toLowerCase().contains(_currentSearchText);
          })
          .toList();
    } else if (_showLocationSuggestions) {
      _filteredSuggestions = locations
          .where((l) => l.name.toLowerCase().contains(_currentSearchText))
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
  }
  
  /// Inserts a mention at the current cursor position.
  /// 
  /// Returns a map with the new text and the new cursor position.
  Map<String, dynamic> insertMention(
    dynamic entity,
    String text,
    int cursorPosition,
  ) {
    // Find the start of the current word
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    
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
