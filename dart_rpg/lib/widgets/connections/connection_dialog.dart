import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/connection.dart';
import '../../utils/outcome_utils.dart';
import 'connection_form.dart';

/// Dialog utilities for connections
class ConnectionDialog {
  static Future<Map<String, dynamic>?> showCreateDialog({
    required BuildContext context,
    required List<Character> characters,
  }) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to create a connection'),
        ),
      );
      return null;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make a Connection'),
        content: SingleChildScrollView(
          child: ConnectionForm(
            characters: characters,
            onSubmit: (name, characterId, rank, role, notes) {
              Navigator.of(context).pop({
                'name': name,
                'characterId': characterId,
                'rank': rank,
                'role': role,
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
    required Connection connection,
    required List<Character> characters,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Connection'),
        content: SingleChildScrollView(
          child: ConnectionForm(
            initialConnection: connection,
            characters: characters,
            onSubmit: (name, characterId, rank, role, notes) {
              Navigator.of(context).pop({
                'name': name,
                'characterId': characterId,
                'rank': rank,
                'role': role,
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
    required Connection connection,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete "${connection.name}"?'),
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
    required Connection connection,
    required Map<String, dynamic> result,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forge a Bond: "${connection.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${connection.progress}/10'),
            const SizedBox(height: 8),
            Text('Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}'),
            const SizedBox(height: 8),
            Text(
              'Outcome: ${result['outcome']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getOutcomeColor(result['outcome']),
              ),
            ),
          ],
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

}
