import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/location.dart';

class LocationScreen extends StatelessWidget {
  final String gameId;

  const LocationScreen({super.key, required this.gameId});

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
            // Location list/grid
            Expanded(
              child: currentGame.locations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No locations yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Location'),
                            onPressed: () {
                              _showCreateLocationDialog(context, gameProvider);
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: currentGame.locations.length + 1, // +1 for the "Add" button
                      itemBuilder: (context, index) {
                        if (index == currentGame.locations.length) {
                          // "Add" button
                          return ListTile(
                            leading: const Icon(Icons.add_circle_outline),
                            title: const Text('Add Location'),
                            onTap: () {
                              _showCreateLocationDialog(context, gameProvider);
                            },
                          );
                        }
                        
                        final location = currentGame.locations[index];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(location.name),
                            subtitle: location.description != null && location.description!.isNotEmpty
                                ? Text(
                                    location.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            leading: const Icon(Icons.place),
                            onTap: () {
                              _showLocationDetailsDialog(context, gameProvider, location);
                            },
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

  void _showCreateLocationDialog(BuildContext context, GameProvider gameProvider) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageUrlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter location name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter location description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'Enter URL to location image',
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
                
                // Create location
                await gameProvider.createLocation(
                  nameController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                );
                
                // Update the location with image URL
                if (imageUrlController.text.isNotEmpty && gameProvider.currentGame != null) {
                  final createdLocation = gameProvider.currentGame!.locations.last;
                  createdLocation.imageUrl = imageUrlController.text;
                  
                  // Save changes by creating and removing a temporary location
                  await gameProvider.createLocation("temp");
                  gameProvider.currentGame!.locations.removeLast();
                }
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((_) {
      nameController.dispose();
      descriptionController.dispose();
      imageUrlController.dispose();
    });
  }

  void _showLocationDetailsDialog(BuildContext context, GameProvider gameProvider, Location location) {
    final nameController = TextEditingController(text: location.name);
    final descriptionController = TextEditingController(text: location.description);
    final imageUrlController = TextEditingController(text: location.imageUrl ?? '');
    
    bool isEditing = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Location' : location.name),
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
                    
                    if (location.imageUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(location.imageUrl!),
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
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 5,
                      )
                    else
                      Text(
                        location.description == null || location.description!.isEmpty
                            ? 'No description available'
                            : location.description!,
                        style: TextStyle(
                          fontStyle: location.description == null || location.description!.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: location.description == null || location.description!.isEmpty
                              ? Colors.grey
                              : null,
                        ),
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
                            title: const Text('Delete Location'),
                            content: Text('Are you sure you want to delete ${location.name}?'),
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
                                    gameProvider.currentGame!.locations.removeWhere((l) => l.id == location.id);
                                    // Save changes by creating and removing a temporary location
                                    gameProvider.createLocation("temp");
                                    gameProvider.currentGame!.locations.removeLast();
                                  }
                                  Navigator.pop(context); // Close confirmation dialog
                                  Navigator.pop(context); // Close location details dialog
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
                      
                      // Update location directly
                      if (gameProvider.currentGame != null) {
                        // Find the location in the game
                        final index = gameProvider.currentGame!.locations.indexWhere((l) => l.id == location.id);
                        if (index != -1) {
                          // Update the location properties
                          location.name = nameController.text;
                          location.description = descriptionController.text.isEmpty ? null : descriptionController.text;
                          location.imageUrl = imageUrlController.text.isEmpty ? null : imageUrlController.text;
                          
                          // Save changes by creating and removing a temporary location
                          gameProvider.createLocation("temp");
                          gameProvider.currentGame!.locations.removeLast();
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
      descriptionController.dispose();
      imageUrlController.dispose();
    });
  }
}
