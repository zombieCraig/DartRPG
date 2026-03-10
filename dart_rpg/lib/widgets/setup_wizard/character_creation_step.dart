import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../character/dialogs/character_create_dialog.dart';

class CharacterCreationStep extends StatelessWidget {
  final Game game;
  final GameProvider gameProvider;

  const CharacterCreationStep({
    super.key,
    required this.game,
    required this.gameProvider,
  });

  @override
  Widget build(BuildContext context) {
    final mainCharacter = game.mainCharacter;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your player character. Define their name, handle, stats, and starting assets.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (mainCharacter != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mainCharacter.name.isNotEmpty
                                ? mainCharacter.name
                                : mainCharacter.getHandle(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (mainCharacter.handle != null &&
                              mainCharacter.handle!.isNotEmpty &&
                              mainCharacter.name.isNotEmpty)
                            Text(
                              '@${mainCharacter.handle}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (mainCharacter.stats.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                mainCharacter.stats
                                    .map((s) => '${s.name}: ${s.value}')
                                    .join(' | '),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => CharacterCreateDialog.show(context, gameProvider),
                icon: const Icon(Icons.person_add),
                label: const Text('Create Another Character'),
              ),
            ),
          ] else
            Center(
              child: ElevatedButton.icon(
                onPressed: () => CharacterCreateDialog.show(context, gameProvider),
                icon: const Icon(Icons.person_add),
                label: const Text('Create Character'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
