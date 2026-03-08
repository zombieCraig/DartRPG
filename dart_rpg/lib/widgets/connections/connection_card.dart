import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/connection.dart';
import 'connection_progress_panel.dart';
import 'connection_actions_panel.dart';

/// A card for displaying a connection
class ConnectionCard extends StatefulWidget {
  final Connection connection;
  final Character character;
  final Function(int)? onProgressChanged;
  final VoidCallback? onProgressRoll;
  final VoidCallback? onAdvance;
  final VoidCallback? onDecrease;
  final VoidCallback? onBond;
  final VoidCallback? onLose;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final Function(String)? onNotesChanged;

  const ConnectionCard({
    super.key,
    required this.connection,
    required this.character,
    this.onProgressChanged,
    this.onProgressRoll,
    this.onAdvance,
    this.onDecrease,
    this.onBond,
    this.onLose,
    this.onDelete,
    this.onEdit,
    this.onNotesChanged,
  });

  @override
  State<ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<ConnectionCard> {
  late TextEditingController _notesController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.connection.notes);
  }

  @override
  void didUpdateWidget(ConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.connection.notes != oldWidget.connection.notes &&
        widget.connection.notes != _notesController.text) {
      _notesController.text = widget.connection.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.connection.status.color.withAlpha(128),
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
                  Icon(widget.connection.status.icon,
                      color: widget.connection.status.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.connection.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          widget.connection.role,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
              ConnectionProgressPanel(
                connection: widget.connection,
                onProgressChanged: widget.onProgressChanged,
                onProgressRoll: widget.onProgressRoll,
                onAdvance: widget.onAdvance,
                onDecrease: widget.onDecrease,
                isEditable: widget.connection.status == ConnectionStatus.active,
              ),

              // Expanded content
              if (_isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Add notes about this connection...',
                    ),
                    maxLines: 3,
                    controller: _notesController,
                    onChanged: widget.onNotesChanged,
                    enabled:
                        widget.connection.status == ConnectionStatus.active,
                    textDirection: TextDirection.ltr,
                  ),
                ),

                ConnectionActionsPanel(
                  connection: widget.connection,
                  onBond: widget.onBond,
                  onLose: widget.onLose,
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
