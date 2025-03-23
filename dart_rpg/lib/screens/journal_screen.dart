import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/journal_entry.dart';
import '../models/session.dart';
import '../models/character.dart';
import '../models/location.dart';
import 'journal_entry_screen.dart';

class JournalScreen extends StatelessWidget {
  final String gameId;

  const JournalScreen({super.key, required this.gameId});

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
                        // Add new entry button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('New Journal Entry'),
                            onPressed: () {
                              _navigateToNewEntry(context, gameProvider);
                            },
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
                              : ListView.builder(
                                  itemCount: currentSession.entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = currentSession.entries[index];
                                    return _buildJournalEntryCard(context, entry, gameProvider);
                                  },
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
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entry content with scroll bar
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    entry.content,
                    style: const TextStyle(fontSize: 16),
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
                          label: Text(character.name),
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
        builder: (context) => const JournalEntryScreen(),
      ),
    );
  }
}
