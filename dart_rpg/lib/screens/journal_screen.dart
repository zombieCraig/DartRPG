import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/game_provider.dart';
import '../models/character.dart';
import '../models/journal_entry.dart';
import '../models/location.dart';
import '../models/session.dart';
import '../services/tutorial_service.dart';
import 'journal_entry_screen.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/journal/begin_session_dialog.dart';
import '../widgets/journal/end_session_dialog.dart';

class JournalScreen extends StatefulWidget {
  final String gameId;
  final VoidCallback? onNavigateToQuests;

  const JournalScreen({super.key, required this.gameId, this.onNavigateToQuests});

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
      if (!mounted) return;
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

    // Post-wizard quest guidance
    if (currentGame.sessions.length == 1 &&
        currentSession != null &&
        currentSession.entries.length == 1 &&
        currentGame.quests.isEmpty) {
      if (!mounted) return;
      await TutorialService.showTutorialIfNeeded(
        context: context,
        tutorialId: 'post_wizard_quest_guidance',
        title: 'Create Your First Quests',
        message: 'Your story has begun! Consider creating quests to track your objectives.\n\n'
            'Start with a quest for the situation in your opening scene. '
            'Then create an Extreme or Epic rank quest for your character\'s '
            'overarching life objective \u2014 this long-term goal will drive your '
            'story forward across many sessions.',
        condition: true,
        actionLabel: 'Go to Quests',
        onAction: widget.onNavigateToQuests,
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
    return Selector<GameProvider, ({String? sessionId, int sessionCount, int entryCount})>(
      selector: (_, gp) => (
        sessionId: gp.currentSession?.id,
        sessionCount: gp.currentGame?.sessions.length ?? 0,
        entryCount: gp.currentSession?.entries.length ?? 0,
      ),
      builder: (context, data, _) {
        final gameProvider = context.read<GameProvider>();
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
                              if (currentGame.mainCharacter != null)
                                IconButton(
                                  icon: const Icon(Icons.flag_outlined),
                                  tooltip: 'End Session',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const EndSessionDialog(),
                                    );
                                  },
                                ),
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
                              ? const EmptyStateWidget(
                                  message: 'No journal entries yet',
                                )
                              : Stack(
                                  children: [
                                    Builder(builder: (context) {
                                      // Build O(1) lookup maps once for all cards
                                      final characterMap = {for (final c in currentGame.characters) c.id: c};
                                      final locationMap = {for (final l in currentGame.locations) l.id: l};
                                      return ListView.builder(
                                      controller: _scrollController,
                                      itemCount: currentSession.entries.length,
                                      itemBuilder: (context, index) {
                                        final entry = currentSession.entries[index];
                                        return _buildJournalEntryCard(context, entry, gameProvider, characterMap: characterMap, locationMap: locationMap);
                                      },
                                    );
                                    }),
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
    GameProvider gameProvider, {
    Map<String, Character>? characterMap,
    Map<String, Location>? locationMap,
  }) {
    final currentGame = gameProvider.currentGame;
    if (currentGame == null) return const SizedBox.shrink();

    // Get linked characters and locations using O(1) maps when available
    final linkedCharacters = entry.linkedCharacterIds
        .map((id) => characterMap != null ? characterMap[id] : currentGame.characters.firstWhereOrNull((c) => c.id == id))
        .nonNulls
        .toList();

    final linkedLocations = entry.linkedLocationIds
        .map((id) => locationMap != null ? locationMap[id] : currentGame.locations.firstWhereOrNull((l) => l.id == id))
        .nonNulls
        .toList();

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

  /// Find focus notes from the previous session's End Session entry, if any.
  String? _getPreviousSessionFocusNotes(GameProvider gameProvider) {
    final game = gameProvider.currentGame;
    if (game == null || game.sessions.isEmpty) return null;

    // The current session (before creating a new one) is the "previous" session
    final previousSession = gameProvider.currentSession ?? game.sessions.last;
    // Search entries in reverse for the most recent End Session entry with focusNotes
    for (int i = previousSession.entries.length - 1; i >= 0; i--) {
      final meta = previousSession.entries[i].metadata;
      if (meta != null && meta['focusNotes'] != null) {
        return meta['focusNotes'] as String;
      }
    }
    return null;
  }

  void _showNewSessionDialog(BuildContext outerContext, GameProvider gameProvider) {
    final textController = TextEditingController();
    final isFirstSession = gameProvider.currentGame?.sessions.isEmpty ?? true;
    final previousFocusNotes = _getPreviousSessionFocusNotes(gameProvider);

    showDialog(
      context: outerContext,
      builder: (dialogContext) {
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
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.isNotEmpty) {
                  await gameProvider.createSession(textController.text);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  if (!outerContext.mounted) return;

                  // Show tutorial about sessions after creating the first one
                  if (gameProvider.currentGame?.sessions.length == 1) {
                    await TutorialService.showTutorialIfNeeded(
                      context: outerContext,
                      tutorialId: 'journal_session_explanation',
                      title: 'About Sessions',
                      message: 'Each Session is a collection of journal entries. '
                          'Group them how you like but often it is best to keep each entry short, '
                          'perhaps a paragraph or two.',
                      condition: true,
                    );
                  }

                  // Offer Begin a Session move (skip for first session — nothing to recap)
                  if (!isFirstSession &&
                      outerContext.mounted &&
                      gameProvider.currentGame?.mainCharacter != null) {
                    final runMove = await showDialog<bool>(
                      context: outerContext,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Begin a Session'),
                        content: const Text('Would you like to run the Begin a Session move?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('No'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                    if (runMove == true && outerContext.mounted) {
                      await showDialog(
                        context: outerContext,
                        builder: (_) => BeginSessionDialog(
                          previousFocusNotes: previousFocusNotes,
                        ),
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
            final character = currentGame.characters.firstWhereOrNull(
              (c) => c.id == characterId,
            );
            if (character != null) {
              buffer.writeln('- ${character.name}');
            }
          }
          buffer.writeln();
        }

        // Add linked locations
        if (entry.linkedLocationIds.isNotEmpty) {
          buffer.writeln('**Locations:**');
          for (final locationId in entry.linkedLocationIds) {
            final location = currentGame.locations.firstWhereOrNull(
              (l) => l.id == locationId,
            );
            if (location != null) {
              buffer.writeln('- ${location.name}');
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
