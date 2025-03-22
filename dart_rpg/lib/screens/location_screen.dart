import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/location.dart';
import '../widgets/location_graph_widget.dart';

class LocationScreen extends StatefulWidget {
  final String gameId;

  const LocationScreen({super.key, required this.gameId});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _showListView = false; // Toggle between graph and list view
  String _searchQuery = '';
  String? _focusLocationId;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Controllers for location dialogs
  TextEditingController? _locationNameController;
  TextEditingController? _locationDescriptionController;
  TextEditingController? _locationImageUrlController;
  TextEditingController? _locationEditNameController;
  TextEditingController? _locationEditDescriptionController;
  TextEditingController? _locationEditImageUrlController;
  
  @override
  void dispose() {
    _searchController.dispose();
    _disposeLocationControllers();
    super.dispose();
  }
  
  void _disposeLocationControllers() {
    _locationNameController?.dispose();
    _locationDescriptionController?.dispose();
    _locationImageUrlController?.dispose();
    _locationEditNameController?.dispose();
    _locationEditDescriptionController?.dispose();
    _locationEditImageUrlController?.dispose();
    
    _locationNameController = null;
    _locationDescriptionController = null;
    _locationImageUrlController = null;
    _locationEditNameController = null;
    _locationEditDescriptionController = null;
    _locationEditImageUrlController = null;
  }
  
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
        
