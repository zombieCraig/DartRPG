import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/character.dart';
import '../widgets/progress_track_widget.dart';

class CharacterScreen extends StatelessWidget {
  final String gameId;

  const CharacterScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final currentGame = gameProvider.currentGame;
        
        if (currentGame == null) {
          return const Center(
            child: Text('No game selected'),
          );
        }
        
        return Column(
          children: [
            // Character list/grid
            Expanded(
              child: currentGame.characters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No characters yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Character'),
                            onPressed: () async {
                              _showCreateCharacterDialog(context, gameProvider);
                            },
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: currentGame.characters.length + 1, // +1 for the "Add" card
                      itemBuilder: (context, index) {
                        if (index == currentGame.characters.length) {
                          // "Add" card
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                _showCreateCharacterDialog(context, gameProvider);
                              },
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 48),
                                    SizedBox(height: 8),
                                    Text('Add Character'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        
                        final character = currentGame.characters[index];
                        final isMainCharacter = currentGame.mainCharacter != null && 
                                               currentGame.mainCharacter?.id == character.id;
                        
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              _showCharacterDetailsDialog(context, gameProvider, character);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Character image or placeholder
                                Expanded(
                                  flex: 3,
                                  child: character.imageUrl != null
                                      ? Image.network(
                                          character.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.person,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.person,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                
                                // Character info
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (isMainCharacter)
                                              const Padding(
                                                padding: EdgeInsets.only(right: 4.0),
                                                child: Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: Colors.amber,
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                character.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (character.stats.isNotEmpty)
                                          Wrap(
                                            spacing: 8,
                                            children: character.stats.map((stat) {
                                              return Chip(
                                                label: Text(
                                                  '${stat.name}: ${stat.value}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                visualDensity: VisualDensity.compact,
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateCharacterDialog(BuildContext context, GameProvider gameProvider) async {
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
    
    showDialog(
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
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Player Character'),
                      subtitle: const Text('Has stats and can use assets'),
                      value: isPlayerCharacter,
                      onChanged: (value) {
                        setState(() {
                          isPlayerCharacter = value;
                        });
                      },
                    ),
                    if (isPlayerCharacter) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Stats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...stats.map((stat) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(stat.name),
                            ),
                            Expanded(
                              flex: 3,
                              child: Slider(
                                value: stat.value.toDouble(),
                                min: 0,
                                max: 5,
                                divisions: 5,
                                label: stat.value.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    stat.value = value.toInt();
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                stat.value.toString(),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: Stats range from 1-5. Typical characters have one stat at 3, two at 2, and two at 1.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
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
                    
                    // No validation needed for stats - they can be any value from 1-5
                    
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
      bioController.dispose();
      imageUrlController.dispose();
    });
  }

  void _showCharacterDetailsDialog(BuildContext context, GameProvider gameProvider, Character character) {
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
    
    showDialog(
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
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: handleController,
                        decoration: const InputDecoration(
                          labelText: 'Short Name or Handle',
                          helperText: 'No spaces, @, #, or brackets. Will default to first name if blank.',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
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
                    
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: imageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (isEditing)
                      TextField(
                        controller: bioController,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                        ),
                        maxLines: 3,
                      )
                    else
                      Text(
                        character.bio == null || character.bio!.isEmpty ? 'No bio available' : character.bio!,
                        style: TextStyle(
                          fontStyle: character.bio == null || character.bio!.isEmpty ? FontStyle.italic : FontStyle.normal,
                          color: character.bio == null || character.bio!.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    
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
                        // Misfortunes
                        const Text('Misfortunes', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(
                          title: const Text('Wounded'),
                          value: impactWounded,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactWounded = value;
                              character.impactWounded = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Shaken'),
                          value: impactShaken,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactShaken = value;
                              character.impactShaken = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Unregulated'),
                          value: impactUnregulated,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactUnregulated = value;
                              character.impactUnregulated = value;
                            });
                          } : null,
                        ),
                        
                        const SizedBox(height: 8),
                        // Lasting Effects
                        const Text('Lasting Effects', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(
                          title: const Text('Permanently Harmed'),
                          value: impactPermanentlyHarmed,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactPermanentlyHarmed = value;
                              character.impactPermanentlyHarmed = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Traumatized'),
                          value: impactTraumatized,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactTraumatized = value;
                              character.impactTraumatized = value;
                            });
                          } : null,
                        ),
                        
                        const SizedBox(height: 8),
                        // Burdens
                        const Text('Burdens', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(
                          title: const Text('Doomed'),
                          value: impactDoomed,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactDoomed = value;
                              character.impactDoomed = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Tormented'),
                          value: impactTormented,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactTormented = value;
                              character.impactTormented = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Indebted'),
                          value: impactIndebted,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactIndebted = value;
                              character.impactIndebted = value;
                            });
                          } : null,
                        ),
                        
                        const SizedBox(height: 8),
                        // Current Rig
                        const Text('Current Rig', style: TextStyle(fontWeight: FontWeight.bold)),
                        SwitchListTile(
                          title: const Text('Overheated'),
                          value: impactOverheated,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactOverheated = value;
                              character.impactOverheated = value;
                            });
                          } : null,
                        ),
                        SwitchListTile(
                          title: const Text('Infected'),
                          value: impactInfected,
                          contentPadding: EdgeInsets.zero,
                          onChanged: isEditing ? (value) {
                            setState(() {
                              impactInfected = value;
                              character.impactInfected = value;
                            });
                          } : null,
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
                        if (character.assets.isEmpty)
                          const Text('No assets attached'),
                        ...character.assets.map((asset) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          asset.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          asset.category,
                                          style: TextStyle(
                                            color: _getAssetCategoryColor(asset.category),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (asset.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(asset.description!),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isEditing && asset.category.toLowerCase() != 'base rig')
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          character.assets.remove(asset);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                        
                        if (isEditing) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Asset'),
                            onPressed: () {
                              // Show asset selection dialog
                              _showAssetSelectionDialog(context, (asset) {
                                setState(() {
                                  character.assets.add(asset);
                                });
                              });
                            },
                          ),
                        ],
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
                        ProgressTrackWidget(
                          label: 'Quests',
                          value: character.legacyQuests,
                          maxValue: 10,
                          isEditable: isEditing,
                          onBoxChanged: (newValue) {
                            setState(() {
                              character.legacyQuests = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ProgressTrackWidget(
                          label: 'Bonds',
                          value: character.legacyBonds,
                          maxValue: 10,
                          isEditable: isEditing,
                          onBoxChanged: (newValue) {
                            setState(() {
                              character.legacyBonds = newValue;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ProgressTrackWidget(
                          label: 'Discoveries',
                          value: character.legacyDiscoveries,
                          maxValue: 10,
                          isEditable: isEditing,
                          onBoxChanged: (newValue) {
                            setState(() {
                              character.legacyDiscoveries = newValue;
                            });
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
                        ...stats.map((stat) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(stat.name),
                              ),
                              Expanded(
                                flex: 3,
                                child: isEditing
                                    ? Slider(
                                        value: stat.value.toDouble(),
                                        min: 0,
                                        max: 5,
                                        divisions: 5,
                                        label: stat.value.toString(),
                                        onChanged: (value) {
                                          setState(() {
                                            stat.value = value.toInt();
                                          });
                                        },
                                      )
                                    : LinearProgressIndicator(
                                        value: stat.value / 5,
                                        backgroundColor: Colors.grey[300],
                                      ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  stat.value.toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          );
                        }),
                        
                        if (isEditing) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Note: Stats range from 1-5. Typical characters have one stat at 3, two at 2, and two at 1.',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
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
                      
                      // No validation needed for stats - they can be any value from 1-5
                      
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
      bioController.dispose();
      imageUrlController.dispose();
    });
  }
  
  // Asset selection dialog using assets from DataswornProvider
  void _showAssetSelectionDialog(BuildContext context, Function(Asset) onAssetSelected) {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final assetsByCategory = dataswornProvider.getAssetsByCategory();
    
    if (assetsByCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assets available. Please load a datasworn source.'),
        ),
      );
      return;
    }
    
    // Sort categories alphabetically
    final sortedCategories = assetsByCategory.keys.toList()..sort();
    final initialCategory = sortedCategories.isNotEmpty ? sortedCategories.first : null;
    
    showDialog(
      context: context,
      builder: (context) {
        // Use a ValueNotifier to track the selected category
        final selectedCategoryNotifier = ValueNotifier<String?>(initialCategory);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Asset'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Asset Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategoryNotifier.value,
                      items: sortedCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryNotifier.value = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Asset list - using ValueListenableBuilder to rebuild when category changes
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: selectedCategoryNotifier,
                        builder: (context, selectedCategory, _) {
                          if (selectedCategory == null || !assetsByCategory.containsKey(selectedCategory)) {
                            return const Center(child: Text('Select a category to view assets'));
                          }
                          
                          final assetsInCategory = assetsByCategory[selectedCategory]!;
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: assetsInCategory.length,
                            itemBuilder: (context, index) {
                              final asset = assetsInCategory[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Color.lerp(
                                  _getAssetCategoryColor(asset.category),
                                  Colors.white,
                                  0.9,
                                ),
                                child: ListTile(
                                  title: Text(
                                    asset.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        asset.category,
                                        style: TextStyle(
                                          color: _getAssetCategoryColor(asset.category),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (asset.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          asset.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                  isThreeLine: true,
                                  onTap: () {
                                    onAssetSelected(asset);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
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
              ],
            );
          },
        );
      },
    );
  }
  
  Color _getAssetCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'base rig':
        return Colors.black;
      case 'module':
        return Colors.blue;
      case 'path':
        return Colors.orange;
      case 'companion':
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }
}
