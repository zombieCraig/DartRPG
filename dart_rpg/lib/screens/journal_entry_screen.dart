import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/journal_entry.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';
import '../widgets/journal/rich_text_editor.dart';
import '../widgets/journal/linked_items_summary.dart';

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
            (e) => e.id == widget.entryId,
          );
          
          setState(() {
            _content = entry.content;
            _richContent = entry.richContent;
            _linkedCharacterIds = List.from(entry.linkedCharacterIds);
            _linkedLocationIds = List.from(entry.linkedLocationIds);
            _moveRolls = List.from(entry.moveRolls);
            _oracleRolls = List.from(entry.oracleRolls);
            _embeddedImages = List.from(entry.embeddedImages);
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
                  Text(moveRoll.moveDescription!),
                  const SizedBox(height: 16),
                ],
                
                Text('Action Die: ${moveRoll.actionDie}'),
                
                if (moveRoll.statValue != null) ...[
                  const SizedBox(height: 4),
                  Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                  const SizedBox(height: 4),
                  Text('Total Action Value: ${moveRoll.actionDie + moveRoll.statValue!}'),
                ],
                
                const SizedBox(height: 8),
                Text('Challenge Dice: ${moveRoll.challengeDice.join(', ')}'),
                
                const SizedBox(height: 16),
                Text(
                  'Outcome: ${moveRoll.outcome.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getOutcomeColor(moveRoll.outcome),
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
  
  void _showRollMoveDialog(BuildContext context) {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final moves = dataswornProvider.moves;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Move'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: moves.length,
              itemBuilder: (context, index) {
                final move = moves[index];
                return ListTile(
                  title: Text(move.name),
                  subtitle: move.description != null
                      ? Text(
                          move.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    // Roll the move
                    _rollMove(context, move);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  void _rollMove(BuildContext context, Move move) {
    // Roll the move
    final rollResult = DiceRoller.rollMove(statValue: 0);
    
    // Create a MoveRoll
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      stat: null,
      statValue: null,
      actionDie: rollResult['actionDie'] ?? 0,
      challengeDice: rollResult['challengeDice'] ?? [0, 0],
      outcome: rollResult['outcome'] ?? 'miss',
    );
    
    // Add to move rolls
    setState(() {
      _moveRolls.add(moveRoll);
    });
    
    // Show the roll details
    _showMoveRollDetailsDialog(context, moveRoll);
  }
  
  void _showRollOracleDialog(BuildContext context) {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final oracles = dataswornProvider.oracles;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Oracle'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: oracles.length,
              itemBuilder: (context, index) {
                final oracle = oracles[index];
                return ListTile(
                  title: Text(oracle.name),
                  onTap: () {
                    Navigator.pop(context);
                    // Roll the oracle
                    _rollOracle(context, oracle);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  
  void _rollOracle(BuildContext context, OracleCategory oracle) {
    // Roll the oracle
    final rollResult = DiceRoller.rollOracle(oracle.name);
    
    // Create an OracleRoll
    final oracleRoll = OracleRoll(
      oracleName: oracle.name,
      oracleTable: null,
      dice: [rollResult['roll'] ?? 0],
      result: rollResult['result'] ?? 'No result',
    );
    
    // Add to oracle rolls
    setState(() {
      _oracleRolls.add(oracleRoll);
    });
    
    // Show the roll details
    _showOracleRollDetailsDialog(context, oracleRoll);
  }
  
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null) {
        final file = result.files.first;
        final path = file.path;
        
        if (path != null) {
          setState(() {
            _embeddedImages.add(path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    
    return Scaffold(
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
          // Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RichTextEditor(
                initialText: _content,
                initialRichText: _richContent,
                readOnly: !_isEditing,
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
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    tooltip: 'Add Character',
                    onPressed: () {
                      _showQuickAddCharacterDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    tooltip: 'Add Location',
                    onPressed: () {
                      _showQuickAddLocationDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.casino),
                    tooltip: 'Roll Move',
                    onPressed: () {
                      _showRollMoveDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.casino),
                    tooltip: 'Roll Oracle',
                    onPressed: () {
                      _showRollOracleDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    tooltip: 'Add Image',
                    onPressed: () {
                      _pickImage();
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
