import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/journal_entry.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../utils/logging_service.dart';
import '../services/autosave_service.dart';
import '../widgets/journal/journal_entry_editor.dart';
import '../widgets/journal/linked_items_manager.dart';
import '../widgets/journal/linked_items_summary.dart';
import '../widgets/journal/journal_entry_viewer.dart';
import '../widgets/journal/move_dialog.dart';
import '../widgets/oracles/oracle_dialog.dart';
import 'game_screen.dart';

// Custom intents for keyboard shortcuts
class QuestsIntent extends Intent {
  const QuestsIntent();
}

class MovesIntent extends Intent {
  const MovesIntent();
}

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

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
  
  // Controller for the RichTextEditor
  final TextEditingController _editorController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.entryId == null;
    
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
  void _navigateToQuests(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentGame != null) {
      // Use pushReplacement to ensure we go directly to the Quests screen
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
  
  // Navigate to the Moves screen
  void _navigateToMoves(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentGame != null) {
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
  
  void _startAutoSaveTimer() {
    // Cancel any existing timer
    _autoSaveTimer?.cancel();
    
    // Start a new timer that will save after 2 seconds of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_isEditing) {
        _autoSave();
      }
    });
  }
  
  // Track if we've already created an entry during this editing session
  String? _createdEntryId;
  bool _isAutoSaving = false;
  
  void _autoSave() async {
    // Prevent multiple auto-saves from running simultaneously
    if (_isAutoSaving) return;
    
    _isAutoSaving = true;
    
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

  void _showMoveRollDetailsDialog(BuildContext context, MoveRoll moveRoll) {
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
                  MarkdownBody(
                    data: moveRoll.moveDescription!,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                      textAlign: WrapAlignment.start,
                    ),
                    softLineBreak: true,
                  ),
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
                ] else ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Move performed successfully',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
  
  void _showOracleRollDetailsDialog(BuildContext context, OracleRoll oracleRoll) {
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
  
  void _showCharacterDetailsDialog(BuildContext context, Character character) {
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
  
  void _showLocationDetailsDialog(BuildContext context, Location location) {
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
  
  void _showQuickAddCharacterDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController handleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Character'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Character Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: handleController,
                  decoration: const InputDecoration(
                    labelText: 'Short Name or Handle',
                    helperText: 'No spaces, @, #, or brackets. Will default to first name if blank.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final gameProvider = Provider.of<GameProvider>(context, listen: false);
                  final character = await gameProvider.createCharacter(
                    nameController.text,
                    handle: handleController.text.isEmpty ? null : handleController.text,
                  );
                  
                  setState(() {
                    _linkedCharacterIds.add(character.id);
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  void _showQuickAddLocationDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final gameProvider = Provider.of<GameProvider>(context, listen: false);
                  final location = await gameProvider.createLocation(
                    nameController.text,
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : null,
                  );
                  
                  setState(() {
                    _linkedLocationIds.add(location.id);
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
  
  // Move-related methods have been moved to the MoveDialog class
  
  void _rollOracleTable(BuildContext context, OracleTable table) {
    // Implementation of _rollOracleTable
    // This is a placeholder to fix the build error
  }
  
  Future<void> _pickImage() async {
    // Implementation of _pickImage
    // This is a placeholder to fix the build error
  }
  
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
  
  @override
  Widget build(BuildContext context) {
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
      },
      actions: {
        QuestsIntent: CallbackAction<QuestsIntent>(
          onInvoke: (QuestsIntent intent) {
            _navigateToQuests(context);
            return null;
          },
        ),
        MovesIntent: CallbackAction<MovesIntent>(
          onInvoke: (MovesIntent intent) {
            _navigateToMoves(context);
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entryId == null ? 'New Journal Entry' : 'Edit Journal Entry'),
          actions: [
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
                      onQuestRequested: () {
                        _navigateToQuests(context);
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
              Padding(
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
                      label: const Text('Add Location'),
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
