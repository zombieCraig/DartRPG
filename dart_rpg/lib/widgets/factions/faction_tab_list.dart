import 'package:flutter/material.dart';
import '../../models/clock.dart';
import '../../models/faction.dart';
import '../../providers/datasworn_provider.dart';
import '../common/empty_state_widget.dart';
import 'faction_card.dart';
import 'faction_oracle_helper.dart';
import 'faction_service.dart';

/// A list view of faction cards for the Factions tab
class FactionTabList extends StatelessWidget {
  final List<Faction> factions;
  final List<Clock> clocks;
  final FactionService factionService;
  final DataswornProvider dataswornProvider;

  const FactionTabList({
    super.key,
    required this.factions,
    required this.clocks,
    required this.factionService,
    required this.dataswornProvider,
  });

  Future<void> _rollRelationships(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Roll Relationships'),
        content: const Text(
          'This will roll new relationships between all factions, '
          'overwriting any existing relationships. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Roll'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final allRelationships = FactionOracleHelper.rollAllRelationships(
      factions, dataswornProvider,
    );

    for (final entry in allRelationships.entries) {
      await factionService.setFactionRelationships(entry.key, entry.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (factions.isEmpty) {
      return const EmptyStateWidget(
        message: 'No factions yet',
        icon: Icons.groups,
      );
    }

    return Column(
      children: [
        if (factions.length >= 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _rollRelationships(context),
                icon: const Icon(Icons.casino, size: 18),
                label: const Text('Roll Relationships'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: factions.length,
            itemBuilder: (context, index) {
              return FactionCard(
                faction: factions[index],
                clocks: clocks,
                allFactions: factions,
                factionService: factionService,
              );
            },
          ),
        ),
      ],
    );
  }
}
