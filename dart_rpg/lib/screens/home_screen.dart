import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import 'game_screen.dart';
import 'new_game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fe-Runners Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
                    'Welcome to the Fe-Runners Journal!',
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(gameId: game.id),
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: gameProvider.games.length + 1, // +1 for the "Add" card
                  itemBuilder: (context, index) {
                    if (index == gameProvider.games.length) {
                      // "Add" card
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewGameScreen(),
                              ),
                            );
                          },
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 48),
                                SizedBox(height: 8),
                                Text('New Game'),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    
                    final game = gameProvider.games[index];
                    final isCurrentGame = gameProvider.currentGame?.id == game.id;
                    
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: isCurrentGame ? 4 : 1,
                      color: isCurrentGame ? Theme.of(context).colorScheme.primaryContainer : null,
                      child: InkWell(
                        onTap: () async {
                          await gameProvider.switchGame(game.id);
                          
                          // Load datasworn source if available
                          if (game.dataswornSource != null && context.mounted) {
                            final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
                            await dataswornProvider.loadDatasworn(game.dataswornSource!);
                          }
                          
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameScreen(gameId: game.id),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Game info
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                            
                                            // Load datasworn source if available
                                            if (game.dataswornSource != null && context.mounted) {
                                              final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
                                              await dataswornProvider.loadDatasworn(game.dataswornSource!);
                                            }
                                            
                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => GameScreen(gameId: game.id),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
