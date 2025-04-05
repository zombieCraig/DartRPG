import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/autosave_service.dart';
import 'editor_toolbar.dart';
import 'autocomplete_system.dart';
import 'linked_items_manager.dart';
import 'location_oracle_shortcuts.dart';

/// A widget for editing journal entries with rich text formatting and autocompletion.
class JournalEntryEditor extends StatefulWidget {
  /// The initial text content of the editor.
  final String initialText;
  
  /// The initial rich text content of the editor.
  final String? initialRichText;
  
  /// Whether the editor is read-only.
  final bool readOnly;
  
  /// Callback for when the content changes.
  final Function(String plainText, String richText) onChanged;
  
  /// Callback for when a character is linked.
  final Function(String characterId)? onCharacterLinked;
  
  /// Callback for when a location is linked.
  final Function(String locationId)? onLocationLinked;
  
  /// Callback for when an image is added.
  final Function(String imageUrl)? onImageAdded;
  
  /// Callback for when a move is requested.
  final Function()? onMoveRequested;
  
  /// Callback for when an oracle is requested.
  final Function()? onOracleRequested;
  
  /// Callback for when a quest is requested.
  final Function()? onQuestRequested;
  
  /// The controller for the text field.
  final TextEditingController? controller;
  
  /// The autosave service to use.
  final AutosaveService? autosaveService;
  
  /// The linked items manager to use.
  final LinkedItemsManager? linkedItemsManager;
  
  /// Creates a new JournalEntryEditor.
  const JournalEntryEditor({
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
    this.onQuestRequested,
    this.controller,
    this.autosaveService,
    this.linkedItemsManager,
  });
  
  /// Inserts text at the current cursor position.
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
  State<JournalEntryEditor> createState() => _JournalEntryEditorState();
}

