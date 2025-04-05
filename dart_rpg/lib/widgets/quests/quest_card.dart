import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/quest.dart';
import 'quest_progress_panel.dart';
import 'quest_actions_panel.dart';

/// A card for displaying a quest
class QuestCard extends StatefulWidget {
  /// The quest to display
  final Quest quest;
  
  /// The character associated with the quest
  final Character character;
  
  /// Callback for when the progress changes
  final Function(int)? onProgressChanged;
  
  /// Callback for when a progress roll is requested
  final VoidCallback? onProgressRoll;
  
  /// Callback for when the advance button is pressed
  final VoidCallback? onAdvance;
  
  /// Callback for when the decrease button is pressed
  final VoidCallback? onDecrease;
  
  /// Callback for when the complete button is pressed
  final VoidCallback? onComplete;
  
  /// Callback for when the forsake button is pressed
  final VoidCallback? onForsake;
  
  /// Callback for when the delete button is pressed
  final VoidCallback? onDelete;
  
  /// Callback for when the edit button is pressed
  final VoidCallback? onEdit;
  
  /// Callback for when the notes change
  final Function(String)? onNotesChanged;
  
  /// Creates a new QuestCard
  const QuestCard({
    super.key,
    required this.quest,
    required this.character,
    this.onProgressChanged,
    this.onProgressRoll,
    this.onAdvance,
    this.onDecrease,
    this.onComplete,
    this.onForsake,
    this.onDelete,
    this.onEdit,
    this.onNotesChanged,
  });
  
  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  late TextEditingController _notesController;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.quest.notes);
  }
  
  @override
  void didUpdateWidget(QuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller text if the quest notes have changed
    // and the controller text is different (to avoid cursor jumping)
    if (widget.quest.notes != oldWidget.quest.notes && 
        widget.quest.notes != _notesController.text) {
      _notesController.text = widget.quest.notes;
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
          color: widget.quest.rank.color.withAlpha(128), // 0.5 opacity = 128 alpha
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
              // Header with title and rank
              Row(
                children: [
                  Icon(widget.quest.rank.icon, color: widget.quest.rank.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.quest.title,
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
              
              // Character association
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Character: ${widget.character.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress track (always visible)
              QuestProgressPanel(
                quest: widget.quest,
                onProgressChanged: widget.onProgressChanged,
                onProgressRoll: widget.onProgressRoll,
                onAdvance: widget.onAdvance,
                onDecrease: widget.onDecrease,
                isEditable: widget.quest.status == QuestStatus.ongoing,
              ),
              
              // Expanded content
              if (_isExpanded) ...[
                // Notes section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Add notes about this quest...',
                    ),
                    maxLines: 3,
                    controller: _notesController,
                    onChanged: widget.onNotesChanged,
                    enabled: widget.quest.status == QuestStatus.ongoing,
                    textDirection: TextDirection.ltr, // Ensure left-to-right text direction
                  ),
                ),
                
                // Action buttons
                QuestActionsPanel(
                  quest: widget.quest,
                  onComplete: widget.onComplete,
                  onForsake: widget.onForsake,
                  onDelete: widget.onDelete,
                  onEdit: widget.onEdit,
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
