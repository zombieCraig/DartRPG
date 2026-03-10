import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/location.dart';
import '../../providers/game_provider.dart';
import '../locations/location_form.dart';

class NetworkNodesStep extends StatefulWidget {
  final Game game;
  final GameProvider gameProvider;

  const NetworkNodesStep({
    super.key,
    required this.game,
    required this.gameProvider,
  });

  @override
  State<NetworkNodesStep> createState() => _NetworkNodesStepState();
}

class _NetworkNodesStepState extends State<NetworkNodesStep> {
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    // Filter to non-rig locations for display
    final locations = widget.game.locations
        .where((l) => l.id != widget.game.rigLocation?.id)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Create the initial nodes of your network. The rulebook recommends about 3 nodes in the Core segment to start.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (locations.isEmpty && !_showForm)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
            child: Center(
              child: Text(
                'No network nodes created yet (besides Your Rig). Tap the button below to add one.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else if (!_showForm)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: location.segment.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(location.name),
                  subtitle: Text(
                    '${location.segment.displayName}${location.nodeType != null ? ' - ${location.nodeType}' : ''}',
                  ),
                ),
              );
            },
          ),
        if (_showForm)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Network Node',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _showForm = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LocationForm(
                      validSegments: LocationSegment.values,
                      availableConnections: widget.game.locations,
                      onSave: (name, description, segment, imageUrl, nodeType, connectionId) async {
                        await widget.gameProvider.createLocation(
                          name,
                          description: description,
                          segment: segment,
                          nodeType: nodeType,
                          connectToLocationId: connectionId,
                        );
                        if (context.mounted) {
                          setState(() => _showForm = false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!_showForm) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Add Network Node'),
            ),
          ),
        ],
      ],
    );
  }
}
