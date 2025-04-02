import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A panel for displaying NPC character details in view mode.
class CharacterNpcDetailsPanel extends StatefulWidget {
  final Character character;
  final bool initiallyExpanded;
  
  const CharacterNpcDetailsPanel({
    super.key,
    required this.character,
    this.initiallyExpanded = true,
  });

  @override
  State<CharacterNpcDetailsPanel> createState() => _CharacterNpcDetailsPanelState();
}

class _CharacterNpcDetailsPanelState extends State<CharacterNpcDetailsPanel> {
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
          title: const Text('Character Details', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
        ),
        if (_isExpanded) ...[
          if (widget.character.firstLook != null && widget.character.firstLook!.isNotEmpty) ...[
            const Text('First Look:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.firstLook!),
            const SizedBox(height: 8),
          ],
          if (widget.character.disposition != null && widget.character.disposition!.isNotEmpty) ...[
            const Text('Disposition:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.disposition!),
            const SizedBox(height: 8),
          ],
          if (widget.character.trademarkAvatar != null && widget.character.trademarkAvatar!.isNotEmpty) ...[
            const Text('Trademark Avatar:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.trademarkAvatar!),
            const SizedBox(height: 8),
          ],
          if (widget.character.role != null && widget.character.role!.isNotEmpty) ...[
            const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.role!),
            const SizedBox(height: 8),
          ],
          if (widget.character.details != null && widget.character.details!.isNotEmpty) ...[
            const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.details!),
            const SizedBox(height: 8),
          ],
          if (widget.character.goals != null && widget.character.goals!.isNotEmpty) ...[
            const Text('Goals:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.character.goals!),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}
