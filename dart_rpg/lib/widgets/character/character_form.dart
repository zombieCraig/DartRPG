import 'package:flutter/material.dart';

/// A component for character data entry.
class CharacterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController handleController;
  final TextEditingController bioController;
  final TextEditingController imageUrlController;
  final bool isPlayerCharacterSwitchVisible;
  final bool isPlayerCharacter;
  final Function(bool)? onPlayerCharacterChanged;

  const CharacterForm({
    super.key,
    required this.nameController,
    required this.handleController,
    required this.bioController,
    required this.imageUrlController,
    required this.isPlayerCharacterSwitchVisible,
    required this.isPlayerCharacter,
    this.onPlayerCharacterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter character name',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: handleController,
          decoration: const InputDecoration(
            labelText: 'Short Name or Handle',
            hintText: 'Enter a short name without spaces or special characters',
            helperText: 'No spaces, @, #, or brackets. Will default to first name if blank.',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bioController,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Enter character bio',
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: imageUrlController,
          decoration: const InputDecoration(
            labelText: 'Image URL (optional)',
            hintText: 'Enter URL to character image',
          ),
        ),
        if (isPlayerCharacterSwitchVisible) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Player Character'),
            subtitle: const Text('Has stats and can use assets'),
            value: isPlayerCharacter,
            onChanged: onPlayerCharacterChanged,
          ),
        ],
      ],
    );
  }
}
