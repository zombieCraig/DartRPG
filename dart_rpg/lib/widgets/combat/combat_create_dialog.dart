import 'package:flutter/material.dart';
import '../../models/quest.dart';

/// Dialog for creating a new combat encounter.
class CombatCreateDialog extends StatefulWidget {
  final Function(String title, QuestRank rank) onCreate;

  const CombatCreateDialog({
    super.key,
    required this.onCreate,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(String title, QuestRank rank) onCreate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CombatCreateDialog(onCreate: onCreate),
    );
  }

  @override
  State<CombatCreateDialog> createState() => _CombatCreateDialogState();
}

class _CombatCreateDialogState extends State<CombatCreateDialog> {
  final _titleController = TextEditingController();
  QuestRank _selectedRank = QuestRank.dangerous;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sports_martial_arts, size: 20),
          SizedBox(width: 8),
          Text('New Combat'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Foe / Combat Title',
              hintText: 'e.g., ICE Guardian',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _create(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rank',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<QuestRank>(
            segments: QuestRank.values.map((rank) {
              return ButtonSegment<QuestRank>(
                value: rank,
                label: Text(
                  rank.displayName,
                  style: const TextStyle(fontSize: 11),
                ),
                icon: Icon(rank.icon, size: 16),
              );
            }).toList(),
            selected: {_selectedRank},
            onSelectionChanged: (Set<QuestRank> selection) {
              setState(() {
                _selectedRank = selection.first;
              });
            },
            showSelectedIcon: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _create,
          child: const Text('Start Combat'),
        ),
      ],
    );
  }

  void _create() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    widget.onCreate(title, _selectedRank);
    Navigator.pop(context);
  }
}
