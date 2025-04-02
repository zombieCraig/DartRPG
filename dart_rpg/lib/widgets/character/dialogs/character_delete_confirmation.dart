import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A dialog for confirming character deletion.
class CharacterDeleteConfirmation extends StatelessWidget {
  final Character character;
  
  const CharacterDeleteConfirmation({
    super.key,
    required this.character,
  });
  
  /// Shows a dialog for confirming character deletion.
  static Future<bool> show(BuildContext context, Character character) async {
    bool confirmed = false;
    
    await showDialog(
      context: context,
      builder: (context) => CharacterDeleteConfirmation(character: character),
    ).then((value) => confirmed = value ?? false);
    
    return confirmed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Character'),
      content: Text('Are you sure you want to delete ${character.name}?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
