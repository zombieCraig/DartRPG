import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/character.dart';
import '../../models/location.dart';

class RichTextEditor extends StatefulWidget {
  final String initialText;
  final String? initialRichText;
  final bool readOnly;
  final Function(String plainText, String richText) onChanged;
  final Function(String characterId)? onCharacterLinked;
  final Function(String locationId)? onLocationLinked;
  final Function(String imageUrl)? onImageAdded;
  final Function()? onMoveRequested;
  final Function()? onOracleRequested;

  const RichTextEditor({
    super.key,
    required this.initialText,
    this.initialRichText,
    this.readOnly = false,
    required this.onChanged,
    this.onCharacterLinked,
    this.onLocationLinked,
    this.onImageAdded,
    this.onMoveRequested,
    this.onOracleRequested,
  });
  
  // Static method to insert text at the current cursor position
  static void insertTextAtCursor(TextEditingController controller, String text) {
    final selection = controller.selection;
    final currentText = controller.text;
    
    if (selection.isValid) {
      final newText = currentText.replaceRange(selection.baseOffset, selection.extentOffset, text);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.baseOffset + text.length),
      );
    } else {
      // If no valid selection, append to the end
      controller.text = currentText + text;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
  }

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // For autocomplete
  bool _showCharacterSuggestions = false;
  bool _showLocationSuggestions = false;
  String _currentSearchText = '';
  List<dynamic> _filteredSuggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the controller with the initial text
    _controller.text = widget.initialText;
    
    // Set up keyboard shortcuts
    _focusNode.onKeyEvent = _handleKeyEvent;
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }
  
  // Handle keyboard shortcuts
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Check for Ctrl+M for Move
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.keyM && 
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
        widget.onMoveRequested != null) {
      widget.onMoveRequested!();
      return KeyEventResult.handled;
    }
    
    // Check for Ctrl+O for Oracle
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.keyO && 
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
        widget.onOracleRequested != null) {
      widget.onOracleRequested!();
      return KeyEventResult.handled;
    }
    
    // Check for Tab key for autocomplete
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.tab && 
        (_showCharacterSuggestions || _showLocationSuggestions) &&
        _filteredSuggestions.isNotEmpty) {
      _insertMention(_filteredSuggestions.first);
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  // For inline suggestion
  String? _inlineSuggestion;
  int? _suggestionStartPosition;
  
  // Check for @ and # characters to trigger autocomplete
  void _checkForMentions() {
    if (widget.readOnly) return;
    
    final text = _controller.text;
    final cursorPosition = _controller.selection.baseOffset;
    
    if (cursorPosition <= 0 || cursorPosition > text.length) {
      _removeOverlay();
      _clearInlineSuggestion();
      return;
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
      _updateSuggestions();
    } else if (currentWord.startsWith('#') && currentWord.length > 1) {
      _currentSearchText = currentWord.substring(1).toLowerCase();
      _showCharacterSuggestions = false;
      _showLocationSuggestions = true;
      _suggestionStartPosition = wordStart;
      _updateSuggestions();
    } else {
      _removeOverlay();
      _clearInlineSuggestion();
    }
  }
  
  void _clearInlineSuggestion() {
    setState(() {
      _inlineSuggestion = null;
      _suggestionStartPosition = null;
    });
  }
  
  void _updateSuggestions() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null) return;
    
    if (_showCharacterSuggestions) {
      // Match on handle if available, otherwise name
      _filteredSuggestions = currentGame.characters
          .where((c) {
            final handle = c.handle ?? c.getHandle();
            return handle.toLowerCase().contains(_currentSearchText) ||
                   c.name.toLowerCase().contains(_currentSearchText);
          })
          .toList();
    } else if (_showLocationSuggestions) {
      _filteredSuggestions = currentGame.locations
          .where((l) => l.name.toLowerCase().contains(_currentSearchText))
          .toList();
    } else {
      _filteredSuggestions = [];
    }
    
    if (_filteredSuggestions.isEmpty) {
      _removeOverlay();
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
      
      setState(() {
        _inlineSuggestion = completionText;
      });
    }
    
    _showSuggestions();
  }
  
  void _showSuggestions() {
    _removeOverlay();
    
    // Make sure the context is still valid
    if (!mounted) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        width: size.width * 0.8,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 4.0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 200,
                maxWidth: size.width * 0.8,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredSuggestions.length,
                itemBuilder: (listContext, index) {
                  final suggestion = _filteredSuggestions[index];
                  String displayText;
                  
                  if (_showCharacterSuggestions) {
                    final character = suggestion as Character;
                    final handle = character.handle ?? character.getHandle();
                    displayText = '$handle (${character.name})';
                  } else {
                    displayText = suggestion.name;
                  }
                  
                  return ListTile(
                    leading: Icon(
                      _showCharacterSuggestions ? Icons.person : Icons.place,
                      size: 20,
                    ),
                    title: Text(displayText),
                    dense: true,
                    onTap: () => _insertMention(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    
    // Make sure the context is still valid before inserting the overlay
    if (mounted) {
      final overlay = Overlay.of(context);
      overlay.insert(_overlayEntry!);
    }
  }
  
  void _removeOverlay() {
    _showCharacterSuggestions = false;
    _showLocationSuggestions = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  void _insertMention(dynamic entity) {
    final selection = _controller.selection;
    final text = _controller.text;
    final cursorPosition = selection.baseOffset;
    
    // Find the start of the current word
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    
    // Create the mention text
    String mentionText;
    if (entity is Character) {
      final handle = entity.handle ?? entity.getHandle();
      mentionText = '@$handle';
      
      // Notify parent about linked character
      if (widget.onCharacterLinked != null) {
        widget.onCharacterLinked!(entity.id);
      }
    } else {
      mentionText = '#${entity.name}';
      
      // Notify parent about linked location
      if (widget.onLocationLinked != null) {
        widget.onLocationLinked!(entity.id);
      }
    }
    
    // Replace the current word with the mention
    final newText = text.replaceRange(wordStart, cursorPosition, mentionText);
    
    // Update the controller
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: wordStart + mentionText.length),
    );
    
    // Notify parent about the change
    widget.onChanged(_controller.text, _controller.text);
    
    _removeOverlay();
  }
  
  // Add an image to the document
  void _addImage() {
    // Show dialog to enter URL
    _showImageUrlDialog().then((imageUrl) {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Insert the image placeholder at the current cursor position
        final cursorPosition = _controller.selection.baseOffset;
        final imagePlaceholder = '![image]($imageUrl)';
        
        final newText = _controller.text.replaceRange(
          cursorPosition, 
          cursorPosition, 
          imagePlaceholder
        );
        
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorPosition + imagePlaceholder.length),
        );
        
        // Notify parent about the change
        widget.onChanged(_controller.text, _controller.text);
        
        // Notify parent about added image
        if (widget.onImageAdded != null) {
          widget.onImageAdded!(imageUrl);
        }
      }
    });
  }
  
  // Show dialog to enter image URL
  Future<String?> _showImageUrlDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Image URL'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://example.com/image.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        children: [
          // Formatting toolbar
          if (!widget.readOnly)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Wrap(
                spacing: 4,
                children: [
                  // Bold
                  IconButton(
                    icon: const Icon(Icons.format_bold),
                    tooltip: 'Bold',
                    onPressed: () => _insertFormatting('**', '**'),
                  ),
                  
                  // Italic
                  IconButton(
                    icon: const Icon(Icons.format_italic),
                    tooltip: 'Italic',
                    onPressed: () => _insertFormatting('*', '*'),
                  ),
                  
                  // Heading
                  IconButton(
                    icon: const Icon(Icons.title),
                    tooltip: 'Heading',
                    onPressed: () => _insertFormatting('# ', ''),
                  ),
                  
                  // Bullet list
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted),
                    tooltip: 'Bullet List',
                    onPressed: () => _insertFormatting('- ', ''),
                  ),
                  
                  // Numbered list
                  IconButton(
                    icon: const Icon(Icons.format_list_numbered),
                    tooltip: 'Numbered List',
                    onPressed: () => _insertFormatting('1. ', ''),
                  ),
                ],
              ),
            ),
          
          // Custom toolbar for character, location, and image buttons
          if (!widget.readOnly)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  // Character button
                  Tooltip(
                    message: 'Add Character (@)',
                    child: IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () {
                        _showCharacterSelectionDialog();
                      },
                    ),
                  ),
                  
                  // Location button
                  Tooltip(
                    message: 'Add Location (#)',
                    child: IconButton(
                      icon: const Icon(Icons.place),
                      onPressed: () {
                        _showLocationSelectionDialog();
                      },
                    ),
                  ),
                  
                  // Image button
                  Tooltip(
                    message: 'Add Image',
                    child: IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () {
                        _addImage();
                      },
                    ),
                  ),
                  
                  // Move button
                  Tooltip(
                    message: 'Roll Move (Ctrl+M)',
                    child: IconButton(
                      icon: const Icon(Icons.sports_martial_arts),
                      onPressed: widget.onMoveRequested,
                    ),
                  ),
                  
                  // Oracle button
                  Tooltip(
                    message: 'Roll Oracle (Ctrl+O)',
                    child: IconButton(
                      icon: const Icon(Icons.casino),
                      onPressed: widget.onOracleRequested,
                    ),
                  ),
                ],
              ),
            ),
          
          // Editor
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // Main text field
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    readOnly: widget.readOnly,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.all(8),
                      border: InputBorder.none,
                      hintText: 'Write your journal entry here...',
                    ),
                    onChanged: (value) {
                      widget.onChanged(value, value);
                      _checkForMentions();
                    },
                    onTap: _checkForMentions,
                  ),
                  
                  // Inline suggestion overlay
                  if (_inlineSuggestion != null && _suggestionStartPosition != null)
                    Positioned(
                      left: 8, // Same as contentPadding
                      top: 8,   // Same as contentPadding
                      child: IgnorePointer(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              // Invisible text to match the user's input
                              TextSpan(
                                text: _controller.text.substring(0, _suggestionStartPosition! + _currentSearchText.length + 1),
                                style: TextStyle(
                                  color: Colors.transparent,
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                ),
                              ),
                              // Grey suggestion text
                              TextSpan(
                                text: _inlineSuggestion!.substring(_currentSearchText.length),
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.7),
                                  fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Insert formatting around selected text or at cursor position
  void _insertFormatting(String prefix, String suffix) {
    final selection = _controller.selection;
    final text = _controller.text;
    
    if (selection.isValid) {
      if (selection.isCollapsed) {
        // No text selected, just insert at cursor position
        final newText = text.replaceRange(selection.baseOffset, selection.baseOffset, '$prefix$suffix');
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.baseOffset + prefix.length),
        );
      } else {
        // Text selected, wrap it with formatting
        final selectedText = text.substring(selection.baseOffset, selection.extentOffset);
        final newText = text.replaceRange(selection.baseOffset, selection.extentOffset, '$prefix$selectedText$suffix');
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.baseOffset + prefix.length + selectedText.length + suffix.length),
        );
      }
      
      // Notify parent about the change
      widget.onChanged(_controller.text, _controller.text);
    }
  }
  
  // Show dialog to select a character
  void _showCharacterSelectionDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null || currentGame.characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Character'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: currentGame.characters.length,
              itemBuilder: (context, index) {
                final character = currentGame.characters[index];
                final handle = character.handle ?? character.getHandle();
                
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(character.name),
                  subtitle: Text(handle),
                  onTap: () {
                    Navigator.pop(context);
                    _insertMention(character);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  // Show dialog to select a location
  void _showLocationSelectionDialog() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null || currentGame.locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations available'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Location'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: currentGame.locations.length,
              itemBuilder: (context, index) {
                final location = currentGame.locations[index];
                
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(location.name),
                  onTap: () {
                    Navigator.pop(context);
                    _insertMention(location);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
