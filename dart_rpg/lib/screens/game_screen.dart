import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import 'journal_screen.dart';
import 'character_screen.dart';
import 'location_screen.dart';
import 'moves_screen.dart';
import 'oracles_screen.dart';
import 'assets_screen.dart';
import 'settings_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;

  const GameScreen({super.key, required this.gameId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final game = gameProvider.games.firstWhere(
          (g) => g.id == widget.gameId,
          orElse: () => throw Exception('Game not found'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(game.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'Export Game',
                onPressed: () => _exportGame(context, gameProvider, game),
              ),
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
          body: _buildBody(context, game, gameProvider),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Journal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Characters',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.place),
                label: 'Locations',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_martial_arts),
                label: 'Moves',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.casino),
                label: 'Oracles',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_membership),
                label: 'Assets',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Game game, GameProvider gameProvider) {
    switch (_selectedIndex) {
      case 0:
        return JournalScreen(gameId: game.id);
      case 1:
        return CharacterScreen(gameId: game.id);
      case 2:
        return LocationScreen(gameId: game.id);
      case 3:
        return MovesScreen();
      case 4:
        return OraclesScreen();
      case 5:
        return AssetsScreen();
      default:
        return const Center(child: Text('Unknown screen'));
    }
  }

  Future<void> _exportGame(
    BuildContext context,
    GameProvider gameProvider,
    Game game,
  ) async {
    try {
      final filePath = await gameProvider.exportGame(game.id);
      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Game exported to: $filePath'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export game: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
