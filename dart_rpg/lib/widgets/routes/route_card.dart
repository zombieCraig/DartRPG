import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/location.dart';
import '../../models/network_route.dart';
import 'route_progress_panel.dart';
import 'route_actions_panel.dart';

/// A card for displaying a network route
class RouteCard extends StatefulWidget {
  final NetworkRoute route;
  final Character character;
  final Function(int)? onProgressChanged;
  final VoidCallback? onProgressRoll;
  final VoidCallback? onAdvance;
  final VoidCallback? onDecrease;
  final VoidCallback? onComplete;
  final VoidCallback? onBurn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Function(String)? onNotesChanged;

  const RouteCard({
    super.key,
    required this.route,
    required this.character,
    this.onProgressChanged,
    this.onProgressRoll,
    this.onAdvance,
    this.onDecrease,
    this.onComplete,
    this.onBurn,
    this.onDelete,
    this.onEdit,
    this.onNotesChanged,
  });

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  late TextEditingController _notesController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.route.notes);
  }

  @override
  void didUpdateWidget(RouteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.route.notes != oldWidget.route.notes &&
        widget.route.notes != _notesController.text) {
      _notesController.text = widget.route.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildSegmentChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.route.status.color.withAlpha(128),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Icon(widget.route.status.icon,
                      color: widget.route.status.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.route.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),

              // Segment chips (origin → destination)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _buildSegmentChip(
                      widget.route.origin.displayName,
                      widget.route.origin.color,
                      widget.route.origin.icon,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward, size: 16),
                    ),
                    _buildSegmentChip(
                      widget.route.destination.displayName,
                      widget.route.destination.color,
                      widget.route.destination.icon,
                    ),
                  ],
                ),
              ),

              // Character association
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Character: ${widget.character.name}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Progress track (always visible)
              RouteProgressPanel(
                route: widget.route,
                onProgressChanged: widget.onProgressChanged,
                onProgressRoll: widget.onProgressRoll,
                onAdvance: widget.onAdvance,
                onDecrease: widget.onDecrease,
                isEditable: widget.route.status == RouteStatus.active,
              ),

              // Expanded content
              if (_isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Add notes about this route...',
                    ),
                    maxLines: 3,
                    controller: _notesController,
                    onChanged: widget.onNotesChanged,
                    enabled: widget.route.status == RouteStatus.active,
                    textDirection: TextDirection.ltr,
                  ),
                ),

                RouteActionsPanel(
                  route: widget.route,
                  onComplete: widget.onComplete,
                  onBurn: widget.onBurn,
                  onDelete: widget.onDelete,
                  onEdit: widget.onEdit,
                ),
              ],

              if (!_isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap to expand',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
