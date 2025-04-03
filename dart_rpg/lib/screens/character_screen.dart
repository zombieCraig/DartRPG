import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../widgets/character/character_list_view.dart';
import '../widgets/character/character_service.dart';
import '../widgets/character/character_dialog.dart';

/// A screen for managing characters.
class CharacterScreen extends StatefulWidget {
  final String gameId;

  const CharacterScreen({super.key, required this.gameId});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  late CharacterService _characterService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context);
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    _characterService = CharacterService(gameProvider);
    
    // Update Base Rig assets for existing characters
    gameProvider.updateBaseRigAssets(dataswornProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final currentGame = gameProvider.currentGame;
        
        if (currentGame == null) {
          return const Center(
            child: Text('No game selected'),
          );
        }
        
        return Column(
          children: [
            // Character list/grid
            Expanded(
              child: currentGame.characters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No characters yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Character'),
                            onPressed: () {
                              // Show character creation dialog
                              CharacterDialog.showCreateDialog(context, gameProvider).then((_) {
                                _refreshScreen();
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : CharacterListView(
                      characters: currentGame.characters,
                      mainCharacter: currentGame.mainCharacter,
                      gameProvider: gameProvider,
                      onCharacterAdded: _refreshScreen,
                    ),
            ),
          ],
        );
      },
    );
  }

  void _refreshScreen() {
    setState(() {});
  }
}
