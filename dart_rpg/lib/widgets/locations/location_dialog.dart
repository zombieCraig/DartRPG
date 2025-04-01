import 'package:flutter/material.dart';
import '../../models/location.dart';
import 'location_service.dart';
import 'location_form.dart';
import 'connection_panel.dart';

/// A utility class for showing location-related dialogs
class LocationDialog {
  /// Show a dialog for creating a new location
  static Future<Location?> showCreateDialog(
    BuildContext context,
    LocationService locationService, {
    String? connectToLocationId,
  }) async {
    // Determine valid segments based on the connection
    List<LocationSegment> validSegments = LocationSegment.values.toList();
    
    if (connectToLocationId != null) {
      final sourceLocation = locationService.getLocationById(connectToLocationId);
      if (sourceLocation != null) {
        // Filter valid segments based on adjacency rules
        validSegments = LocationSegment.values.where((segment) => 
          locationService.areSegmentsAdjacent(sourceLocation.segment, segment)
        ).toList();
        
        // Default to the next segment in the progression if possible
        if (validSegments.isEmpty) {
          // Fallback to all segments if no valid ones found
          validSegments = LocationSegment.values.toList();
        }
      }
    }
    
    Location? createdLocation;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(connectToLocationId != null ? 'Create Connected Location' : 'Create Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LocationForm(
                  validSegments: validSegments,
                  onSave: (name, description, segment, imageUrl) async {
                    // Create the location
                    final location = await locationService.createLocation(
                      name: name,
                      description: description,
                      segment: segment,
                      connectToLocationId: connectToLocationId,
                    );
                    
                    if (location != null && imageUrl != null) {
                      // Update the location with the image URL
                      await locationService.updateLocation(
                        locationId: location.id,
                        name: location.name,
                        description: location.description,
                        imageUrl: imageUrl,
                      );
                    }
                    
                    createdLocation = location;
                    Navigator.pop(context);
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
          ],
        );
      },
    );
    
    return createdLocation;
  }
  
  /// Show a dialog for editing a location
  static Future<bool> showEditDialog(
    BuildContext context,
    LocationService locationService,
    Location location,
  ) async {
    bool wasUpdated = false;
    
    // Get connected locations
    final connectedLocations = <Location>[];
    for (final connectedId in location.connectedLocationIds) {
      final connectedLocation = locationService.getLocationById(connectedId);
      if (connectedLocation != null) {
        connectedLocations.add(connectedLocation);
      }
    }
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location form
                    LocationForm(
                      initialLocation: location,
                      validSegments: LocationSegment.values,
                      onSave: (name, description, segment, imageUrl) async {
                        // Update the location
                        final success = await locationService.updateLocation(
                          locationId: location.id,
                          name: name,
                          description: description,
                          imageUrl: imageUrl,
                          segment: segment,
                        );
                        
                        if (success) {
                          wasUpdated = true;
                          Navigator.pop(context);
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to update location'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Connections panel
                    ConnectionPanel(
                      location: location,
                      connectedLocations: connectedLocations,
                      locationService: locationService,
                      isEditing: true,
                      onLocationTap: (connectedLocation) {
                        // Close this dialog and show the connected location
                        Navigator.pop(context);
                        showEditDialog(context, locationService, connectedLocation);
                      },
                      onAddConnection: () {
                        _showAddConnectionDialog(context, locationService, location);
                      },
                      onCreateConnectedLocation: () {
                        // Close this dialog and show create dialog
                        Navigator.pop(context);
                        showCreateDialog(
                          context, 
                          locationService,
                          connectToLocationId: location.id,
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Show delete confirmation
                    showDeleteConfirmation(context, locationService, location);
                  },
                  child: const Text('Delete'),
                ),
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
    
    return wasUpdated;
  }
  
  /// Show a dialog for confirming location deletion
  static Future<bool> showDeleteConfirmation(
    BuildContext context,
    LocationService locationService,
    Location location,
  ) async {
    bool wasDeleted = false;
    
    await showDialog(
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
              onPressed: () async {
                final success = await locationService.deleteLocation(location.id);
                
                if (success) {
                  wasDeleted = true;
                  Navigator.pop(context); // Close confirmation dialog
                  Navigator.pop(context); // Close location dialog
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete location'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.pop(context); // Close confirmation dialog
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    return wasDeleted;
  }
  
  /// Show a dialog for adding a connection to a location
  static Future<bool> _showAddConnectionDialog(
    BuildContext context,
    LocationService locationService,
    Location location,
  ) async {
    // Get valid connections
    final validConnections = locationService.getValidConnectionsForLocation(location.id);
    
    if (validConnections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid connections available'),
        ),
      );
      return false;
    }
    
    bool wasConnected = false;
    
    await showDialog(
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
                    onTap: () async {
                      final success = await locationService.connectLocations(
                        location.id, 
                        targetLocation.id
                      );
                      
                      if (success) {
                        wasConnected = true;
                        Navigator.pop(context);
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to connect locations'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Location'),
                  onPressed: () {
                    Navigator.pop(context);
                    showCreateDialog(
                      context, 
                      locationService,
                      connectToLocationId: location.id,
                    );
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
    
    return wasConnected;
  }
}
