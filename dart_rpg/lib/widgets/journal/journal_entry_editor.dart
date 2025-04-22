import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../providers/image_manager_provider.dart';
import '../../services/autosave_service.dart';
import '../../models/journal_entry.dart';
import '../../widgets/common/image_picker_dialog.dart';
import 'editor_toolbar.dart';
import 'autocomplete_system.dart';
import 'linked_items_manager.dart';
import 'location_oracle_shortcuts.dart';
import 'linked_items_summary.dart';

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
  
  /// Callback for when a new entry is requested.
  final Function()? onNewEntryRequested;
  
  /// Callback for when the linked items button is pressed.
  final Function()? onLinkedItemsPressed;
  
  /// The controller for the text field.
  final TextEditingController? controller;
  
  /// The focus node for the text field.
  final FocusNode? focusNode;
  
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
    this.onNewEntryRequested,
    this.onLinkedItemsPressed,
    this.controller,
    this.focusNode,
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
  late FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();
  
  late AutocompleteSystem _autocompleteSystem;
  late LinkedItemsManager _linkedItemsManager;
  late AutosaveService? _autosaveService;
  
  // State for linked items visibility
  bool _showLinkedItems = false;
  
  @override
  void initState() {
    super.initState();
    
    // Use the controller provided by the parent widget or create a new one
    _controller = widget.controller ?? TextEditingController();
    
    // Use the focus node provided by the parent widget or create a new one
    _focusNode = widget.focusNode ?? FocusNode();
    
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
    
    // Only dispose the focus node if it was created by this widget
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    
    _scrollController.dispose();
    super.dispose();
  }
  
  // Toggle linked items visibility
  void _toggleLinkedItems() {
    setState(() {
      _showLinkedItems = !_showLinkedItems;
    });
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
    
    // Check for Ctrl+N for New Entry
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.keyN && 
        (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) &&
        widget.onNewEntryRequested != null) {
      widget.onNewEntryRequested!();
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
  Future<void> _addImage() async {
    // Show image picker dialog
    final result = await ImagePickerDialog.show(context);
    
    if (result != null) {
      final imageManagerProvider = Provider.of<ImageManagerProvider>(context, listen: false);
      String? imageUrl;
      String? imageId;
      
      // Process the result based on the type
      if (result['type'] == 'url') {
        // URL selected
        imageUrl = result['url'];
      } else if (result['type'] == 'file') {
        // File selected
        final file = result['file'] as File;
        
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving image...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Save the image
        final image = await imageManagerProvider.addImageFromFile(
          file,
          metadata: {'usage': 'journal'},
        );
        
        if (image != null) {
          imageId = image.id;
        }
      } else if (result['type'] == 'saved') {
        // Saved image selected
        imageId = result['imageId'];
      }
      
      // Insert the image placeholder at the current cursor position
      if (imageUrl != null || imageId != null) {
        final cursorPosition = _controller.selection.baseOffset;
        String imagePlaceholder;
        
        if (imageId != null) {
          // Use a special format for local images
          imagePlaceholder = '![image](id:$imageId)';
        } else {
          imagePlaceholder = '![image]($imageUrl)';
        }
        
        // Make sure cursorPosition is valid
        if (cursorPosition >= 0 && cursorPosition <= _controller.text.length) {
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
            if (imageUrl != null) {
              widget.onImageAdded!(imageUrl);
              _linkedItemsManager.addEmbeddedImage(imageUrl);
            } else if (imageId != null) {
              widget.onImageAdded!('id:$imageId');
              _linkedItemsManager.addEmbeddedImageId(imageId);
            }
          }
        } else {
          // Handle invalid cursor position
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Invalid cursor position'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
  
  // Performance metrics
  int _lastRebuildTime = 0;
  int _lastMentionCheckTime = 0;
  bool _shouldCheckMentions = false;
  
  // Show character details dialog
  void _showCharacterDetailsDialog(BuildContext context, dynamic character) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(character.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (character.bio != null && character.bio!.isNotEmpty) ...[
                  const Text(
                    'Bio:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(character.bio!),
                  const SizedBox(height: 16),
                ],
                
                // Stats
                if (character.stats.isNotEmpty) ...[
                  const Text(
                    'Stats:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: character.stats.map((stat) => 
                      Chip(
                        label: Text('${stat.name}: ${stat.value}'),
                        backgroundColor: Colors.grey[200],
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Notes
                if (character.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...character.notes.map((note) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Show location details dialog
  void _showLocationDetailsDialog(BuildContext context, dynamic location) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(location.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location.description != null && location.description!.isNotEmpty) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(location.description!),
                  const SizedBox(height: 16),
                ],
                
                if (location.notes.isNotEmpty) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...location.notes.map((note) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('• $note'),
                    )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Show move roll details dialog
  void _showMoveRollDetailsDialog(BuildContext context, dynamic moveRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${moveRoll.moveName} Roll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moveRoll.moveDescription != null) ...[
                  Text(moveRoll.moveDescription!),
                  const SizedBox(height: 16),
                ],
                
                if (moveRoll.rollType == 'action_roll') ...[
                  Text('Action Die: ${moveRoll.actionDie}'),
                  
                  if (moveRoll.statValue != null) ...[
                    const SizedBox(height: 4),
                    Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                    const SizedBox(height: 4),
                    Text('Total Action Value: ${moveRoll.actionDie + moveRoll.statValue!}'),
                  ],
                  
                  if (moveRoll.modifier != null && moveRoll.modifier != 0) ...[
                    const SizedBox(height: 4),
                    Text('Modifier: ${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}'),
                  ],
                ],
                
                if (moveRoll.rollType == 'progress_roll' && moveRoll.progressValue != null) ...[
                  Text('Progress Value: ${moveRoll.progressValue}'),
                ],
                
                if (moveRoll.challengeDice.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                ],
                
                if (moveRoll.outcome != 'performed') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Outcome: ${moveRoll.outcome.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getOutcomeColor(moveRoll.outcome),
                    ),
                  ),
                  
                  // Add Momentum Burned indicator
                  if (moveRoll.momentumBurned) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Momentum Burned',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Move performed successfully',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  
                  // Show oracle result if this is an oracle roll
                  if (moveRoll.rollType == 'oracle_roll' && 
                      moveRoll.moveData != null && 
                      moveRoll.moveData!.containsKey('oracleResult')) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Oracle Result: ${moveRoll.moveData!['oracleResult']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Show oracle roll details dialog
  void _showOracleRollDetailsDialog(BuildContext context, dynamic oracleRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${oracleRoll.oracleName} Result'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (oracleRoll.oracleTable != null) ...[
                  Text('Table: ${oracleRoll.oracleTable}'),
                  const SizedBox(height: 8),
                ],
                
                Text('Roll: ${oracleRoll.dice.join(', ')}'),
                const SizedBox(height: 16),
                
                Text(
                  'Result: ${oracleRoll.result}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Get color for move outcome
  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Colors.green;
      case 'weak hit':
        return Colors.orange;
      case 'miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    
    final gameProvider = Provider.of<GameProvider>(context);
    final currentGame = gameProvider.currentGame;
    
    // Create a memoized toolbar to prevent unnecessary rebuilds
    final toolbar = !widget.readOnly ? 
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
        onLinkedItemsPressed: _toggleLinkedItems,
      ) : null;
    
    // Only check for mentions if we need to
    if (_shouldCheckMentions && currentGame != null && !widget.readOnly) {
      final mentionStopwatch = Stopwatch()..start();
      
      _autocompleteSystem.checkForMentions(
        text: _controller.text,
        cursorPosition: _controller.selection.baseOffset,
        characters: currentGame.characters,
        locations: currentGame.locations,
      );
      
      _lastMentionCheckTime = mentionStopwatch.elapsedMicroseconds;
      _shouldCheckMentions = false;
    }
    
    return Column(
      children: [
        // Formatting toolbar
        if (toolbar != null) toolbar,
        
        // Location Oracle Shortcuts - only rebuild when linkedLocationIds changes
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
          
        // Linked Items Summary - only show when toggled
        if (_showLinkedItems && !widget.readOnly)
          Consumer<GameProvider>(
            builder: (context, gameProvider, _) {
              // Create temporary journal entry for the summary
              final tempEntry = JournalEntry(
                id: 'temp',
                content: _controller.text,
                linkedCharacterIds: _linkedItemsManager.linkedCharacterIds,
                linkedLocationIds: _linkedItemsManager.linkedLocationIds,
                moveRolls: _linkedItemsManager.moveRolls,
                oracleRolls: _linkedItemsManager.oracleRolls,
                embeddedImages: _linkedItemsManager.embeddedImages,
              );
              
              return Container(
                constraints: const BoxConstraints(maxHeight: 300), // Limit height
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: LinkedItemsSummary(
                      journalEntry: tempEntry,
                      onCharacterTap: (characterId) {
                        final character = gameProvider.currentGame!.characters
                            .firstWhere((c) => c.id == characterId);
                        _showCharacterDetailsDialog(context, character);
                      },
                      onLocationTap: (locationId) {
                        final location = gameProvider.currentGame!.locations
                            .firstWhere((l) => l.id == locationId);
                        _showLocationDetailsDialog(context, location);
                      },
                      onMoveRollTap: (moveRoll) {
                        _showMoveRollDetailsDialog(context, moveRoll);
                      },
                      onOracleRollTap: (oracleRoll) {
                        _showOracleRollDetailsDialog(context, oracleRoll);
                      },
                    ),
                  ),
                ),
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
                    // Only start autosave for substantial content
                    if (value.length > 20) {
                      _startAutoSaveTimer();
                    }
                    
                    widget.onChanged(value, value);
                    
                    // Check for mentions when needed
                    if (currentGame != null && !widget.readOnly) {
                      final cursorPosition = _controller.selection.baseOffset;
                      
                      // Always check if we just typed @ or #
                      if (cursorPosition > 0) {
                        final charBeforeCursor = value[cursorPosition - 1];
                        if (charBeforeCursor == '@' || charBeforeCursor == '#') {
                          // Immediately check for mentions when @ or # is typed
                          final mentionResult = _autocompleteSystem.checkForMentions(
                            text: value,
                            cursorPosition: cursorPosition,
                            characters: currentGame.characters,
                            locations: currentGame.locations,
                          );
                          
                          setState(() {});
                          return;
                        }
                      }
                      
                      // Continue checking if we're already in a mention context
                      if (_autocompleteSystem.showCharacterSuggestions || 
                          _autocompleteSystem.showLocationSuggestions) {
                        _shouldCheckMentions = true;
                        setState(() {});
                      }
                    }
                  },
                  onTap: () {
                    if (currentGame != null && !widget.readOnly) {
                      // Check for mentions on tap if we're in a mention context
                      final cursorPosition = _controller.selection.baseOffset;
                      if (cursorPosition > 0) {
                        final textBeforeCursor = _controller.text.substring(0, cursorPosition);
                        final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
                        final wordStart = lastSpaceOrNewline + 1;
                        
                        if (wordStart < textBeforeCursor.length) {
                          final currentWord = textBeforeCursor.substring(wordStart);
                          if (currentWord.startsWith('@') || currentWord.startsWith('#')) {
                            _autocompleteSystem.checkForMentions(
                              text: _controller.text,
                              cursorPosition: cursorPosition,
                              characters: currentGame.characters,
                              locations: currentGame.locations,
                            );
                            setState(() {});
                          }
                        }
                      }
                    }
                  },
                ),
                
                // Optimized inline suggestion overlay
                if ((_autocompleteSystem.inlineSuggestion != null && 
                    _autocompleteSystem.suggestionStartPosition != null) ||
                    _autocompleteSystem.showCharacterSuggestions ||
                    _autocompleteSystem.showLocationSuggestions)
                  Builder(
                    builder: (context) {
                      // Handle the case where we just typed @ or # without any additional characters
                      String textBeforeSuggestion = "";
                      String suggestionText = "";
                      
                      if (_autocompleteSystem.suggestionStartPosition != null) {
                        // Calculate the position of the suggestion more efficiently
                        final startPos = _autocompleteSystem.suggestionStartPosition!;
                        final searchTextLength = _autocompleteSystem.currentSearchText.length;
                        
                        if (startPos < _controller.text.length) {
                          final endPos = startPos + searchTextLength + 1 <= _controller.text.length 
                              ? startPos + searchTextLength + 1 
                              : _controller.text.length;
                          
                          textBeforeSuggestion = _controller.text.substring(0, endPos);
                          
                          if (_autocompleteSystem.inlineSuggestion != null && searchTextLength < _autocompleteSystem.inlineSuggestion!.length) {
                            suggestionText = _autocompleteSystem.inlineSuggestion!.substring(searchTextLength);
                          }
                        }
                      }
                      
                      return Positioned(
                        left: 8, // Same as contentPadding
                        top: 8,   // Same as contentPadding
                        child: IgnorePointer(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                // Invisible text to match the user's input
                                TextSpan(
                                  text: textBeforeSuggestion,
                                  style: TextStyle(
                                    color: Colors.transparent,
                                    fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                  ),
                                ),
                                // Grey suggestion text
                                TextSpan(
                                  text: suggestionText,
                                  style: TextStyle(
                                    color: Colors.grey.withAlpha(179), // 0.7 opacity = 179 alpha
                                    fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