class _JournalEntryEditorState extends State<JournalEntryEditor> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late AutocompleteSystem _autocompleteSystem;
  late LinkedItemsManager _linkedItemsManager;
  late AutosaveService? _autosaveService;
  
  @override
  void initState() {
    super.initState();
    
    // Use the controller provided by the parent widget or create a new one
    _controller = widget.controller ?? TextEditingController();
    
    // Initialize the controller with the initial text if it's empty
    if (_controller.text.isEmpty) {
      _controller.text = widget.initialText;
    }
    
    // Initialize the autocomplete system
    _autocompleteSystem = AutocompleteSystem();
    
    // Initialize the linked items manager
    _linkedItemsManager = widget.linkedItemsManager ?? LinkedItemsManager();
    
    // Initialize the autosave service
    _autosaveService = widget.autosaveService;
    
    // Set up keyboard shortcuts
    _focusNode.onKeyEvent = _handleKeyEvent;
  }
  
  @override
  void dispose() {
    // Only dispose the controller if it was created by this widget
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _scrollController.dispose();
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
    
    // Check for Ctrl+Q for Quests
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.keyQ && 
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
        widget.onQuestRequested != null) {
      widget.onQuestRequested!();
      return KeyEventResult.handled;
    }
    
    // Check for Tab or Enter key for autocomplete
    if (event is KeyDownEvent && 
        (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.enter)) {
      final result = _autocompleteSystem.handleTabOrEnterKey(
        _controller.text,
        _controller.selection.baseOffset,
      );
      
      if (result != null) {
        // Update the text
        _controller.value = TextEditingValue(
          text: result['text'],
          selection: TextSelection.collapsed(offset: result['cursorPosition']),
        );
        
        // Notify parent about the change
        widget.onChanged(_controller.text, _controller.text);
        
        // Notify parent about linked entity
        if (result['isCharacter'] && widget.onCharacterLinked != null) {
          widget.onCharacterLinked!(result['entityId']);
          _linkedItemsManager.addCharacter(result['entityId']);
        } else if (!result['isCharacter'] && widget.onLocationLinked != null) {
          widget.onLocationLinked!(result['entityId']);
          _linkedItemsManager.addLocation(result['entityId']);
        }
        
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
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
  
  // Insert a mention at the current cursor position
  void _insertMention(dynamic entity) {
    final result = _autocompleteSystem.insertMention(
      entity,
      _controller.text,
      _controller.selection.baseOffset,
    );
    
    // Update the text
    _controller.value = TextEditingValue(
      text: result['text'],
      selection: TextSelection.collapsed(offset: result['cursorPosition']),
    );
    
    // Notify parent about the change
    widget.onChanged(_controller.text, _controller.text);
    
    // Notify parent about linked entity
    if (result['isCharacter'] && widget.onCharacterLinked != null) {
      widget.onCharacterLinked!(result['entityId']);
      _linkedItemsManager.addCharacter(result['entityId']);
    } else if (!result['isCharacter'] && widget.onLocationLinked != null) {
      widget.onLocationLinked!(result['entityId']);
      _linkedItemsManager.addLocation(result['entityId']);
    }
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
          _linkedItemsManager.addEmbeddedImage(imageUrl);
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
  
  // Start the autosave timer
  void _startAutoSaveTimer() {
    if (_autosaveService != null && !widget.readOnly) {
      _autosaveService!.startAutoSaveTimer(
        onSave: _autoSave,
      );
    }
  }
  
  // Perform an autosave
  void _autoSave() {
    if (_autosaveService != null && !widget.readOnly) {
      _autosaveService!.autoSave(
        context: context,
        entryId: null, // This will be provided by the parent widget if needed
        content: _controller.text,
        richContent: _controller.text, // Using the same text for now
        linkedCharacterIds: _linkedItemsManager.linkedCharacterIds,
        linkedLocationIds: _linkedItemsManager.linkedLocationIds,
        moveRolls: _linkedItemsManager.moveRolls,
        oracleRolls: _linkedItemsManager.oracleRolls,
        embeddedImages: _linkedItemsManager.embeddedImages,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final currentGame = gameProvider.currentGame;
    
    return Column(
      children: [
        // Formatting toolbar
        if (!widget.readOnly)
          EditorToolbar(
            onBoldPressed: () => _insertFormatting('**', '**'),
            onItalicPressed: () => _insertFormatting('*', '*'),
            onHeadingPressed: () => _insertFormatting('# ', ''),
            onBulletListPressed: () => _insertFormatting('- ', ''),
            onNumberedListPressed: () => _insertFormatting('1. ', ''),
            onCharacterPressed: _showCharacterSelectionDialog,
            onLocationPressed: _showLocationSelectionDialog,
            onImagePressed: _addImage,
            onMovePressed: widget.onMoveRequested,
            onOraclePressed: widget.onOracleRequested,
            onQuestPressed: widget.onQuestRequested,
          ),
        
        // Location Oracle Shortcuts
        if (!widget.readOnly && _linkedItemsManager.linkedLocationIds.isNotEmpty)
          Consumer<DataswornProvider>(
            builder: (context, dataswornProvider, _) {
              return LocationOracleShortcuts(
                linkedLocationIds: _linkedItemsManager.linkedLocationIds,
                onOracleRollAdded: (oracleRoll) {
                  _linkedItemsManager.addOracleRoll(oracleRoll);
                  // Notify parent about the change
                  widget.onChanged(_controller.text, _controller.text);
                },
                onInsertText: (text) {
                  JournalEntryEditor.insertTextAtCursor(_controller, text);
                  // Notify parent about the change
                  widget.onChanged(_controller.text, _controller.text);
                  // Start autosave timer
                  _startAutoSaveTimer();
                },
              );
            },
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
                    
                    if (currentGame != null && !widget.readOnly) {
                      // Check for mentions
                      _autocompleteSystem.checkForMentions(
                        text: value,
                        cursorPosition: _controller.selection.baseOffset,
                        characters: currentGame.characters,
                        locations: currentGame.locations,
                      );
                      
                      // Start autosave timer
                      _startAutoSaveTimer();
                    }
                    
                    setState(() {});
                  },
                  onTap: () {
                    if (currentGame != null && !widget.readOnly) {
                      // Check for mentions
                      _autocompleteSystem.checkForMentions(
                        text: _controller.text,
                        cursorPosition: _controller.selection.baseOffset,
                        characters: currentGame.characters,
                        locations: currentGame.locations,
                      );
                      
                      setState(() {});
                    }
                  },
                ),
                
                // Inline suggestion overlay
                if (_autocompleteSystem.inlineSuggestion != null && 
                    _autocompleteSystem.suggestionStartPosition != null)
                  Positioned(
                    left: 8, // Same as contentPadding
                    top: 8,   // Same as contentPadding
                    child: IgnorePointer(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            // Invisible text to match the user's input
                            TextSpan(
                              text: _controller.text.substring(
                                0, 
                                _autocompleteSystem.suggestionStartPosition! + 
                                _autocompleteSystem.currentSearchText.length + 1
                              ),
                              style: TextStyle(
                                color: Colors.transparent,
                                fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                              ),
                            ),
                            // Grey suggestion text
                            TextSpan(
                              text: _autocompleteSystem.inlineSuggestion!.substring(
                                _autocompleteSystem.currentSearchText.length
                              ),
                              style: TextStyle(
                                color: Colors.grey.withAlpha(179), // 0.7 opacity = 179 alpha
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
    );
  }
}
