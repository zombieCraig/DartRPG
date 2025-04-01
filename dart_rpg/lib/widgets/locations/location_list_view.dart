import 'package:flutter/material.dart';
import '../../models/location.dart';
import 'location_service.dart';
import 'location_dialog.dart';

/// A widget for displaying locations in a list view
class LocationListView extends StatelessWidget {
  /// The list of locations to display
  final List<Location> locations;
  
  /// The location service
  final LocationService locationService;
  
  /// Callback when a location is selected
  final Function(Location)? onLocationSelected;
  
  /// Callback when a location is updated
  final Function()? onLocationUpdated;
  
  /// Creates a new LocationListView
  const LocationListView({
    super.key,
    required this.locations,
    required this.locationService,
    this.onLocationSelected,
    this.onLocationUpdated,
  });
  
  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const Center(
        child: Text('No locations found'),
      );
    }
    
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
                if (location.connectedLocationIds.isNotEmpty)
                  Text(
                    'Connections: ${location.connectedLocationIds.length}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: location.segment.color,
                shape: locationService.isRigLocation(location.id) ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: locationService.isRigLocation(location.id) ? BorderRadius.circular(8) : null,
                border: Border.all(color: Colors.black),
              ),
              child: Icon(
                Icons.place,
                color: _getTextColor(location.segment.color),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final wasUpdated = await LocationDialog.showEditDialog(
                  context,
                  locationService,
                  location,
                );
                
                if (wasUpdated && onLocationUpdated != null) {
                  onLocationUpdated!();
                }
              },
            ),
            onTap: () {
              if (onLocationSelected != null) {
                onLocationSelected!(location);
              }
            },
          ),
        );
      },
    );
  }
  
  /// Get the text color based on background color
  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
