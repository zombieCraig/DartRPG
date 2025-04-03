import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../providers/game_provider.dart';
import 'character_card.dart';
import 'character_dialog.dart';

/// A component for displaying a list of characters.
class CharacterListView extends StatelessWidget {
  final List<Character> characters;
  final Character? mainCharacter;
  final GameProvider gameProvider;
  final VoidCallback? onCharacterAdded;

  const CharacterListView({
    super.key,
    required this.characters,
    this.mainCharacter,
    required this.gameProvider,
    this.onCharacterAdded,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: characters.length + 1, // +1 for the "Add" card
      itemBuilder: (context, index) {
        if (index == characters.length) {
          // "Add" card
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                CharacterDialog.showCreateDialog(context, gameProvider).then((_) {
                  if (onCharacterAdded != null) {
                    onCharacterAdded!();
                  }
                });
              },
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 48),
                    SizedBox(height: 8),
                    Text('Add Character'),
                  ],
                ),
              ),
            ),
          );
        }
        
        final character = characters[index];
        final isMainCharacter = mainCharacter != null && mainCharacter?.id == character.id;
        
        return CharacterCard(
          character: character,
          isMainCharacter: isMainCharacter,
          onTap: () {
            CharacterDialog.showEditDialog(
              context, 
              gameProvider, 
              character,
              onCharacterDeleted: onCharacterAdded, // Use the same callback as for adding
            );
          },
        );
      },
    );
  }
}
