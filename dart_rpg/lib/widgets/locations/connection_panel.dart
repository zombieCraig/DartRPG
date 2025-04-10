import 'package:flutter/material.dart';
import '../../models/location.dart';
import 'location_service.dart';

/// A panel for displaying and managing location connections
class ConnectionPanel extends StatelessWidget {
  /// The location being displayed
  final Location location;
  
  /// The list of connected locations
  final List<Location> connectedLocations;
  
  /// The location service
  final LocationService locationService;
  
  /// Callback when a location is tapped
  final Function(Location) onLocationTap;
  
  /// Callback when the add connection button is tapped
  final Function() onAddConnection;
  
  /// Callback when the create connected location button is tapped
  final Function() onCreateConnectedLocation;
  
  /// Callback when a connection is disconnected
  final Function(String)? onDisconnect;
  
  /// Whether the panel is in editing mode
  final bool isEditing;
  
  /// Creates a new ConnectionPanel
  const ConnectionPanel({
    super.key,
    required this.location,
    required this.connectedLocations,
    required this.locationService,
    required this.onLocationTap,
    required this.onAddConnection,
    required this.onCreateConnectedLocation,
    this.onDisconnect,
    this.isEditing = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        const Text(
          'Connections',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        
        // Connection list
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
                        tooltip: 'Disconnect',
                        onPressed: () async {
                          // Show confirmation dialog
                          final shouldDisconnect = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Disconnect Locations'),
                              content: Text(
                                'Are you sure you want to disconnect ${location.name} from ${connectedLocation.name}?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Disconnect'),
                                ),
                              ],
                            ),
                          ) ?? false;
                          
                          if (shouldDisconnect) {
                            final success = await locationService.disconnectLocations(
                              location.id, 
                              connectedLocation.id
                            );
                            
                            // Notify parent if disconnect was successful
                            if (success && onDisconnect != null) {
                              onDisconnect!(connectedLocation.id);
                            }
                          }
                        },
                      )
                    : null,
                onTap: () => onLocationTap(connectedLocation),
              );
            }).toList(),
          ),
        
        // Action buttons for editing mode
        if (isEditing) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add Connection'),
                  onPressed: onAddConnection,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create Connected Location'),
                  onPressed: onCreateConnectedLocation,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
