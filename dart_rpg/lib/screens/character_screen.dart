import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/character.dart';

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
                      }).toList(),
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
                      character = Character.createMainCharacter(nameController.text);
                    } else {
                      character = Character(
                        name: nameController.text,
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
                      await gameProvider.createCharacter(character.name, isMainCharacter: isPlayerCharacter);
                      
                      // Update the character with our custom data
                      final createdCharacter = gameProvider.currentGame!.characters.last;
                      createdCharacter.bio = character.bio;
                      createdCharacter.imageUrl = character.imageUrl;
                      
                      // Update stats if it's a player character
                      if (isPlayerCharacter) {
                        createdCharacter.stats.clear();
                        createdCharacter.stats.addAll(stats);
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
    final bioController = TextEditingController(text: character.bio);
    final imageUrlController = TextEditingController(text: character.imageUrl ?? '');
    
    // Create copies of stats for editing
    final stats = character.stats.map((stat) => CharacterStat(
      name: stat.name,
      value: stat.value,
    )).toList();
    
    bool isEditing = false;
    
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
                    
                    if (character.stats.isNotEmpty) ...[
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
                      }).toList(),
                      
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
                          character.bio = bioController.text;
                          character.imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
                          
                          // Update stats if it's a main character
                          if (character.stats.isNotEmpty) {
                            character.stats.clear();
                            character.stats.addAll(stats);
                          }
                          
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
}
