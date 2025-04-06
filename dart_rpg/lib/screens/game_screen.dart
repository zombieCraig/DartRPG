import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game.dart';
import '../transitions/navigation_service.dart';
import 'journal_screen.dart';
import 'character_screen.dart';
import 'location_screen.dart';
import 'quests_screen.dart';
import 'moves_screen.dart';
import 'oracles_screen.dart';
import 'assets_screen.dart';
import 'settings_screen.dart';
import 'game_settings_screen.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final int initialTabIndex;

  const GameScreen({
    super.key, 
    required this.gameId, 
    this.initialTabIndex = 1, // Default to Character tab
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    
    // Only apply the main character logic if we're using the default tab index
    if (widget.initialTabIndex == 1) {
      // Delay to ensure the game provider is initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final game = gameProvider.games.firstWhere(
          (g) => g.id == widget.gameId,
          orElse: () => throw Exception('Game not found'),
        );
        
        // Check if there's a main character
        final hasMainCharacter = game.mainCharacter != null;
        
        // If there's a main character, go to Journal tab, otherwise stay on Character tab
        if (hasMainCharacter) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      });
    }
  }

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
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onSelected: (value) {
                  final navigationService = NavigationService();
                  if (value == 'app_settings') {
                    navigationService.navigateTo(
                      context,
                      const SettingsScreen(),
                    );
                  } else if (value == 'game_settings') {
                    navigationService.navigateTo(
                      context,
                      const GameSettingsScreen(),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'game_settings',
                    child: Row(
                      children: [
                        Icon(Icons.videogame_asset),
                        SizedBox(width: 8),
                        Text('Game Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'app_settings',
                    child: Row(
                      children: [
                        Icon(Icons.app_settings_alt),
                        SizedBox(width: 8),
                        Text('App Settings'),
                      ],
                    ),
                  ),
                ],
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
                icon: Icon(Icons.task_alt),
                label: 'Quests',
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
        return QuestsScreen(gameId: game.id);
      case 4:
        return MovesScreen();
      case 5:
        return OraclesScreen();
      case 6:
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
