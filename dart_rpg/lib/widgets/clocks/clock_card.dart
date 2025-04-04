import 'package:flutter/material.dart';
import '../../models/clock.dart';
import 'clock_progress_panel.dart';

/// A card for displaying a clock
class ClockCard extends StatefulWidget {
  /// The clock to display
  final Clock clock;
  
  /// Callback for when the advance button is pressed
  final VoidCallback? onAdvance;
  
  /// Callback for when the reset button is pressed
  final VoidCallback? onReset;
  
  /// Callback for when the delete button is pressed
  final VoidCallback? onDelete;
  
  /// Callback for when the edit button is pressed
  final VoidCallback? onEdit;
  
  /// Creates a new ClockCard
  const ClockCard({
    super.key,
    required this.clock,
    this.onAdvance,
    this.onReset,
    this.onDelete,
    this.onEdit,
  });
  
  @override
  State<ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends State<ClockCard> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.clock.type.color.withOpacity(0.5),
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
              // Header with title and type
              Row(
                children: [
                  Icon(widget.clock.type.icon, color: widget.clock.type.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.clock.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    tooltip: _isExpanded ? 'Collapse' : 'Expand',
                  ),
                ],
              ),
              
              // Basic progress info (always visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Type: ${widget.clock.type.displayName}',
                      style: TextStyle(
                        color: widget.clock.type.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Progress: ${widget.clock.progress}/${widget.clock.segments}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Expanded content
              if (_isExpanded) ...[
                // Clock progress panel
                Center(
                  child: ClockProgressPanel(
                    clock: widget.clock,
                    onAdvance: widget.onAdvance,
                    onReset: widget.onReset,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      onPressed: widget.onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      onPressed: widget.onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Collapsed hint
              if (!_isExpanded)
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Tap to ${_isExpanded ? 'collapse' : 'expand'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
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
