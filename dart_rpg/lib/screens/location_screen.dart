import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/location.dart';
import '../widgets/locations/graph/index.dart';
import '../widgets/locations/location_service.dart';
import '../widgets/locations/location_dialog.dart';
import '../widgets/locations/location_list_view.dart';

class LocationScreen extends StatefulWidget {
  final String gameId;

  const LocationScreen({super.key, required this.gameId});

  @override
  LocationScreenState createState() => LocationScreenState();
}

class LocationScreenState extends State<LocationScreen> {
  bool _showListView = false; // Toggle between graph and list view
  String _searchQuery = '';
  String? _focusLocationId;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        
        // Create location service
        final locationService = LocationService(gameProvider: gameProvider);
        
        // Filter locations based on search query
        final filteredLocations = locationService.getFilteredLocations(_searchQuery);
        
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
                            final matches = locationService.getFilteredLocations(value);
                            
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
                          onPressed: () async {
                            final location = await LocationDialog.showCreateDialog(
                              context,
                              locationService,
                            );
                            
                            if (location != null) {
                              setState(() {
                                _focusLocationId = location.id;
                              });
                            }
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
                              onPressed: () async {
                                await LocationDialog.showCreateDialog(
                                  context,
                                  locationService,
                                );
                                
                                // Force a rebuild
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      )
                    : _showListView
                        ? LocationListView(
                            locations: filteredLocations,
                            locationService: locationService,
                            onLocationSelected: (location) {
                              setState(() {
                                _showListView = false;
                                _focusLocationId = location.id;
                              });
                            },
                            onLocationUpdated: () {
                              // Force a rebuild
                              setState(() {});
                            },
                          )
                        : _buildGraphView(
                            context, 
                            locationService, 
                            currentGame.locations, 
                            filteredLocations
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildGraphView(
    BuildContext context, 
    LocationService locationService, 
    List<Location> allLocations,
    List<Location> filteredLocations
  ) {
    return LocationGraphWidget(
      key: ValueKey(allLocations.map((l) => l.id).join(',')),
      locations: allLocations,
      onLocationTap: (locationId) {
        final location = locationService.getLocationById(locationId);
        if (location != null) {
          LocationDialog.showEditDialog(
            context, 
            locationService, 
            location
          ).then((wasUpdated) {
            if (wasUpdated) {
              // Force a rebuild
              setState(() {});
            }
          });
        }
      },
      onLocationMoved: (locationId, x, y) {
        locationService.updateLocationPosition(locationId, x, y);
      },
      onScaleChanged: (scale) {
        // Save scale for the current location if needed
        if (allLocations.isNotEmpty && _focusLocationId != null) {
          locationService.updateLocationScale(_focusLocationId!, scale);
        }
      },
      searchQuery: _searchQuery,
      focusLocationId: _focusLocationId,
      game: locationService.gameProvider.currentGame,
    );
  }
}
