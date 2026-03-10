import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/network_route.dart';
import '../../utils/outcome_utils.dart';
import 'route_form.dart';

/// Dialog utilities for routes
class RouteDialog {
  static Future<Map<String, dynamic>?> showCreateDialog({
    required BuildContext context,
    required List<Character> characters,
  }) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to map a route'),
        ),
      );
      return null;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map a Route'),
        content: SingleChildScrollView(
          child: RouteForm(
            characters: characters,
            onSubmit: (name, characterId, origin, destination, rank, notes) {
              Navigator.of(context).pop({
                'name': name,
                'characterId': characterId,
                'origin': origin,
                'destination': destination,
                'rank': rank,
                'notes': notes,
              });
            },
          ),
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>?> showEditDialog({
    required BuildContext context,
    required NetworkRoute route,
    required List<Character> characters,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Route'),
        content: SingleChildScrollView(
          child: RouteForm(
            initialRoute: route,
            characters: characters,
            onSubmit: (name, characterId, origin, destination, rank, notes) {
              Navigator.of(context).pop({
                'name': name,
                'characterId': characterId,
                'origin': origin,
                'destination': destination,
                'rank': rank,
                'notes': notes,
              });
            },
          ),
        ),
      ),
    );
  }

  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required NetworkRoute route,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${route.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void showProgressRollResult({
    required BuildContext context,
    required NetworkRoute route,
    required Map<String, dynamic> result,
  }) {
    final outcome = result['outcome'] as String;
    final outcomeDescription = _getOutcomeDescription(outcome);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Infiltrate Segment: "${route.name}"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Route: ${route.routeLabel}'),
              const SizedBox(height: 4),
              Text('Progress: ${route.progress}/10'),
              const SizedBox(height: 8),
              Text('Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}'),
              const SizedBox(height: 8),
              Text(
                'Outcome: $outcome',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: getOutcomeColor(outcome),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getOutcomeColor(outcome).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: getOutcomeColor(outcome).withAlpha(77),
                  ),
                ),
                child: Text(
                  outcomeDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _getOutcomeDescription(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return 'You successfully enter the segment.';
      case 'weak hit':
        return 'You succeed but you face an unforeseen consequence. Envision what you encounter.';
      case 'miss':
        return 'You can\'t enter the segment. Envision what happens and either:\n'
            '\u2022 You forcibly Disconnect.\n'
            '\u2022 You Pay the Price.\n'
            '\u2022 Experience a setback and lose progress. Roll both challenge dice and take the lowest value, '
            'clear that number of progress. Then increase the difficulty ranking by one.';
      default:
        return outcome;
    }
  }
}
