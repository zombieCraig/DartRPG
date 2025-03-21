import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/journal_entry.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../models/move.dart';
import '../models/oracle.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? entryId;

  const JournalEntryScreen({super.key, this.entryId});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  bool _isEditing = false;
  List<String> _linkedCharacterIds = [];
  List<String> _linkedLocationIds = [];
  MoveRoll? _moveRoll;
  OracleRoll? _oracleRoll;
  Timer? _autoSaveTimer;
  
  // For autocomplete
  bool _showCharacterSuggestions = false;
  bool _showLocationSuggestions = false;
  String _currentSearchText = '';
  int _cursorPosition = 0;
  List<dynamic> _filteredSuggestions = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // For move and oracle search
  final TextEditingController _moveSearchController = TextEditingController();
  final TextEditingController _oracleSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.entryId == null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntry();
    });
    
    // Set up auto-save when content changes
    _contentController.addListener(_startAutoSaveTimer);
    
    // Set up listener for @ and # characters
    _contentController.addListener(_checkForMentions);
    
    // Set up focus node listener to hide suggestions when focus is lost
    _contentFocusNode.addListener(() {
      if (!_contentFocusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_startAutoSaveTimer);
    _contentController.removeListener(_checkForMentions);
    _autoSaveTimer?.cancel();
    _removeOverlay();
    _contentController.dispose();
    _contentFocusNode.dispose();
    _moveSearchController.dispose();
    _oracleSearchController.dispose();
    super.dispose();
  }
  
  void _checkForMentions() {
    if (!_isEditing) return;
    
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (!selection.isValid || selection.isCollapsed == false) {
      _removeOverlay();
      return;
    }
    
    _cursorPosition = selection.start;
    
    // Find the word being typed (from the last space or newline to the cursor)
    final textBeforeCursor = text.substring(0, _cursorPosition);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final currentWord = textBeforeCursor.substring(lastSpaceOrNewline + 1);
    
    if (currentWord.startsWith('@') && currentWord.length > 1) {
      _currentSearchText = currentWord.substring(1).toLowerCase();
      _showCharacterSuggestions = true;
      _showLocationSuggestions = false;
      _updateSuggestions();
    } else if (currentWord.startsWith('#') && currentWord.length > 1) {
      _currentSearchText = currentWord.substring(1).toLowerCase();
      _showCharacterSuggestions = false;
      _showLocationSuggestions = true;
      _updateSuggestions();
    } else {
      _removeOverlay();
    }
  }
  
  void _updateSuggestions() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null) return;
    
    if (_showCharacterSuggestions) {
      _filteredSuggestions = currentGame.characters
          .where((c) => c.name.toLowerCase().contains(_currentSearchText))
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
      return;
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
                  return ListTile(
                    leading: Icon(
                      _showCharacterSuggestions ? Icons.person : Icons.place,
                      size: 20,
                    ),
                    title: Text(suggestion.name),
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
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (!selection.isValid) {
      _removeOverlay();
      return;
    }
    
    // Find the start of the current word
    final textBeforeCursor = text.substring(0, selection.start);
    final lastSpaceOrNewline = textBeforeCursor.lastIndexOf(RegExp(r'[\s\n]'));
    final wordStart = lastSpaceOrNewline + 1;
    
    // Replace the current word with the mention
    final prefix = _showCharacterSuggestions ? '@' : '#';
    final mentionText = '$prefix${entity.name} ';
    
    final newText = text.replaceRange(wordStart, selection.start, mentionText);
    
    // Update the text and cursor position
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: wordStart + mentionText.length,
      ),
    );
    
    // Add to linked entities
    if (_showCharacterSuggestions) {
      if (!_linkedCharacterIds.contains(entity.id)) {
        setState(() {
          _linkedCharacterIds.add(entity.id);
        });
      }
    } else if (_showLocationSuggestions) {
      if (!_linkedLocationIds.contains(entity.id)) {
        setState(() {
          _linkedLocationIds.add(entity.id);
        });
      }
    }
    
    _removeOverlay();
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
        entry.update(_contentController.text);
        
        // Save the changes
        await gameProvider.updateJournalEntry(widget.entryId!, _contentController.text);
        
      } else if (_contentController.text.isNotEmpty) {
        if (_createdEntryId == null) {
          // Create new entry if there's content and we haven't created one yet
          final entry = await gameProvider.createJournalEntry(_contentController.text);
          setState(() {
            _createdEntryId = entry.id; // Store the ID of the created entry
          });
        } else {
          // Update the entry we already created
          await gameProvider.updateJournalEntry(_createdEntryId!, _contentController.text);
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
          
          _contentController.text = entry.content;
          setState(() {
            _linkedCharacterIds = List.from(entry.linkedCharacterIds);
            _linkedLocationIds = List.from(entry.linkedLocationIds);
            _moveRoll = entry.moveRoll;
            _oracleRoll = entry.oracleRoll;
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
    if (_contentController.text.isEmpty) {
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
        await gameProvider.updateJournalEntry(widget.entryId!, _contentController.text);
        
        // Update the entry object with linked entities and rolls
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == widget.entryId,
        );
        
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRoll = _moveRoll;
        entry.oracleRoll = _oracleRoll;
        
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
      } else {
        // Create new entry
        final entry = await gameProvider.createJournalEntry(_contentController.text);
        
        // Update the entry object with linked entities and rolls
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRoll = _moveRoll;
        entry.oracleRoll = _oracleRoll;
        
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

  Future<void> _saveEntryWithoutNavigation() async {
    if (_contentController.text.isEmpty) {
      return;
    }

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    try {
      if (widget.entryId != null) {
        // Update existing entry
        await gameProvider.updateJournalEntry(widget.entryId!, _contentController.text);
        
        // Update the entry object with linked entities and rolls
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == widget.entryId,
        );
        
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRoll = _moveRoll;
        entry.oracleRoll = _oracleRoll;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
      } else if (_createdEntryId != null) {
        // Update the entry we already created
        await gameProvider.updateJournalEntry(_createdEntryId!, _contentController.text);
        
        // Update the entry object with linked entities and rolls
        final entry = gameProvider.currentSession!.entries.firstWhere(
          (e) => e.id == _createdEntryId,
        );
        
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRoll = _moveRoll;
        entry.oracleRoll = _oracleRoll;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
      } else {
        // Create new entry
        final entry = await gameProvider.createJournalEntry(_contentController.text);
        
        // Update the entry object with linked entities and rolls
        entry.linkedCharacterIds = _linkedCharacterIds;
        entry.linkedLocationIds = _linkedLocationIds;
        entry.moveRoll = _moveRoll;
        entry.oracleRoll = _oracleRoll;
        
        // Save the game to persist the changes
        await gameProvider.saveGame();
        
        _createdEntryId = entry.id;
      }
    } catch (e) {
      LoggingService().error(
        'Error saving entry without navigation',
        tag: 'JournalEntryScreen',
        error: e,
        stackTrace: StackTrace.current
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Save the entry if we're editing and there's content
        if (_isEditing && _contentController.text.isNotEmpty) {
          await _saveEntryWithoutNavigation();
          if (!didPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entryId == null ? 'New Journal Entry' : 'Journal Entry'),
          actions: [
            if (widget.entryId != null && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                  // Focus the text field
                  _contentFocusNode.requestFocus();
                },
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveEntry,
              ),
          ],
        ),
        body: Consumer<GameProvider>(
          builder: (context, gameProvider, _) {
            final currentGame = gameProvider.currentGame;
            final currentSession = gameProvider.currentSession;
            
            if (currentGame == null || currentSession == null) {
              return const Center(
                child: Text('No game or session selected'),
              );
            }
            
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content text field
                  Expanded(
                    child: _isEditing
                        ? CompositedTransformTarget(
                            link: _layerLink,
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (KeyEvent event) {
                                if (event is KeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.tab &&
                                    (_showCharacterSuggestions || _showLocationSuggestions) &&
                                    _filteredSuggestions.isNotEmpty) {
                                  _insertMention(_filteredSuggestions.first);
                                  return;
                                }
                              },
                              child: TextField(
                                controller: _contentController,
                                focusNode: _contentFocusNode,
                                maxLines: null,
                                expands: true,
                                decoration: const InputDecoration(
                                  hintText: 'Write your journal entry here...\nTip: Type @ to mention a character or # to mention a location\nPress Tab to autocomplete',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: _buildRichText(context, currentGame),
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Linked entities
                  if (_linkedCharacterIds.isNotEmpty || _linkedLocationIds.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Linked Entities',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._linkedCharacterIds.map((id) {
                              try {
                                final character = currentGame.characters.firstWhere(
                                  (c) => c.id == id,
                                );
                                return Chip(
                                  avatar: const Icon(Icons.person, size: 16),
                                  label: Text(character.name),
                                  onDeleted: _isEditing
                                      ? () {
                                          setState(() {
                                            _linkedCharacterIds.remove(id);
                                          });
                                        }
                                      : null,
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            }),
                            ..._linkedLocationIds.map((id) {
                              try {
                                final location = currentGame.locations.firstWhere(
                                  (l) => l.id == id,
                                );
                                return Chip(
                                  avatar: const Icon(Icons.place, size: 16),
                                  label: Text(location.name),
                                  onDeleted: _isEditing
                                      ? () {
                                          setState(() {
                                            _linkedLocationIds.remove(id);
                                          });
                                        }
                                      : null,
                                );
                              } catch (_) {
                                return const SizedBox.shrink();
                              }
                            }),
                          ],
                        ),
                      ],
                    )
                  else if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Character'),
                            onPressed: () {
                              _showQuickAddCharacterDialog(context, currentGame);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add Location'),
                            onPressed: () {
                              _showQuickAddLocationDialog(context, currentGame);
                            },
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Move or Oracle roll
                  if (_moveRoll != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Move: ${_moveRoll!.moveName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      _moveRoll = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (_moveRoll!.moveDescription != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Text(_moveRoll!.moveDescription!),
                            ),
                          Text(
                            'Result: ${_moveRoll!.outcome}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getOutcomeColor(context, _moveRoll!.outcome),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Roll: ${_moveRoll!.actionDie}${_moveRoll!.statValue != null ? ' + ${_moveRoll!.statValue} (${_moveRoll!.stat})' : ''} vs ${_moveRoll!.challengeDice.join(', ')}',
                          ),
                        ],
                      ),
                    ),
                  
                  if (_oracleRoll != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Oracle: ${_oracleRoll!.oracleName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      _oracleRoll = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                          if (_oracleRoll!.oracleTable != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Text('Table: ${_oracleRoll!.oracleTable}'),
                            ),
                          Text('Result: ${_oracleRoll!.result}'),
                          const SizedBox(height: 4),
                          Text(
                            'Roll: ${_oracleRoll!.dice.join(', ')}',
                          ),
                        ],
                      ),
                    ),
                  
                  // Roll buttons
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.sports_martial_arts),
                          label: const Text('Roll Move'),
                          onPressed: () {
                            _showRollMoveDialog(context);
                          },
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.casino),
                          label: const Text('Roll Oracle'),
                          onPressed: () {
                            _showRollOracleDialog(context);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Show character details dialog
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
                      _buildStatChip(stat.name, stat.value)
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Assets
                if (character.assets.isNotEmpty) ...[
                  const Text(
                    'Assets:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...character.assets.map((asset) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (asset.description != null)
                            Text(asset.description!),
                        ],
                      ),
                    )
                  ),
                  const SizedBox(height: 8),
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
  
  // Build a stat chip
  Widget _buildStatChip(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey[200],
    );
  }

  // Show quick add character dialog
  void _showQuickAddCharacterDialog(BuildContext context, dynamic currentGame) {
    final TextEditingController nameController = TextEditingController();
    
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
                  final character = await gameProvider.createCharacter(nameController.text);
                  
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
  
  // Show roll move dialog
  void _showRollMoveDialog(BuildContext context) {
    if (!mounted) return;
    
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final moves = dataswornProvider.moves;
    
    // Group moves by category
    final categories = <String>{};
    final movesByCategory = <String, List<Move>>{};
    
    for (final move in moves) {
      final category = move.category ?? 'Uncategorized';
      categories.add(category);
      
      if (!movesByCategory.containsKey(category)) {
        movesByCategory[category] = [];
      }
      
      movesByCategory[category]!.add(move);
    }
    
    final sortedCategories = categories.toList()..sort();
    
    // First, show a dialog to select the category
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Move Category'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: sortedCategories.length,
              itemBuilder: (context, index) {
                final category = sortedCategories[index];
                return ListTile(
                  title: Text(category),
                  onTap: () {
                    Navigator.pop(context);
                    // Show the moves for this category
                    _showMovesDialog(context, category, movesByCategory[category]!);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show search dialog instead
                _showMoveSearchDialog(context, moves);
              },
              child: const Text('Search All Moves'),
            ),
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
  
  // Show moves dialog
  void _showMovesDialog(BuildContext context, String category, List<Move> moves) {
    // Sort moves by name
    moves.sort((a, b) => a.name.compareTo(b.name));
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$category Moves'),
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
                    if (move.isProgressMove) {
                      // Roll progress move directly
                      _rollProgressMove(context, move);
                    } else {
                      // Show stat selection for action move
                      _showStatSelectionDialog(context, move);
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRollMoveDialog(context); // Go back to categories
              },
              child: const Text('Back'),
            ),
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
  
  // Show move search dialog
  void _showMoveSearchDialog(BuildContext context, List<Move> allMoves) {
    final TextEditingController searchController = TextEditingController();
    List<Move> filteredMoves = [];
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter moves based on search text
            if (searchController.text.isNotEmpty) {
              final searchText = searchController.text.toLowerCase();
              filteredMoves = allMoves
                  .where((move) => 
                    move.name.toLowerCase().contains(searchText) ||
                    (move.description?.toLowerCase().contains(searchText) ?? false)
                  )
                  .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
            } else {
              filteredMoves = [];
            }
            
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Search Moves',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filteredMoves.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: filteredMoves.length,
                          itemBuilder: (context, index) {
                            final move = filteredMoves[index];
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
                                if (move.isProgressMove) {
                                  // Roll progress move directly
                                  _rollProgressMove(context, move);
                                } else {
                                  // Show stat selection for action move
                                  _showStatSelectionDialog(context, move);
                                }
                              },
                            );
                          },
                        ),
                      )
                    else if (searchController.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No moves found'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Type to search for moves'),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRollMoveDialog(context); // Go back to categories
                          },
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Show stat selection dialog
  void _showStatSelectionDialog(BuildContext context, Move move) {
    String? selectedStat;
    int statValue = 0;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Stat for ${move.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (move.description != null) ...[
                      Text(move.description!),
                      const SizedBox(height: 16),
                    ],
                    
                    const Text(
                      'Select Stat:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Edge'),
                          selected: selectedStat == 'Edge',
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedStat = selected ? 'Edge' : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Heart'),
                          selected: selectedStat == 'Heart',
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedStat = selected ? 'Heart' : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Iron'),
                          selected: selectedStat == 'Iron',
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedStat = selected ? 'Iron' : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Shadow'),
                          selected: selectedStat == 'Shadow',
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedStat = selected ? 'Shadow' : null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Wits'),
                          selected: selectedStat == 'Wits',
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedStat = selected ? 'Wits' : null;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (selectedStat != null) ...[
                      Text('$selectedStat Value:'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('0'),
                          Expanded(
                            child: Slider(
                              value: statValue.toDouble(),
                              min: 0,
                              max: 5,
                              divisions: 5,
                              label: statValue.toString(),
                              onChanged: (value) {
                                setDialogState(() {
                                  statValue = value.toInt();
                                });
                              },
                            ),
                          ),
                          Text('5'),
                        ],
                      ),
                      Center(
                        child: Text(
                          'Value: $statValue',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedStat == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          _rollActionMove(context, move, selectedStat!, statValue);
                        },
                  child: const Text('Roll'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Roll a progress move
  void _rollProgressMove(BuildContext context, Move move) {
    // For progress moves, we'll use a default progress value of 3
    final rollResult = DiceRoller.rollProgressMove(progressValue: 3);
    
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
    
    // Update the journal entry
    setState(() {
      _moveRoll = moveRoll;
    });
    
    // Insert the move name into the journal text
    final text = _contentController.text;
    final newText = '$text[${move.name}] ';
    _contentController.text = newText;
    
    // Show the roll details
    _showMoveRollDetailsDialog(context, moveRoll);
  }
  
  // Roll an action move
  void _rollActionMove(BuildContext context, Move move, String stat, int statValue) {
    // Roll the move
    final rollResult = DiceRoller.rollMove(
      statValue: statValue,
    );
    
    // Create a MoveRoll
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      stat: stat,
      statValue: statValue,
      actionDie: rollResult['actionDie'] ?? 0,
      challengeDice: rollResult['challengeDice'] ?? [0, 0],
      outcome: rollResult['outcome'] ?? 'miss',
    );
    
    // Update the journal entry
    setState(() {
      _moveRoll = moveRoll;
    });
    
    // Insert the move name into the journal text
    final text = _contentController.text;
    final newText = '$text[${move.name}] ';
    _contentController.text = newText;
    
    // Show the roll details
    _showMoveRollDetailsDialog(context, moveRoll);
  }
  
  // Show roll oracle dialog
  void _showRollOracleDialog(BuildContext context) {
    if (!mounted) return;
    
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final oracleCategories = dataswornProvider.oracles;
    
    // First, show a dialog to select the category
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Oracle Category'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: oracleCategories.length,
              itemBuilder: (context, index) {
                final category = oracleCategories[index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.pop(context);
                    // Show the tables for this category
                    _showOracleTablesDialog(context, category);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show search dialog instead
                _showOracleSearchDialog(context, oracleCategories);
              },
              child: const Text('Search All Oracles'),
            ),
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
  
  // Show oracle tables dialog
  void _showOracleTablesDialog(BuildContext context, OracleCategory category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${category.name} Oracles'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: category.tables.length,
              itemBuilder: (context, index) {
                final table = category.tables[index];
                return ListTile(
                  title: Text(table.name),
                  subtitle: table.description != null
                      ? Text(
                          table.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _rollOnOracleTable(context, table, category.name);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRollOracleDialog(context); // Go back to categories
              },
              child: const Text('Back'),
            ),
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
  
  // Show oracle search dialog
  void _showOracleSearchDialog(BuildContext context, List<OracleCategory> categories) {
    final TextEditingController searchController = TextEditingController();
    List<OracleTable> filteredTables = [];
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter tables based on search text
            if (searchController.text.isNotEmpty) {
              final searchText = searchController.text.toLowerCase();
              filteredTables = [];
              
              for (final category in categories) {
                if (category.tables.isNotEmpty) {
                  filteredTables.addAll(
                    category.tables.where((table) => 
                      table.name.toLowerCase().contains(searchText) ||
                      (table.description?.toLowerCase().contains(searchText) ?? false)
                    )
                  );
                }
              }
              
              filteredTables.sort((a, b) => a.name.compareTo(b.name));
            } else {
              filteredTables = [];
            }
            
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Search Oracles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    if (filteredTables.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: filteredTables.length,
                          itemBuilder: (context, index) {
                            final table = filteredTables[index];
                            // Find the category for this table
                            String? categoryName;
                            for (final category in categories) {
                              if (category.tables.contains(table)) {
                                categoryName = category.name;
                                break;
                              }
                            }
                            
                            return ListTile(
                              title: Text(table.name),
                              subtitle: Text(categoryName ?? ''),
                              onTap: () {
                                Navigator.pop(context);
                                _rollOnOracleTable(context, table, categoryName);
                              },
                            );
                          },
                        ),
                      )
                    else if (searchController.text.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No oracles found'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Type to search for oracles'),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRollOracleDialog(context); // Go back to categories
                          },
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Roll on an oracle table
  void _rollOnOracleTable(BuildContext context, OracleTable table, String? categoryName) {
    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    
    // Find the matching table entry
    OracleTableRow? matchingRow;
    for (final row in table.rows) {
      if (row.matchesRoll(total)) {
        matchingRow = row;
        break;
      }
    }
    
    if (matchingRow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No result found for roll: $total'),
        ),
      );
      return;
    }
    
    // Create an OracleRoll
    final oracleRoll = OracleRoll(
      oracleName: table.name,
      oracleTable: categoryName,
      dice: rollResult['dice'] as List<int>,
      result: matchingRow.result,
    );
    
    // Update the journal entry
    setState(() {
      _oracleRoll = oracleRoll;
    });
    
    // Insert the oracle result into the journal text
    final text = _contentController.text;
    final newText = '$text[${matchingRow.result}] ';
    _contentController.text = newText;
    
    // Show the roll details
    _showOracleRollDetailsDialog(context, oracleRoll);
  }
  
  // Show move roll details dialog
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
                    color: _getOutcomeColor(context, moveRoll.outcome),
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
  
  // Show oracle roll details dialog
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

  // Show quick add location dialog
  void _showQuickAddLocationDialog(BuildContext context, dynamic currentGame) {
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

  // Navigate to a character or location
  void _navigateToEntity(BuildContext context, dynamic entity, String type) {
    if (type == 'character') {
      _showCharacterDetailsDialog(context, entity);
    } else if (type == 'location') {
      _showLocationDetailsDialog(context, entity);
    }
  }

  // Get the color for a move outcome
  Color _getOutcomeColor(BuildContext context, String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Colors.green;
      case 'weak hit':
        return Colors.orange;
      case 'miss':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Widget _buildRichText(BuildContext context, dynamic currentGame) {
    final text = _contentController.text;
    final List<InlineSpan> spans = [];
    
    // Regular expressions to match @character, #location mentions, and [move/oracle] references
    final characterRegex = RegExp(r'@([a-zA-Z0-9_\s]+?)(?=\s|$)');
    final locationRegex = RegExp(r'#([a-zA-Z0-9_\s]+?)(?=\s|$)');
    final moveOracleRegex = RegExp(r'\[(.*?)\]');
    
    // Current position in the text
    int currentPosition = 0;
    
    // Find all character mentions, location mentions, and move/oracle references
    final characterMatches = characterRegex.allMatches(text);
    final locationMatches = locationRegex.allMatches(text);
    final moveOracleMatches = moveOracleRegex.allMatches(text);
    
    // Combine all matches and sort by position
    final allMatches = [
      ...characterMatches.map((m) => {'type': 'character', 'match': m}),
      ...locationMatches.map((m) => {'type': 'location', 'match': m}),
      ...moveOracleMatches.map((m) => {'type': 'moveOracle', 'match': m}),
    ]..sort((a, b) => (a['match'] as RegExpMatch).start.compareTo((b['match'] as RegExpMatch).start));
    
    // Process each match in order
    for (final matchData in allMatches) {
      final match = matchData['match'] as RegExpMatch;
      final type = matchData['type'] as String;
      
      // Add text before the match
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
          style: const TextStyle(fontSize: 16),
        ));
      }
      
      if (type == 'character' || type == 'location') {
        // Extract the name without the @ or # prefix
        final name = match.group(1)!.trim();
        
        // Find the entity by name
        dynamic entity;
        if (type == 'character') {
          try {
            entity = currentGame.characters.firstWhere(
              (c) => c.name == name,
            );
          } catch (e) {
            entity = null;
          }
        } else {
          try {
            entity = currentGame.locations.firstWhere(
              (l) => l.name == name,
            );
          } catch (e) {
            entity = null;
          }
        }
        
        // Add the mention as a clickable span if the entity exists
        if (entity != null) {
          spans.add(
            TextSpan(
              text: match.group(0),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _navigateToEntity(context, entity, type);
                },
            ),
          );
        } else {
          // If entity doesn't exist, just add as plain text
          spans.add(TextSpan(
            text: match.group(0),
            style: const TextStyle(fontSize: 16),
          ));
        }
      } else if (type == 'moveOracle') {
        // This is a move or oracle reference
        final content = match.group(1)!;
        
        // Check if it matches a move or oracle roll
        
        // Check if it's a move or oracle by looking at the current rolls
        // Use more flexible comparison by trimming and ignoring case
        bool isMove = _moveRoll != null && 
                      content.trim().toLowerCase() == _moveRoll!.moveName.trim().toLowerCase();
        bool isOracle = _oracleRoll != null && 
                        content.trim().toLowerCase() == _oracleRoll!.result.trim().toLowerCase();
        
        // Always make bracketed text clickable
        spans.add(
          TextSpan(
            text: match.group(0),
            style: TextStyle(
              color: isMove 
                  ? Theme.of(context).colorScheme.primary
                  : isOracle
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.tertiary, // Different color for unrecognized brackets
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline, // Add underline to make it look like a link
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (isMove && _moveRoll != null) {
                  _showMoveRollDetailsDialog(context, _moveRoll!);
                } else if (isOracle && _oracleRoll != null) {
                  _showOracleRollDetailsDialog(context, _oracleRoll!);
                } else {
                  // Show a message for unrecognized bracketed text
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No details available for "$content"'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
          ),
        );
      }
      
      // Update current position
      currentPosition = match.end;
    }
    
    // Add any remaining text after the last match
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
        style: const TextStyle(fontSize: 16),
      ));
    }
    
    // Return the rich text
    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
