import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/character.dart';
import '../../../providers/game_provider.dart';
import '../../../providers/datasworn_provider.dart';
import '../character_form.dart';
import '../services/character_dialog_service.dart';
import '../stat_panel.dart';
import 'initial_assets_dialog.dart';

/// A dialog for creating a new character.
class CharacterCreateDialog extends StatefulWidget {
  final GameProvider gameProvider;
  
  const CharacterCreateDialog({
    super.key,
    required this.gameProvider,
  });
  
  /// Shows a dialog for creating a new character.
  static Future<void> show(BuildContext context, GameProvider gameProvider) async {
    await showDialog(
      context: context,
      builder: (context) => CharacterCreateDialog(gameProvider: gameProvider),
    );
  }

  @override
  State<CharacterCreateDialog> createState() => _CharacterCreateDialogState();
}

class _CharacterCreateDialogState extends State<CharacterCreateDialog> {
  final nameController = TextEditingController();
  final handleController = TextEditingController();
  final bioController = TextEditingController();
  final imageUrlController = TextEditingController();
  
  // Controllers for NPC character details
  final firstLookController = TextEditingController();
  final dispositionController = TextEditingController();
  final trademarkAvatarController = TextEditingController();
  final roleController = TextEditingController();
  final detailsController = TextEditingController();
  final goalsController = TextEditingController();
  
  // Default to player character only if no main character exists yet
  late bool isPlayerCharacter;
  
  // Default stats for player characters - typical distribution is one stat at 3, two at 2, and two at 1
  final stats = [
    CharacterStat(name: 'Edge', value: 1),
    CharacterStat(name: 'Heart', value: 2),
    CharacterStat(name: 'Iron', value: 3),
    CharacterStat(name: 'Shadow', value: 2),
    CharacterStat(name: 'Wits', value: 1),
  ];
  
  @override
  void initState() {
    super.initState();
    isPlayerCharacter = widget.gameProvider.currentGame?.mainCharacter == null;
  }
  
  @override
  void dispose() {
    nameController.dispose();
    handleController.dispose();
    bioController.dispose();
    imageUrlController.dispose();
    firstLookController.dispose();
    dispositionController.dispose();
    trademarkAvatarController.dispose();
    roleController.dispose();
    detailsController.dispose();
    goalsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Character'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character form for basic information
            CharacterForm(
              nameController: nameController,
              handleController: handleController,
              bioController: bioController,
              imageUrlController: imageUrlController,
              isPlayerCharacterSwitchVisible: true,
              isPlayerCharacter: isPlayerCharacter,
              onPlayerCharacterChanged: (value) {
                setState(() {
                  isPlayerCharacter = value;
                });
              },
              // Pass controllers for NPC character details
              firstLookController: firstLookController,
              dispositionController: dispositionController,
              trademarkAvatarController: trademarkAvatarController,
              roleController: roleController,
              detailsController: detailsController,
              goalsController: goalsController,
            ),
            
            if (isPlayerCharacter) ...[
              const SizedBox(height: 16),
              // Stat panel for character stats
              StatPanel(
                stats: stats,
                isEditable: true,
                onStatChanged: (index, value) {
                  setState(() {
                    stats[index].value = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a name'),
                ),
              );
              return;
            }
            
            // Create character using the service
            final character = await CharacterDialogService.createCharacter(
              gameProvider: widget.gameProvider,
              dataswornProvider: Provider.of<DataswornProvider>(context, listen: false),
              name: nameController.text,
              isPlayerCharacter: isPlayerCharacter,
              handle: handleController.text.isEmpty ? null : handleController.text,
              bio: bioController.text.isEmpty ? null : bioController.text,
              imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
              stats: isPlayerCharacter ? stats : null,
              // NPC character details
              firstLook: !isPlayerCharacter && firstLookController.text.isNotEmpty ? firstLookController.text : null,
              disposition: !isPlayerCharacter && dispositionController.text.isNotEmpty ? dispositionController.text : null,
              trademarkAvatar: !isPlayerCharacter && trademarkAvatarController.text.isNotEmpty ? trademarkAvatarController.text : null,
              role: !isPlayerCharacter && roleController.text.isNotEmpty ? roleController.text : null,
              details: !isPlayerCharacter && detailsController.text.isNotEmpty ? detailsController.text : null,
              goals: !isPlayerCharacter && goalsController.text.isNotEmpty ? goalsController.text : null,
            );
            
            if (mounted) {
              // Close the character creation dialog
              Navigator.pop(context);
              
              // Show the initial assets dialog for player characters
              if (isPlayerCharacter && character != null) {
                await InitialAssetsDialog.show(context, character, widget.gameProvider);
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
