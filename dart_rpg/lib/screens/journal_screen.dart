import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/game_provider.dart';
import '../models/journal_entry.dart';
import '../models/session.dart';
import '../models/character.dart';
import '../models/location.dart';
import '../services/tutorial_service.dart';
import 'journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  final String gameId;

  const JournalScreen({super.key, required this.gameId});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Schedule tutorial check after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorials();
    });
  }
  
  void _checkTutorials() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    final currentSession = gameProvider.currentSession;
    
    if (currentGame == null) return;
    
    // Tutorial for creating a session
    if (currentGame.sessions.isEmpty) {
      await TutorialService.showTutorialIfNeeded(
        context: context,
        tutorialId: 'journal_create_session',
        title: 'Create Your First Session',
        message: 'You should create an initial session to start journaling. '
            'Click the + button next to the session dropdown to get started.',
        condition: true,
      );
    }
    
    // Tutorial for understanding sessions after creating first one
    if (currentGame.sessions.length == 1 && currentSession != null && 
        currentSession.entries.isEmpty) {
      await TutorialService.showTutorialIfNeeded(
        context: context,
        tutorialId: 'journal_session_explanation',
        title: 'About Sessions',
        message: 'Each Session is a collection of journal entries. '
            'Group them how you like but often it is best to keep each entry short, '
            'perhaps a paragraph or two.',
        condition: true,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      setState(() {
        _showScrollButton = _scrollController.position.maxScrollExtent > 0;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final currentGame = gameProvider.currentGame;
        final currentSession = gameProvider.currentSession;

        if (currentGame == null) {
          return const Center(
            child: Text('No game selected'),
          );
        }

        // Check if we have entries to determine if we should show the scroll button
        if (currentSession != null && currentSession.entries.isNotEmpty) {
          // Schedule a check after the layout is complete to see if we have a scrollbar
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollListener();
          });
        }

        return Column(
          children: [
            // Session selector
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Session'),
                      value: currentSession?.id,
                      onChanged: (String? sessionId) {
                        if (sessionId != null) {
                          gameProvider.switchSession(sessionId);
                        }
                      },
                      items: currentGame.sessions.map((Session session) {
                        return DropdownMenuItem<String>(
                          value: session.id,
                          child: Text(session.title),
                        );
                      }).toList(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'New Session',
                    onPressed: () {
                      _showNewSessionDialog(context, gameProvider);
                    },
                  ),
                ],
              ),
            ),

            // Journal entries
            Expanded(
              child: currentSession == null
                  ? const Center(
                      child: Text('No session selected. Create a new session to start journaling.'),
                    )
                  : Column(
                      children: [
                        // Add new entry and export buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('New Journal Entry'),
                                onPressed: () {
                                  _navigateToNewEntry(context, gameProvider);
                                },
                              ),
                              const SizedBox(width: 8.0),
                              IconButton(
                                icon: const Icon(Icons.ios_share),
                                tooltip: 'Export Session',
                                onPressed: () {
                                  _showExportDialog(context, gameProvider);
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Journal entries list
                        Expanded(
                          child: currentSession.entries.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'No journal entries yet',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Click the "New Journal Entry" button above to create your first entry',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Stack(
                                  children: [
                                    ListView.builder(
                                      controller: _scrollController,
                                      itemCount: currentSession.entries.length,
                                      itemBuilder: (context, index) {
                                        final entry = currentSession.entries[index];
                                        return _buildJournalEntryCard(context, entry, gameProvider);
                                      },
                                    ),
                                    if (_showScrollButton)
                                      Positioned(
                                        right: 16,
                                        bottom: 16,
                                        child: FloatingActionButton(
                                          mini: true,
                                          tooltip: 'Jump to last entry',
                                          onPressed: _scrollToBottom,
                                          child: const Icon(Icons.arrow_downward),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJournalEntryCard(
    BuildContext context,
    JournalEntry entry,
    GameProvider gameProvider,
  ) {
    final currentGame = gameProvider.currentGame;
    if (currentGame == null) return const SizedBox.shrink();

    // Get linked characters and locations
    final linkedCharacters = <Character>[];
    for (final id in entry.linkedCharacterIds) {
      try {
        final character = currentGame.characters.firstWhere((c) => c.id == id);
        linkedCharacters.add(character);
      } catch (_) {
        // Character not found, skip
      }
    }

    final linkedLocations = <Location>[];
    for (final id in entry.linkedLocationIds) {
      try {
        final location = currentGame.locations.firstWhere((l) => l.id == id);
        linkedLocations.add(location);
      } catch (_) {
        // Location not found, skip
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          // Pass the entry ID to open the existing entry
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalEntryScreen(
                entryId: entry.id,
                // Use the metadata if available, otherwise default to 'journal'
                sourceScreen: entry.metadata?['sourceScreen'] ?? 'journal',
                // Hide the back button if this entry was created from a quest
                hideAppBarBackButton: entry.metadata?['sourceScreen'] == 'quests',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entry content with scroll bar and markdown rendering
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: MarkdownBody(
                    data: entry.content,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                      textAlign: WrapAlignment.start,
                    ),
                    softLineBreak: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Linked entities
              if (linkedCharacters.isNotEmpty || linkedLocations.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    ...linkedCharacters.map((character) => Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(character.handle ?? character.getHandle()),
                        )),
                    ...linkedLocations.map((location) => Chip(
                          avatar: const Icon(Icons.place, size: 16),
                          label: Text(location.name),
                        )),
                  ],
                ),
              
              // Move or Oracle roll
              if (entry.moveRoll != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move: ${entry.moveRoll!.moveName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Result: ${entry.moveRoll!.outcome} (${entry.moveRoll!.actionDie}+${entry.moveRoll!.statValue ?? 0} vs ${entry.moveRoll!.challengeDice.join(', ')})',
                      ),
                    ],
                  ),
                ),
              
              if (entry.oracleRoll != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Oracle: ${entry.oracleRoll!.oracleName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Result: ${entry.oracleRoll!.result}'),
                    ],
                  ),
                ),
              
              // Timestamp
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatDateTime(entry.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showNewSessionDialog(BuildContext context, GameProvider gameProvider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Session'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Session Title',
              hintText: 'Enter a title for this session',
            ),
            autofocus: true,
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
                if (textController.text.isNotEmpty) {
                  await gameProvider.createSession(textController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    
                    // Show tutorial about sessions after creating the first one
                    if (gameProvider.currentGame?.sessions.length == 1) {
                      await TutorialService.showTutorialIfNeeded(
                        context: context,
                        tutorialId: 'journal_session_explanation',
                        title: 'About Sessions',
                        message: 'Each Session is a collection of journal entries. '
                            'Group them how you like but often it is best to keep each entry short, '
                            'perhaps a paragraph or two.',
                        condition: true,
                      );
                    }
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((_) {
      textController.dispose();
    });
  }

  void _navigateToNewEntry(BuildContext context, GameProvider gameProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalEntryScreen(
          sourceScreen: 'journal',
        ),
      ),
    );
  }
  
  void _showExportDialog(BuildContext context, GameProvider gameProvider) {
    final currentSession = gameProvider.currentSession;
    if (currentSession == null || currentSession.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No entries to export'),
        ),
      );
      return;
    }

    String selectedFormat = 'Markdown';
    bool includeLinkedItems = false;
    bool exportToClipboard = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Session'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format dropdown
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Export Format',
                    ),
                    value: selectedFormat,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedFormat = newValue;
                        });
                      }
                    },
                    items: ['Markdown'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Include linked items checkbox
                  CheckboxListTile(
                    title: const Text('Include Embedded Linked Items'),
                    value: includeLinkedItems,
                    onChanged: (bool? value) {
                      setState(() {
                        includeLinkedItems = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  // Export to clipboard checkbox (only for Markdown)
                  if (selectedFormat == 'Markdown')
                    CheckboxListTile(
                      title: const Text('Export to Clipboard'),
                      value: exportToClipboard,
                      onChanged: (bool? value) {
                        setState(() {
                          exportToClipboard = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _exportSession(
                      context,
                      gameProvider,
                      format: selectedFormat,
                      includeLinkedItems: includeLinkedItems,
                      exportToClipboard: exportToClipboard,
                    );
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _exportSession(
    BuildContext context,
    GameProvider gameProvider, {
    required String format,
    required bool includeLinkedItems,
    required bool exportToClipboard,
  }) async {
    final currentSession = gameProvider.currentSession;
    if (currentSession == null || currentSession.entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No entries to export'),
        ),
      );
      return;
    }

    try {
      // Generate markdown content
      final markdown = _generateMarkdownContent(
        gameProvider,
        currentSession,
        includeLinkedItems: includeLinkedItems,
      );

      if (exportToClipboard) {
        // Export to clipboard
        await Clipboard.setData(ClipboardData(text: markdown));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session exported to clipboard'),
            ),
          );
        }
      } else {
        // Export to file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Markdown File',
          fileName: '${currentSession.title.replaceAll(' ', '_')}.md',
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsString(markdown);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Session exported to: $result'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export session: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateMarkdownContent(
    GameProvider gameProvider,
    Session session, {
    required bool includeLinkedItems,
  }) {
    final currentGame = gameProvider.currentGame!;
    final buffer = StringBuffer();
    
    // Add title
    buffer.writeln('# ${session.title}');
    buffer.writeln();
    
    // Add entries
    for (final entry in session.entries) {
      buffer.writeln(entry.content);
      buffer.writeln();
      
      // Add linked items if requested
      if (includeLinkedItems) {
        // Add linked characters
        if (entry.linkedCharacterIds.isNotEmpty) {
          buffer.writeln('**Characters:**');
          for (final characterId in entry.linkedCharacterIds) {
            try {
              final character = currentGame.characters.firstWhere(
                (c) => c.id == characterId,
              );
              buffer.writeln('- ${character.name}');
            } catch (_) {
              // Character not found, skip
            }
          }
          buffer.writeln();
        }
        
        // Add linked locations
        if (entry.linkedLocationIds.isNotEmpty) {
          buffer.writeln('**Locations:**');
          for (final locationId in entry.linkedLocationIds) {
            try {
              final location = currentGame.locations.firstWhere(
                (l) => l.id == locationId,
              );
              buffer.writeln('- ${location.name}');
            } catch (_) {
              // Location not found, skip
            }
          }
          buffer.writeln();
        }
        
        // Add move rolls
        if (entry.moveRolls.isNotEmpty) {
          buffer.writeln('**Moves:**');
          for (final moveRoll in entry.moveRolls) {
            buffer.writeln('- ${moveRoll.moveName}: ${moveRoll.outcome}');
          }
          buffer.writeln();
        }
        
        // Add oracle rolls
        if (entry.oracleRolls.isNotEmpty) {
          buffer.writeln('**Oracles:**');
          for (final oracleRoll in entry.oracleRolls) {
            buffer.writeln('- ${oracleRoll.oracleName}: ${oracleRoll.result}');
          }
          buffer.writeln();
        }
      }
      
      // Add separator between entries
      buffer.writeln('---');
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
