import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A panel for displaying and editing character notes.
class CharacterNotesPanel extends StatefulWidget {
  final Character character;
  final TextEditingController notesController;
  final bool isEditable;
  final bool initiallyExpanded;
  
  const CharacterNotesPanel({
    super.key,
    required this.character,
    required this.notesController,
    this.isEditable = false,
    this.initiallyExpanded = false,
  });

  @override
  State<CharacterNotesPanel> createState() => _CharacterNotesPanelState();
}

class _CharacterNotesPanelState extends State<CharacterNotesPanel> {
  late bool _isExpanded;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded) ...[
          TextField(
            controller: widget.notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              hintText: 'Add notes about this character here',
            ),
            maxLines: 5,
            readOnly: !widget.isEditable,
          ),
        ],
      ],
    );
  }
}
