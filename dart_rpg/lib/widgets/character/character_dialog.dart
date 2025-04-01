import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../providers/game_provider.dart';
import 'character_form.dart';
import 'stat_panel.dart';
import 'impact_panel.dart';
import 'asset_panel.dart';
import 'legacy_panel.dart';

/// A utility class that handles character creation and editing dialogs.
class CharacterDialog {
  /// Shows a dialog for creating a new character.
  static Future<void> showCreateDialog(BuildContext context, GameProvider gameProvider) async {
    final nameController = TextEditingController();
    final handleController = TextEditingController();
    final bioController = TextEditingController();
    final imageUrlController = TextEditingController();
    bool isPlayerCharacter = true;
    
    // Default stats for player characters - typical distribution is one stat at 3, two at 2, and two at 1
    final stats = [
      CharacterStat(name: 'Edge', value: 1),
      CharacterStat(name: 'Heart', value: 2),
      CharacterStat(name: 'Iron', value: 3),
      CharacterStat(name: 'Shadow', value: 2),
      CharacterStat(name: 'Wits', value: 1),
    ];
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    
                    // Create character
                    Character character;
                    if (isPlayerCharacter) {
                      character = Character.createMainCharacter(
                        nameController.text,
                        handle: handleController.text.isEmpty ? null : handleController.text,
                      );
                    } else {
                      character = Character(
                        name: nameController.text,
                        handle: handleController.text.isEmpty ? null : handleController.text,
                      );
                    }
                    
                    // Set bio and image
                    character.bio = bioController.text.isEmpty ? null : bioController.text;
                    character.imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
                    
                    // Update stats if it's a player character
                    if (isPlayerCharacter) {
                      character.stats.clear();
                      character.stats.addAll(stats);
                    }
                    
                    // Add character to game
                    if (gameProvider.currentGame != null) {
                      // Use the createCharacter method from GameProvider
                      await gameProvider.createCharacter(
                        character.name, 
                        isMainCharacter: isPlayerCharacter,
                        handle: handleController.text.isEmpty ? null : handleController.text,
                      );
                    
                      // Update the character with our custom data
                      final createdCharacter = gameProvider.currentGame!.characters.last;
                      createdCharacter.bio = character.bio;
                      createdCharacter.imageUrl = character.imageUrl;
                      
                      // Update stats if it's a player character
                      if (isPlayerCharacter) {
                        createdCharacter.stats.clear();
                        createdCharacter.stats.addAll(stats);
                        
                        // Set default values for key stats
                        createdCharacter.momentum = 2;
                        createdCharacter.momentumReset = 2;
                        createdCharacter.health = 5;
                        createdCharacter.spirit = 5;
                        createdCharacter.supply = 5;
                        
                        // Ensure Base Rig asset is added
                        if (createdCharacter.assets.isEmpty) {
                          createdCharacter.assets.add(Asset.baseRig());
                        }
                      }
                    }
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      handleController.dispose();
      bioController.dispose();
      imageUrlController.dispose();
    });
  }

  /// Shows a dialog for editing an existing character.
  static Future<void> showEditDialog(BuildContext context, GameProvider gameProvider, Character character) async {
    final nameController = TextEditingController(text: character.name);
    final handleController = TextEditingController(text: character.handle ?? character.getHandle());
    final bioController = TextEditingController(text: character.bio);
    final imageUrlController = TextEditingController(text: character.imageUrl ?? '');
    final notesController = TextEditingController(text: character.notes.isNotEmpty ? character.notes.join('\n') : '');
    
    // Create controllers for key stats
    final momentumController = TextEditingController(text: character.momentum.toString());
    final healthController = TextEditingController(text: character.health.toString());
    final spiritController = TextEditingController(text: character.spirit.toString());
    final supplyController = TextEditingController(text: character.supply.toString());
    
    // Create copies of stats for editing
    final stats = character.stats.map((stat) => CharacterStat(
      name: stat.name,
      value: stat.value,
    )).toList();
    
    // Create copies of key stats for editing
    int momentum = character.momentum;
    int health = character.health;
    int spirit = character.spirit;
    int supply = character.supply;
    
    // Create copies of impacts for editing
    bool impactWounded = character.impactWounded;
    bool impactShaken = character.impactShaken;
    bool impactUnregulated = character.impactUnregulated;
    bool impactPermanentlyHarmed = character.impactPermanentlyHarmed;
    bool impactTraumatized = character.impactTraumatized;
    bool impactDoomed = character.impactDoomed;
    bool impactTormented = character.impactTormented;
    bool impactIndebted = character.impactIndebted;
    bool impactOverheated = character.impactOverheated;
    bool impactInfected = character.impactInfected;
    
    // For collapsible sections and editing state
    bool isEditing = false;
    bool showStats = true;
    bool showKeyStats = true;
    bool showImpacts = false;
    bool showAssets = true;
    bool showBio = true;
    bool showNotes = false;
    bool showLegacies = false;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Character' : character.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isEditing) ...[
                      // Character form for basic information
                      CharacterForm(
                        nameController: nameController,
                        handleController: handleController,
                        bioController: bioController,
                        imageUrlController: imageUrlController,
                        isPlayerCharacterSwitchVisible: false,
                        isPlayerCharacter: character.isMainCharacter,
                        onPlayerCharacterChanged: null,
                      ),
                    ] else ...[
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
                    
                    const SizedBox(height: 16),
                    
                    // Key Stats section (collapsible)
                    if (character.isMainCharacter) ...[
                      ListTile(
                        title: const Text('Key Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showKeyStats ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showKeyStats = !showKeyStats;
                          });
                        },
                      ),
                      if (showKeyStats) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: momentumController,
                                decoration: const InputDecoration(
                                  labelText: 'Momentum',
                                  helperText: 'Range: -6 to 10',
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: !isEditing,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(() {
                                      momentum = parsed.clamp(-6, 10 - character.totalImpacts);
                                      character.momentum = momentum;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: healthController,
                                decoration: const InputDecoration(
                                  labelText: 'Health',
                                  helperText: 'Range: 0 to 5',
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: !isEditing,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(() {
                                      health = parsed.clamp(0, 5);
                                      character.health = health;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: spiritController,
                                decoration: const InputDecoration(
                                  labelText: 'Spirit',
                                  helperText: 'Range: 0 to 5',
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: !isEditing,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(() {
                                      spirit = parsed.clamp(0, 5);
                                      character.spirit = spirit;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: supplyController,
                                decoration: const InputDecoration(
                                  labelText: 'Supply',
                                  helperText: 'Range: 0 to 5',
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: !isEditing,
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null) {
                                    setState(() {
                                      supply = parsed.clamp(0, 5);
                                      character.supply = supply;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Max Momentum: ${character.maxMomentum} (reduced by ${character.totalImpacts} impacts)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                    
                    // Impacts section (collapsible)
                    if (character.isMainCharacter) ...[
                      ListTile(
                        title: const Text('Impacts', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showImpacts ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showImpacts = !showImpacts;
                          });
                        },
                      ),
                      if (showImpacts) ...[
                        ImpactPanel(
                          character: character,
                          isEditable: isEditing,
                          onImpactChanged: (impactType, value) {
                            setState(() {
                              switch (impactType) {
                                case 'wounded':
                                  impactWounded = value;
                                  character.impactWounded = value;
                                  break;
                                case 'shaken':
                                  impactShaken = value;
                                  character.impactShaken = value;
                                  break;
                                case 'unregulated':
                                  impactUnregulated = value;
                                  character.impactUnregulated = value;
                                  break;
                                case 'permanently_harmed':
                                  impactPermanentlyHarmed = value;
                                  character.impactPermanentlyHarmed = value;
                                  break;
                                case 'traumatized':
                                  impactTraumatized = value;
                                  character.impactTraumatized = value;
                                  break;
                                case 'doomed':
                                  impactDoomed = value;
                                  character.impactDoomed = value;
                                  break;
                                case 'tormented':
                                  impactTormented = value;
                                  character.impactTormented = value;
                                  break;
                                case 'indebted':
                                  impactIndebted = value;
                                  character.impactIndebted = value;
                                  break;
                                case 'overheated':
                                  impactOverheated = value;
                                  character.impactOverheated = value;
                                  break;
                                case 'infected':
                                  impactInfected = value;
                                  character.impactInfected = value;
                                  break;
                              }
                            });
                          },
                        ),
                      ],
                    ],
                    
                    // Assets section (collapsible)
                    if (character.isMainCharacter) ...[
                      ListTile(
                        title: const Text('Assets', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showAssets ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showAssets = !showAssets;
                          });
                        },
                      ),
                      if (showAssets) ...[
                        AssetPanel(
                          character: character,
                          isEditable: isEditing,
                          onAssetsChanged: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                    
                    // Legacies section (collapsible)
                    if (character.isMainCharacter) ...[
                      ListTile(
                        title: const Text('Legacies', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showLegacies ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showLegacies = !showLegacies;
                          });
                        },
                      ),
                      if (showLegacies) ...[
                        LegacyPanel(
                          character: character,
                          isEditable: isEditing,
                          onLegacyChanged: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                    
                    // Notes section (collapsible)
                    if (character.isMainCharacter) ...[
                      ListTile(
                        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showNotes ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showNotes = !showNotes;
                          });
                        },
                      ),
                      if (showNotes) ...[
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                            hintText: 'Add notes about this character here',
                          ),
                          maxLines: 5,
                          readOnly: !isEditing,
                        ),
                      ],
                    ],
                    
                    // Character stats section (collapsible)
                    if (character.stats.isNotEmpty) ...[
                      ListTile(
                        title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Icon(showStats ? Icons.expand_less : Icons.expand_more),
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            showStats = !showStats;
                          });
                        },
                      ),
                      if (showStats) ...[
                        StatPanel(
                          stats: stats,
                          isEditable: isEditing,
                          onStatChanged: (index, value) {
                            setState(() {
                              stats[index].value = value;
                            });
                          },
                        ),
                      ],
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (character.stats.isNotEmpty && !isEditing)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.star),
                        label: Text(
                          gameProvider.currentGame?.mainCharacter?.id == character.id
                              ? 'Main Character'
                              : 'Set as Main Character',
                        ),
                        onPressed: gameProvider.currentGame?.mainCharacter?.id == character.id
                            ? null
                            : () {
                                if (gameProvider.currentGame != null) {
                                  gameProvider.currentGame!.mainCharacter = character;
                                  // Save the changes
                                  gameProvider.saveGame();
                                }
                                Navigator.pop(context);
                              },
                      ),
                  ],
                ),
              ),
              actions: [
                if (!isEditing)
                  TextButton(
                    onPressed: () {
                      // Show delete confirmation
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Delete Character'),
                            content: Text('Are you sure you want to delete ${character.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (gameProvider.currentGame != null) {
                                    gameProvider.currentGame!.characters.removeWhere((c) => c.id == character.id);
                                    // Save the changes
                                    gameProvider.saveGame();
                                  }
                                  Navigator.pop(context); // Close confirmation dialog
                                  Navigator.pop(context); // Close character details dialog
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Delete'),
                  ),
                TextButton(
                  onPressed: () {
                    if (isEditing) {
                      // Save changes
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a name'),
                          ),
                        );
                        return;
                      }
                      
                      // Update character directly
                      if (gameProvider.currentGame != null) {
                        // Find the character in the game
                        final index = gameProvider.currentGame!.characters.indexWhere((c) => c.id == character.id);
                        if (index != -1) {
                          // Update the character properties
                          character.name = nameController.text;
                          character.setHandle(handleController.text);
                          character.bio = bioController.text;
                          character.imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
                          
                          // Update notes
                          character.notes = notesController.text.isEmpty 
                              ? [] 
                              : notesController.text.split('\n').where((line) => line.trim().isNotEmpty).toList();
                          
                          // Update stats if it's a main character
                          if (character.stats.isNotEmpty) {
                            character.stats.clear();
                            character.stats.addAll(stats);
                          }
                          
                          // Update key stats
                          character.momentum = momentum;
                          character.health = health;
                          character.spirit = spirit;
                          character.supply = supply;
                          
                          // Update impacts
                          character.impactWounded = impactWounded;
                          character.impactShaken = impactShaken;
                          character.impactUnregulated = impactUnregulated;
                          character.impactPermanentlyHarmed = impactPermanentlyHarmed;
                          character.impactTraumatized = impactTraumatized;
                          character.impactDoomed = impactDoomed;
                          character.impactTormented = impactTormented;
                          character.impactIndebted = impactIndebted;
                          character.impactOverheated = impactOverheated;
                          character.impactInfected = impactInfected;
                          
                          // Save changes
                          gameProvider.saveGame();
                        }
                      }
                      
                      setState(() {
                        isEditing = false;
                      });
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Save' : 'Close'),
                ),
                if (!isEditing)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isEditing = true;
                      });
                    },
                    child: const Text('Edit'),
                  ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      handleController.dispose();
      bioController.dispose();
      imageUrlController.dispose();
      notesController.dispose();
      momentumController.dispose();
      healthController.dispose();
      spiritController.dispose();
      supplyController.dispose();
    });
  }

  /// Shows a dialog for confirming character deletion.
  static Future<bool> showDeleteConfirmation(BuildContext context, Character character) async {
    bool confirmed = false;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Character'),
          content: Text('Are you sure you want to delete ${character.name}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                confirmed = true;
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    return confirmed;
  }
}
