import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../widgets/character/character_list_view.dart';
import '../widgets/character/character_dialog.dart';
import '../widgets/common/empty_state_widget.dart';

/// A screen for managing characters.
class CharacterScreen extends StatefulWidget {
  final String gameId;

  const CharacterScreen({super.key, required this.gameId});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    // Update Base Rig assets for existing characters
    gameProvider.updateBaseRigAssets(dataswornProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameProvider, ({int characterCount, String? mainCharId})>(
      selector: (_, gp) => (
        characterCount: gp.currentGame?.characters.length ?? 0,
        mainCharId: gp.currentGame?.mainCharacter?.id,
      ),
      builder: (context, data, _) {
        final gameProvider = context.read<GameProvider>();
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
                  ? EmptyStateWidget(
                      message: 'No characters yet',
                      actionLabel: 'Create Character',
                      onAction: () {
                        CharacterDialog.showCreateDialog(context, gameProvider).then((_) {
                          _refreshScreen();
                        });
                      },
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
