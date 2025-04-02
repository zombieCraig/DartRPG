import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'loading_screen.dart';
import 'new_game_screen.dart';
import 'settings_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Game'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, _) {
          if (gameProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gameProvider.error != null) {
            return Center(
              child: Text(
                'Error: ${gameProvider.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          if (gameProvider.games.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No Games Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create a new game to get started.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Game'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewGameScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import Game'),
                    onPressed: () async {
                      final game = await gameProvider.importGame();
                      if (game != null && context.mounted) {
                        // Check if there's a main character
                        final hasMainCharacter = gameProvider.currentGame?.mainCharacter != null;
                        
                        // If there's a main character, start with Journal tab (0)
                        // Otherwise, start with Characters tab (1)
                        final initialTabIndex = hasMainCharacter ? 0 : 1;
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoadingScreen(
                              gameId: game.id,
                              dataswornSource: game.dataswornSource,
                              hasMainCharacter: hasMainCharacter,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Games',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('New Game'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewGameScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: gameProvider.games.length,
                  itemBuilder: (context, index) {
                    final game = gameProvider.games[index];
                    final isCurrentGame = gameProvider.currentGame?.id == game.id;
                    
                    return Card(
                      elevation: isCurrentGame ? 4 : 1,
                      color: isCurrentGame ? Theme.of(context).colorScheme.primaryContainer : null,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          game.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Last played: ${_formatDate(game.lastPlayedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sessions: ${game.sessions.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Characters: ${game.characters.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteConfirmation(context, gameProvider, game.id, game.name);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () async {
                                await gameProvider.switchGame(game.id);
                                
                                // We'll load datasworn in the LoadingScreen
                                
                                if (context.mounted) {
                                  // Check if there's a main character
                                  final hasMainCharacter = gameProvider.currentGame?.mainCharacter != null;
                                  
                                  // If there's a main character, start with Journal tab (0)
                                  // Otherwise, start with Characters tab (1)
                                  final initialTabIndex = hasMainCharacter ? 0 : 1;
                                  
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoadingScreen(
                                        gameId: game.id,
                                        dataswornSource: game.dataswornSource,
                                        hasMainCharacter: hasMainCharacter,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () async {
                          await gameProvider.switchGame(game.id);
                          
                          // We'll load datasworn in the LoadingScreen
                          
                          if (context.mounted) {
                            // Check if there's a main character
                            final hasMainCharacter = gameProvider.currentGame?.mainCharacter != null;
                            
                            // If there's a main character, start with Journal tab (0)
                            // Otherwise, start with Characters tab (1)
                            final initialTabIndex = hasMainCharacter ? 0 : 1;
                            
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoadingScreen(
                                  gameId: game.id,
                                  dataswornSource: game.dataswornSource,
                                  hasMainCharacter: hasMainCharacter,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GameProvider gameProvider,
    String gameId,
    String gameName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text('Are you sure you want to delete "$gameName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                gameProvider.deleteGame(gameId);
                Navigator.pop(context);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}
