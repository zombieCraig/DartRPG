import 'package:flutter/material.dart';
import '../../models/clock.dart';
import '../../models/faction.dart';
import 'faction_form.dart';

/// Dialog utilities for factions
class FactionDialog {
  static Future<Map<String, dynamic>?> showCreateDialog({
    required BuildContext context,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Faction'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: FactionForm(
              onSubmit: (result) {
                Navigator.of(context).pop(result);
              },
            ),
          ),
        ),
      ),
    );
  }

  static Future<Map<String, dynamic>?> showEditDialog({
    required BuildContext context,
    required Faction faction,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Faction'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: SingleChildScrollView(
            child: FactionForm(
              initialFaction: faction,
              onSubmit: (result) {
                Navigator.of(context).pop(result);
              },
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool?> showDeleteConfirmation({
    required BuildContext context,
    required Faction faction,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Faction'),
        content: Text('Are you sure you want to delete "${faction.name}"? '
            'Associated clocks will be unlinked but not deleted.'),
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

  static Future<Map<String, dynamic>?> showAddClockDialog({
    required BuildContext context,
  }) async {
    final titleController = TextEditingController();
    int selectedSegments = 4;
    ClockType selectedType = ClockType.campaign;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Clock to Faction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Clock Title',
                    border: OutlineInputBorder(),
                    hintText: 'Enter clock title',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Segments',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedSegments,
                  items: [4, 6, 8, 10].map((s) {
                    return DropdownMenuItem<int>(
                      value: s,
                      child: Text('$s segments'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSegments = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ClockType>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedType,
                  items: ClockType.values.map((type) {
                    return DropdownMenuItem<ClockType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, color: type.color, size: 16),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Navigator.of(context).pop({
                    'title': titleController.text,
                    'segments': selectedSegments,
                    'type': selectedType,
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
