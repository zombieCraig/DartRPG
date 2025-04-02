import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A panel for displaying character details in view mode.
class CharacterDetailsPanel extends StatelessWidget {
  final Character character;
  
  const CharacterDetailsPanel({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (character.imageUrl != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(character.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        Text(
          character.bio == null || character.bio!.isEmpty ? 'No bio available' : character.bio!,
          style: TextStyle(
            fontStyle: character.bio == null || character.bio!.isEmpty ? FontStyle.italic : FontStyle.normal,
            color: character.bio == null || character.bio!.isEmpty ? Colors.grey : null,
          ),
        ),
      ],
    );
  }
}
