import 'package:flutter/material.dart';
import '../../models/faction.dart';
import '../../models/game.dart';
import '../../providers/game_provider.dart';
import '../factions/faction_dialog.dart';

class FactionSetupStep extends StatelessWidget {
  final Game game;
  final GameProvider gameProvider;

  const FactionSetupStep({
    super.key,
    required this.game,
    required this.gameProvider,
  });

  @override
  Widget build(BuildContext context) {
    final factions = game.factions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Create the factions that shape your world. The rulebook recommends at least 2 corporate and 2 government factions.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (factions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Center(
              child: Text(
                'No factions created yet. Tap the button below to add one.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: factions.length,
            itemBuilder: (context, index) {
              final faction = factions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(faction.type.icon),
                  title: Text(faction.name),
                  subtitle: Text(faction.type.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirm = await FactionDialog.showDeleteConfirmation(
                        context: context,
                        faction: faction,
                      );
                      if (confirm == true) {
                        await gameProvider.deleteFaction(faction.id);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _addFaction(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Faction'),
          ),
        ),
      ],
    );
  }

  Future<void> _addFaction(BuildContext context) async {
    final result = await FactionDialog.showCreateDialog(context: context);
    if (result != null) {
      await gameProvider.createFaction(
        result['name'],
        type: result['type'] ?? FactionType.corporate,
        influence: result['influence'] ?? FactionInfluence.established,
        description: result['description'] ?? '',
        leadershipStyle: result['leadershipStyle'] ?? '',
        subtypes: result['subtypes'] != null
            ? List<String>.from(result['subtypes'])
            : null,
        projects: result['projects'] ?? '',
        quirks: result['quirks'] ?? '',
        rumors: result['rumors'] ?? '',
      );
    }
  }
}