        // Filter locations based on search query
        List<Location> filteredLocations = currentGame.locations;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredLocations = currentGame.locations.where((loc) => 
            loc.name.toLowerCase().contains(query) ||
            (loc.description != null && loc.description!.toLowerCase().contains(query))
          ).toList();
        }
        
        return Scaffold(
          key: _scaffoldKey,
          body: Column(
            children: [
              // Search bar and view toggle
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search locations...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _focusLocationId = null;
                                });
                              },
                            )
                          : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          // If there's exactly one match, focus on it
                          if (value.isNotEmpty) {
                            final matches = currentGame.locations.where((loc) => 
                              loc.name.toLowerCase().contains(value.toLowerCase()) ||
                              (loc.description != null && loc.description!.toLowerCase().contains(value.toLowerCase()))
                            ).toList();
                            
                            if (matches.length == 1) {
                              _focusLocationId = matches.first.id;
                            }
                          } else {
                            _focusLocationId = null;
                          }
                        });
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // View toggle and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ToggleButtons(
                          isSelected: [!_showListView, _showListView],
                          onPressed: (index) {
                            setState(() {
                              _showListView = index == 1;
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(Icons.account_tree),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(Icons.list),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Location'),
                          onPressed: () {
                            _showCreateLocationDialog(context, gameProvider);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Search results indicator
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Found ${filteredLocations.length} location${filteredLocations.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const Spacer(),
                      if (filteredLocations.length > 1 && !_showListView)
                        TextButton.icon(
                          icon: const Icon(Icons.center_focus_strong, size: 16),
                          label: const Text('Focus on matches'),
                          onPressed: () {
                            // This would ideally zoom to show all matches
                            if (filteredLocations.isNotEmpty) {
                              setState(() {
                                _focusLocationId = filteredLocations.first.id;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                ),
              
              // Location graph/list
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
                    : _showListView
                        ? _buildListView(context, gameProvider, filteredLocations)
                        : _buildGraphView(context, gameProvider, currentGame.locations, filteredLocations),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildListView(BuildContext context, GameProvider gameProvider, List<Location> locations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(location.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (location.description != null && location.description!.isNotEmpty)
                  Text(
                    location.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  'Segment: ${location.segment.displayName}',
                  style: TextStyle(
                    color: location.segment.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            leading: Icon(
              Icons.place,
              color: location.segment.color,
            ),
            onTap: () {
              _showLocationDetailsDialog(context, gameProvider, location);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildGraphView(
    BuildContext context, 
    GameProvider gameProvider, 
    List<Location> allLocations,
    List<Location> filteredLocations
  ) {
    return LocationGraphWidget(
      key: ValueKey(allLocations.map((l) => l.id).join(',')),
      locations: allLocations,
      onLocationTap: (locationId) {
        final location = allLocations.firstWhere((loc) => loc.id == locationId);
        _showLocationDetailsDialog(context, gameProvider, location);
      },
      onLocationMoved: (locationId, x, y) {
        gameProvider.updateLocationPosition(locationId, x, y);
      },
      onScaleChanged: (scale) {
        // Save scale for the current location if needed
        if (allLocations.isNotEmpty) {
          gameProvider.updateLocationScale(allLocations.first.id, scale);
        }
      },
      searchQuery: _searchQuery,
      focusLocationId: _focusLocationId,
      game: gameProvider.currentGame,
    );
  }

  void _showCreateLocationDialog(BuildContext context, GameProvider gameProvider, {String? connectToLocationId}) {
    // Initialize controllers
    _locationNameController = TextEditingController();
    _locationDescriptionController = TextEditingController();
    _locationImageUrlController = TextEditingController();
    
    // Default to Core segment, but allow selection
    LocationSegment selectedSegment = LocationSegment.core;
    
    // If connecting to an existing location, get its segment to determine valid options
    List<LocationSegment> validSegments = LocationSegment.values.toList();
    if (connectToLocationId != null && gameProvider.currentGame != null) {
      final sourceLocation = gameProvider.currentGame!.locations.firstWhere(
        (loc) => loc.id == connectToLocationId,
        orElse: () => gameProvider.currentGame!.locations.first,
      );
      
      // Determine valid segments based on the source location's segment
      switch (sourceLocation.segment) {
        case LocationSegment.core:
          validSegments = [LocationSegment.core, LocationSegment.corpNet];
          break;
        case LocationSegment.corpNet:
          validSegments = [LocationSegment.core, LocationSegment.corpNet, LocationSegment.govNet];
          break;
        case LocationSegment.govNet:
          validSegments = [LocationSegment.corpNet, LocationSegment.govNet, LocationSegment.darkNet];
          break;
        case LocationSegment.darkNet:
          validSegments = [LocationSegment.govNet, LocationSegment.darkNet];
          break;
      }
      
      // Default to the next segment in the progression if possible
      if (sourceLocation.segment == LocationSegment.core && validSegments.contains(LocationSegment.corpNet)) {
        selectedSegment = LocationSegment.corpNet;
      } else if (sourceLocation.segment == LocationSegment.corpNet && validSegments.contains(LocationSegment.govNet)) {
        selectedSegment = LocationSegment.govNet;
      } else if (sourceLocation.segment == LocationSegment.govNet && validSegments.contains(LocationSegment.darkNet)) {
        selectedSegment = LocationSegment.darkNet;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(connectToLocationId != null ? 'Create Connected Location' : 'Create Location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _locationNameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter location name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter location description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationImageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'Enter URL to location image',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LocationSegment>(
                      value: selectedSegment,
                      decoration: const InputDecoration(
                        labelText: 'Segment',
                        border: OutlineInputBorder(),
                      ),
                      items: validSegments.map((segment) {
                        return DropdownMenuItem<LocationSegment>(
                          value: segment,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: segment.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(segment.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSegment = value;
                          });
                        }
                      },
                    ),
                    if (connectToLocationId != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'This location will be connected to the selected location.',
                        style: TextStyle(fontStyle: FontStyle.italic),
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
                    if (_locationNameController!.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a name'),
                        ),
                      );
                      return;
                    }
                    
                    // Create location with segment and connection
                    await gameProvider.createLocation(
                      _locationNameController!.text,
                      description: _locationDescriptionController!.text.isEmpty ? null : _locationDescriptionController!.text,
                      segment: selectedSegment,
                      connectToLocationId: connectToLocationId,
                    );
                    
                    // Update the location with image URL
                    if (_locationImageUrlController!.text.isNotEmpty && gameProvider.currentGame != null) {
                      final createdLocation = gameProvider.currentGame!.locations.last;
                      createdLocation.imageUrl = _locationImageUrlController!.text;
                      
                      // Save changes
                      await gameProvider.saveGame();
                    }
                    
                    // Force a rebuild of the graph
                    setState(() {
                      // If this is a new connected location, focus on it
                      if (connectToLocationId != null && gameProvider.currentGame != null) {
                        _focusLocationId = gameProvider.currentGame!.locations.last.id;
                      }
                    });
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      
                      // Force a rebuild of the parent widget
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          this.setState(() {});
                        }
                      });
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Don't dispose controllers here, they will be disposed in _disposeLocationControllers
    });
  }

  void _showLocationDetailsDialog(BuildContext context, GameProvider gameProvider, Location location) {
    // Initialize controllers
    _locationEditNameController = TextEditingController(text: location.name);
    _locationEditDescriptionController = TextEditingController(text: location.description);
    _locationEditImageUrlController = TextEditingController(text: location.imageUrl ?? '');
    
    // For segment selection
    LocationSegment selectedSegment = location.segment;
    
    // For connection management
    final connectedLocations = <Location>[];
    if (gameProvider.currentGame != null) {
      for (final connectedId in location.connectedLocationIds) {
        try {
          final connectedLocation = gameProvider.currentGame!.locations.firstWhere(
            (loc) => loc.id == connectedId,
          );
          connectedLocations.add(connectedLocation);
        } catch (_) {
          // Ignore if location not found
        }
      }
    }
    
    bool isEditing = false;
    
    // Create a function to force a rebuild of the parent widget
    void forceParentRebuild() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
    
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
                        controller: _locationEditNameController,
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
                        controller: _locationEditImageUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Segment indicator/selector
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: location.segment.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Segment: ${location.segment.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<LocationSegment>(
                        value: selectedSegment,
                        decoration: const InputDecoration(
                          labelText: 'Segment',
                          border: OutlineInputBorder(),
                        ),
                        items: LocationSegment.values.map((segment) {
                          return DropdownMenuItem<LocationSegment>(
                            value: segment,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: segment.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(segment.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedSegment = value;
                            });
                          }
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (isEditing)
                      TextField(
                        controller: _locationEditDescriptionController,
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
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Connections section
                    const Text(
                      'Connections',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if (connectedLocations.isEmpty)
                      const Text(
                        'No connections',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                    else
                      Column(
                        children: connectedLocations.map((connectedLocation) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: connectedLocation.segment.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black),
                              ),
                            ),
                            title: Text(connectedLocation.name),
                            subtitle: Text(connectedLocation.segment.displayName),
                            trailing: isEditing
                                ? IconButton(
                                    icon: const Icon(Icons.link_off),
                                    onPressed: () {
                                      setState(() {
                                        gameProvider.disconnectLocations(location.id, connectedLocation.id);
                                        connectedLocations.remove(connectedLocation);
                                      });
                                      
                                      // Force a rebuild of the parent widget
                                      forceParentRebuild();
                                    },
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _showLocationDetailsDialog(context, gameProvider, connectedLocation);
                            },
                          );
                        }).toList(),
                      ),
                    
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_link),
                        label: const Text('Add Connection'),
                        onPressed: () {
                          _showAddConnectionDialog(context, gameProvider, location);
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Connected Location'),
                        onPressed: () {
                          Navigator.pop(context);
                          _showCreateLocationDialog(context, gameProvider, connectToLocationId: location.id);
                        },
                      ),
                    ],
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
                                    // Remove all connections first
                                    for (final connectedId in List.from(location.connectedLocationIds)) {
                                      gameProvider.disconnectLocations(location.id, connectedId);
                                    }
                                    
                                    // Then remove the location
                                    gameProvider.currentGame!.locations.removeWhere((l) => l.id == location.id);
                                    gameProvider.saveGame();
                                    
                                    // Force a rebuild of the parent widget
                                    forceParentRebuild();
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
                      if (_locationEditNameController!.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a name'),
                          ),
                        );
                        return;
                      }
                      
                      // Update location directly
                      if (gameProvider.currentGame != null) {
                        // Update the location properties
                        location.name = _locationEditNameController!.text;
                        location.description = _locationEditDescriptionController!.text.isEmpty ? null : _locationEditDescriptionController!.text;
                        location.imageUrl = _locationEditImageUrlController!.text.isEmpty ? null : _locationEditImageUrlController!.text;
                        
                        // Update segment if changed
                        if (location.segment != selectedSegment) {
                          try {
                            gameProvider.updateLocationSegment(location.id, selectedSegment);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update segment: ${e.toString()}'),
                              ),
                            );
                            return;
                          }
                        }
                        
                        // Save changes
                        gameProvider.saveGame();
                        
                        // Force a rebuild of the parent widget
                        forceParentRebuild();
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
      // Don't dispose controllers here, they will be disposed in _disposeLocationControllers
    });
  }
  
  void _showAddConnectionDialog(BuildContext context, GameProvider gameProvider, Location location) {
    // Get valid connections based on segment adjacency rules
    final validConnections = gameProvider.getValidConnectionsForLocation(location.id);
    
    if (validConnections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid connections available'),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Connection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a location to connect to:'),
                const SizedBox(height: 16),
                ...validConnections.map((targetLocation) {
                  return ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: targetLocation.segment.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black),
                      ),
                    ),
                    title: Text(targetLocation.name),
                    subtitle: Text(targetLocation.segment.displayName),
                    onTap: () {
                      gameProvider.connectLocations(location.id, targetLocation.id);
                      
                      // Force a rebuild of the graph
                      setState(() {
                        // Focus on the newly connected location
                        _focusLocationId = targetLocation.id;
                      });
                      
                      Navigator.pop(context);
                      
                      // Force a rebuild of the parent widget
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          setState(() {});
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Location'),
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateLocationDialog(context, gameProvider, connectToLocationId: location.id);
                  },
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
  }
}
