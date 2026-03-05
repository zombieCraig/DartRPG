import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/journal_entry.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../utils/logging_service.dart';
import '../widgets/journal/journal_entry_editor.dart';
import '../widgets/journal/linked_items_summary.dart';
import '../widgets/journal/journal_entry_viewer.dart';
import '../widgets/journal/journal_detail_dialogs.dart';
import '../widgets/journal/quick_add_dialogs.dart';
import '../widgets/journal/move_dialog.dart';
import '../widgets/journal/linked_items_manager.dart';
import '../widgets/journal/autocomplete_system.dart';
import '../widgets/oracles/oracle_dialog.dart';
import '../widgets/character/dialogs/character_edit_dialog.dart';
import 'game_screen.dart';

// Custom intents for keyboard shortcuts
class QuestsIntent extends Intent {
  const QuestsIntent();
}

class MovesIntent extends Intent {
  const MovesIntent();
}

class NewEntryIntent extends Intent {
  const NewEntryIntent();
}

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;
  final String? sourceScreen;
  final bool hideAppBarBackButton;

  const JournalEntryScreen({
    super.key, 
    this.entryId, 
    this.sourceScreen,
    this.hideAppBarBackButton = false,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  bool _isEditing = false;
  String _content = '';
  String? _richContent;
  List<String> _linkedCharacterIds = [];
  List<String> _linkedLocationIds = [];
  List<MoveRoll> _moveRolls = [];
  List<OracleRoll> _oracleRolls = [];
  List<String> _embeddedImages = [];
  Timer? _autoSaveTimer;
  
  /// Adds an oracle roll to the journal entry.
  void addOracleRoll(OracleRoll oracleRoll) {
    setState(() {
      _oracleRolls.add(oracleRoll);
    });
  }
  
  // Controller for the RichTextEditor
  final TextEditingController _editorController = TextEditingController();
  
  // Linked items manager
  late LinkedItemsManager _linkedItemsManager;
  
  // Autocomplete system
  late AutocompleteSystem _autocompleteSystem;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.entryId == null;
    
    // Initialize the linked items manager
    _linkedItemsManager = LinkedItemsManager(
      linkedCharacterIds: _linkedCharacterIds,
      linkedLocationIds: _linkedLocationIds,
      moveRolls: _moveRolls,
      oracleRolls: _oracleRolls,
      embeddedImages: _embeddedImages,
    );
    
    // Initialize the autocomplete system
    _autocompleteSystem = AutocompleteSystem();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntry();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
  
  // Navigate to the Quests screen
  Future<void> _navigateToQuests(BuildContext context) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentGame != null) {
      // If we're in editing mode, save the entry first
      if (_isEditing && _content.isNotEmpty) {
        try {
          // Show a loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving journal entry...'),
              duration: Duration(seconds: 1),
            ),
          );
          
          // Save the entry
          await _saveEntry();
          
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();
        } catch (e) {
          // Show error if saving fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving journal entry: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          // Still navigate even if save fails
        }
      }
      
      // Use pushReplacement to ensure we go directly to the Quests screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameId: gameProvider.currentGame!.id,
              initialTabIndex: 3, // Quests tab index
            ),
          ),
        );
      }
    }
  }
  
  // Navigate to the Moves screen
  Future<void> _navigateToMoves(BuildContext context) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentGame != null) {
      // If we're in editing mode, save the entry first
      if (_isEditing && _content.isNotEmpty) {
        try {
          // Show a loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving journal entry...'),
              duration: Duration(seconds: 1),
            ),
          );
          
          // Save the entry
          await _saveEntry();
          
          // Clear any existing snackbars
          ScaffoldMessenger.of(context).clearSnackBars();
        } catch (e) {
          // Show error if saving fails
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving journal entry: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          // Still navigate even if save fails
        }
      }
      
      // Use pushReplacement to ensure we go directly to the Moves screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              gameId: gameProvider.currentGame!.id,
              initialTabIndex: 4, // Moves tab index
            ),
          ),
        );
      }
    }
  }
  
  void _startAutoSaveTimer() {
    // Cancel any existing timer
    _autoSaveTimer?.cancel();
    
    // Start a new timer that will save after 10 seconds of inactivity (increased from 2)
    _autoSaveTimer = Timer(const Duration(seconds: 10), () {
      if (_isEditing) {
        _autoSave();
      }
    });
  }
  
  // Track if we've already created an entry during this editing session
  String? _createdEntryId;
  bool _isAutoSaving = false;
  
  // Focus node for the editor
  final FocusNode _editorFocusNode = FocusNode();
  
  // Performance metrics
  int _lastAutoSaveDuration = 0;
  
  void _autoSave() async {
    // Skip autosave for very short content
    if (_content.length < 20 && widget.entryId == null && _createdEntryId == null) {
      return;
    }
    
    // Prevent multiple auto-saves from running simultaneously
    if (_isAutoSaving) return;
    
    _isAutoSaving = true;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      // Auto-save for both new and existing entries
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final currentSession = gameProvider.currentSession;
      
      if (currentSession == null) {
        _isAutoSaving = false;
        return;
      }
      
      if (widget.entryId != null) {
        // Update existing entry
        final entry = currentSession.entries.firstWhere(
          (e) => e.id == widget.entryId,
        );
        
        // Update content
        entry.update(_content);
        entry.richContent = _richContent;
        
        // Update linked entities
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        
        // Update rolls
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        
        // Update embedded images
        entry.embeddedImages = _embeddedImages;
        
        // Save the changes
        await gameProvider.updateJournalEntry(widget.entryId!, _content);
        await gameProvider.saveGame();
        
      } else if (_content.isNotEmpty) {
        if (_createdEntryId == null) {
          // Create new entry if there's content and we haven't created one yet
          final entry = await gameProvider.createJournalEntry(_content);
          
          // Update the entry with additional data
          entry.richContent = _richContent;
          entry.linkedCharacterIds = _linkedCharacterIds;
          entry.linkedLocationIds = _linkedLocationIds;
          entry.moveRolls = _moveRolls;
          entry.oracleRolls = _oracleRolls;
          entry.embeddedImages = _embeddedImages;
          
          // Save the changes
          await gameProvider.saveGame();
          
          setState(() {
            _createdEntryId = entry.id; // Store the ID of the created entry
          });
        } else {
          // Update the entry we already created
          final entry = currentSession.entries.firstWhere(
            (e) => e.id == _createdEntryId,
          );
          
          // Update content
          entry.update(_content);
          entry.richContent = _richContent;
          
          // Update linked entities
          entry.linkedCharacterIds = _linkedCharacterIds;
          entry.linkedLocationIds = _linkedLocationIds;
          
          // Update rolls
          entry.moveRolls = _moveRolls;
          entry.oracleRolls = _oracleRolls;
          
          // Update embedded images
          entry.embeddedImages = _embeddedImages;
          
          // Save the changes
          await gameProvider.updateJournalEntry(_createdEntryId!, _content);
          await gameProvider.saveGame();
        }
      }
    } catch (e) {
      // Log errors during auto-save
      LoggingService().error(
        'Error during auto-save',
        tag: 'JournalEntryScreen',
        error: e,
        stackTrace: StackTrace.current
      );
    } finally {
      _isAutoSaving = false;
      _lastAutoSaveDuration = stopwatch.elapsedMilliseconds;
      
      // Log performance metrics
      LoggingService().debug(
        'Journal entry autosave completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'JournalEntryScreen',
      );
    }
  }

  void _loadEntry() {
    if (widget.entryId != null) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final currentSession = gameProvider.currentSession;

      if (currentSession != null) {
        try {
          final entry = currentSession.entries.firstWhere(
            (e) => e.id == widget.entryId
          );

          setState(() {
            _content = entry.content;
            _richContent = entry.richContent;
            _linkedCharacterIds = List.from(entry.linkedCharacterIds);
            _linkedLocationIds = List.from(entry.linkedLocationIds);
            _moveRolls = List.from(entry.moveRolls);
            _oracleRolls = List.from(entry.oracleRolls);
            _embeddedImages = List.from(entry.embeddedImages);
            
            // Update the linked items manager
            _linkedItemsManager = LinkedItemsManager(
              linkedCharacterIds: _linkedCharacterIds,
              linkedLocationIds: _linkedLocationIds,
              moveRolls: _moveRolls,
              oracleRolls: _oracleRolls,
              embeddedImages: _embeddedImages,
            );
            
            // Update the editor controller with the loaded content
            _editorController.text = entry.content;
          });
        } catch (e) {
          // Entry not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entry not found: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveEntry() async {
    if (_content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save an empty entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    try {
      if (widget.entryId != null) {
        // Update existing entry
        await gameProvider.updateJournalEntry(widget.entryId!, _content);
        
        // Update the entry object with additional data
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == widget.entryId,
        );
        
        entry.richContent = _richContent;
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        entry.embeddedImages = _embeddedImages;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
        
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (_createdEntryId != null) {
        // Update the entry that was already created by autosave
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == _createdEntryId,
        );
        
        // Update content
        entry.update(_content);
        entry.richContent = _richContent;
        
        // Update linked entities
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        
        // Update rolls
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        
        // Update embedded images
        entry.embeddedImages = _embeddedImages;
        
        // Save the changes
        await gameProvider.updateJournalEntry(_createdEntryId!, _content);
        await gameProvider.saveGame();
        
        setState(() {
          _isEditing = false;
        });
        
        // Navigate back to journal screen
        if (context.mounted) {
          Navigator.pop(context);
        }
      } else {
        // Create new entry
        final entry = await gameProvider.createJournalEntry(_content);
        
        // Update the entry object with additional data
        entry.richContent = _richContent;
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        entry.embeddedImages = _embeddedImages;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
        
        setState(() {
          _createdEntryId = entry.id;
          _isEditing = false;
        });
        
        // Navigate back to journal screen
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving journal entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMoveRollDetailsDialog(BuildContext context, MoveRoll moveRoll) =>
      JournalDetailDialogs.showMoveRollDetails(context, moveRoll);

  void _showOracleRollDetailsDialog(BuildContext context, OracleRoll oracleRoll) =>
      JournalDetailDialogs.showOracleRollDetails(context, oracleRoll);

  void _showCharacterDetailsDialog(BuildContext context, Character character) =>
      JournalDetailDialogs.showCharacterDetails(context, character);

  void _showLocationDetailsDialog(BuildContext context, Location location) =>
      JournalDetailDialogs.showLocationDetails(context, location);
  
  void _showQuickAddCharacterDialog(BuildContext context) {
    QuickAddDialogs.showAddCharacter(
      context,
      onCharacterCreated: (characterId) {
        setState(() {
          _linkedCharacterIds.add(characterId);
        });
      },
    );
  }
  
  void _showQuickAddLocationDialog(BuildContext context) {
    QuickAddDialogs.showAddLocation(
      context,
      onLocationCreated: (location) {
        setState(() {
          _linkedLocationIds.add(location.id);
        });

        if (_isEditing && _editorController.text.isNotEmpty) {
          final result = _autocompleteSystem.insertMention(
            location,
            _editorController.text,
            _editorController.selection.baseOffset,
          );

          _editorController.value = TextEditingValue(
            text: result['text'],
            selection: TextSelection.collapsed(offset: result['cursorPosition']),
          );

          setState(() {
            _content = _editorController.text;
          });

          _startAutoSaveTimer();
        }
      },
    );
  }
  
  // Move-related methods have been moved to the MoveDialog class
  
  void _showRollMoveDialog(BuildContext context) {
    // Only show the dialog if we're in editing mode
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be in edit mode to roll moves'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    MoveDialog.show(
      context,
      onMoveRollAdded: (moveRoll) {
        setState(() {
          _moveRolls.add(moveRoll);
        });
      },
      onInsertText: (text) {
        JournalEntryEditor.insertTextAtCursor(_editorController, text);
        
        // Update the content
        setState(() {
          _content = _editorController.text;
        });
        
        // Start auto-save timer
        _startAutoSaveTimer();
      },
      isEditing: true, // Always true since we check above
    );
  }
  
  void _showRollOracleDialog(BuildContext context) {
    // Only show the dialog if we're in editing mode
    if (!_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be in edit mode to roll oracles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Use the OracleDialog class to show the dialog
    OracleDialog.show(
      context,
      onOracleRollAdded: (oracleRoll) {
        setState(() {
          _oracleRolls.add(oracleRoll);
        });
      },
      onInsertText: (text) {
        JournalEntryEditor.insertTextAtCursor(_editorController, text);
        
        // Update the content
        setState(() {
          _content = _editorController.text;
        });
        
        // Start auto-save timer
        _startAutoSaveTimer();
      },
      isEditing: true, // Always true since we check above
    );
  }
  
  // Show the character edit dialog for the main character
  // Save the current entry and create a new one
  Future<void> _saveAndCreateNew() async {
    // First save the current entry
    if (_content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save an empty entry'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    try {
      if (widget.entryId != null) {
        // Update existing entry
        await gameProvider.updateJournalEntry(widget.entryId!, _content);
        
        // Update the entry object with additional data
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == widget.entryId,
        );
        
        entry.richContent = _richContent;
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        entry.embeddedImages = _embeddedImages;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
      } else if (_createdEntryId != null) {
        // Update the entry that was already created by autosave
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == _createdEntryId,
        );
        
        // Update content
        entry.update(_content);
        entry.richContent = _richContent;
        
        // Update linked entities
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        
        // Update rolls
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        
        // Update embedded images
        entry.embeddedImages = _embeddedImages;
        
        // Save the changes
        await gameProvider.updateJournalEntry(_createdEntryId!, _content);
        await gameProvider.saveGame();
      } else {
        // Create new entry
        final entry = await gameProvider.createJournalEntry(_content);
        
        // Update the entry object with additional data
        entry.richContent = _richContent;
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRolls = _moveRolls;
        entry.oracleRolls = _oracleRolls;
        entry.embeddedImages = _embeddedImages;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
        
        setState(() {
          _createdEntryId = entry.id;
        });
      }
      
      // Reset state for new entry
      setState(() {
        _content = '';
        _richContent = null;
        _linkedCharacterIds = [];
        _linkedLocationIds = [];
        _moveRolls = [];
        _oracleRolls = [];
        _embeddedImages = [];
        _createdEntryId = null;
        
        // Reset the editor controller
        _editorController.clear();
        
        // Update the linked items manager
        _linkedItemsManager = LinkedItemsManager(
          linkedCharacterIds: _linkedCharacterIds,
          linkedLocationIds: _linkedLocationIds,
          moveRolls: _moveRolls,
          oracleRolls: _oracleRolls,
          embeddedImages: _embeddedImages,
        );
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry saved. Started new entry.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Focus the editor
      _editorFocusNode.requestFocus();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving journal entry: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showCharacterEditDialog(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null || currentGame.mainCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No main character found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Show the character edit dialog for the main character
    CharacterEditDialog.show(
      context,
      gameProvider,
      currentGame.mainCharacter!,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final buildStopwatch = Stopwatch()..start();
    
    final gameProvider = Provider.of<GameProvider>(context);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null) {
      return const Scaffold(
        body: Center(
          child: Text('No game selected'),
        ),
      );
    }
    
    // Add keyboard shortcuts
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ): 
            const QuestsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyM): 
            const MovesIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): 
            const NewEntryIntent(),
      },
      actions: {
        QuestsIntent: CallbackAction<QuestsIntent>(
          onInvoke: (QuestsIntent intent) async {
            await _navigateToQuests(context);
            return null;
          },
        ),
        MovesIntent: CallbackAction<MovesIntent>(
          onInvoke: (MovesIntent intent) async {
            await _navigateToMoves(context);
            return null;
          },
        ),
        NewEntryIntent: CallbackAction<NewEntryIntent>(
          onInvoke: (NewEntryIntent intent) {
            if (_isEditing) {
              _saveAndCreateNew();
            }
            return null;
          },
        ),
      },
      child: Scaffold(
        floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _saveAndCreateNew,
              tooltip: 'Save and Create New Entry (Ctrl+N)',
              child: const Icon(Icons.note_add),
            )
          : null,
        appBar: AppBar(
          title: Text(widget.entryId == null ? 'New Journal Entry' : 'Edit Journal Entry'),
          automaticallyImplyLeading: !widget.hideAppBarBackButton,
          actions: [
            // Character edit icon - only show if there's a main character
            if (currentGame.mainCharacter != null)
              IconButton(
                icon: const Icon(Icons.assignment_ind),
                tooltip: 'Edit Character',
                onPressed: () => _showCharacterEditDialog(context),
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: _saveEntry,
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
        body: Column(
          children: [
            // Editor or Viewer
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isEditing
                  ? JournalEntryEditor(
                      initialText: _content,
                      initialRichText: _richContent,
                      readOnly: false,
                      controller: _editorController,
                      focusNode: _editorFocusNode,
                      linkedItemsManager: _linkedItemsManager,
                      onChanged: (plainText, richText) {
                        setState(() {
                          _content = plainText;
                          _richContent = richText;
                        });
                        _startAutoSaveTimer();
                      },
                      onCharacterLinked: (characterId) {
                        setState(() {
                          if (!_linkedCharacterIds.contains(characterId)) {
                            _linkedCharacterIds.add(characterId);
                          }
                        });
                      },
                      onLocationLinked: (locationId) {
                        setState(() {
                          if (!_linkedLocationIds.contains(locationId)) {
                            _linkedLocationIds.add(locationId);
                          }
                        });
                      },
                      onImageAdded: (imageUrl) {
                        setState(() {
                          if (!_embeddedImages.contains(imageUrl)) {
                            _embeddedImages.add(imageUrl);
                          }
                        });
                      },
                      onMoveRequested: () {
                        _showRollMoveDialog(context);
                      },
                      onOracleRequested: () {
                        _showRollOracleDialog(context);
                      },
                      // Only show the quest button if we didn't come from the quests screen
                      onQuestRequested: widget.sourceScreen != 'quests' ? () {
                        _navigateToQuests(context);
                      } : null,
                      onNewEntryRequested: _saveAndCreateNew,
                      onLinkedItemsPressed: () {
                        // This is handled internally by the JournalEntryEditor
                      },
                    )
                  : JournalEntryViewer(
                      content: _content,
                      moveRolls: _moveRolls,
                      oracleRolls: _oracleRolls,
                      onCharacterTap: (character) {
                        _showCharacterDetailsDialog(context, character);
                      },
                      onLocationTap: (location) {
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
            
            // Linked items summary
            if (!_isEditing && (
                _linkedCharacterIds.isNotEmpty || 
                _linkedLocationIds.isNotEmpty || 
                _moveRolls.isNotEmpty || 
                _oracleRolls.isNotEmpty
              ))
              Container(
                constraints: const BoxConstraints(maxHeight: 300), // Limit height to prevent overflow
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LinkedItemsSummary(
                      journalEntry: JournalEntry(
                        id: widget.entryId ?? _createdEntryId ?? '',
                        content: _content,
                        richContent: _richContent,
                        linkedCharacterIds: _linkedCharacterIds,
                        linkedLocationIds: _linkedLocationIds,
                        moveRolls: _moveRolls,
                        oracleRolls: _oracleRolls,
                        embeddedImages: _embeddedImages,
                      ),
                      onCharacterTap: (characterId) {
                        final gameProvider = Provider.of<GameProvider>(context, listen: false);
                        final character = gameProvider.currentGame!.characters
                            .firstWhere((c) => c.id == characterId);
                        _showCharacterDetailsDialog(context, character);
                      },
                      onLocationTap: (locationId) {
                        final gameProvider = Provider.of<GameProvider>(context, listen: false);
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
              ),
            
            // Toolbar for editing mode
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Character'),
                      onPressed: () => _showQuickAddCharacterDialog(context),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_location),
                      label: const Text('Create Location'),
                      onPressed: () => _showQuickAddLocationDialog(context),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
