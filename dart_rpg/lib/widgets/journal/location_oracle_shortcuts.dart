import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../models/location.dart';
import '../../models/journal_entry.dart'; // Import for OracleRoll
import 'node_type_oracle_dialog.dart';

/// A widget that displays oracle shortcut buttons for linked locations with node types.
class LocationOracleShortcuts extends StatelessWidget {
  /// The list of linked location IDs.
  final List<String> linkedLocationIds;

  /// Callback for when an oracle roll is added.
  final Function(OracleRoll oracleRoll)? onOracleRollAdded;

  /// Callback for when text should be inserted at the cursor.
  final Function(String text)? onInsertText;

  /// Creates a new LocationOracleShortcuts widget.
  const LocationOracleShortcuts({
    super.key,
    required this.linkedLocationIds,
    this.onOracleRollAdded,
    this.onInsertText,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedLocationIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final gameProvider = Provider.of<GameProvider>(context);
    final dataswornProvider = Provider.of<DataswornProvider>(context);
    final currentGame = gameProvider.currentGame;

    if (currentGame == null) {
      return const SizedBox.shrink();
    }

    // Get linked locations with node types
    final locationsWithNodeTypes = currentGame.locations
        .where((location) => 
            linkedLocationIds.contains(location.id) && 
            location.nodeType != null && 
            location.nodeType!.isNotEmpty)
        .toList();

    if (locationsWithNodeTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: locationsWithNodeTypes.map((location) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.casino, size: 16),
            label: Text('${location.name} Oracles'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getLocationColor(location),
              foregroundColor: _getTextColor(_getLocationColor(location)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              _showNodeTypeOracleDialog(context, location, dataswornProvider);
            },
          );
        }).toList(),
      ),
    );
  }

  /// Shows the node type oracle dialog for a location.
  void _showNodeTypeOracleDialog(
    BuildContext context, 
    Location location, 
    DataswornProvider dataswornProvider
  ) {
    showDialog(
      context: context,
      builder: (context) => NodeTypeOracleDialog(
        location: location,
        dataswornProvider: dataswornProvider,
        onOracleRollAdded: onOracleRollAdded,
        onInsertText: onInsertText,
      ),
    );
  }

  /// Gets a color for a location based on its segment.
  Color _getLocationColor(Location location) {
    return location.segment.color;
  }

  /// Gets an appropriate text color based on the background color.
  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    final luminance = backgroundColor.computeLuminance();
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
