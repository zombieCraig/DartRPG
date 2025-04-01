import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/quest.dart';

/// A form for creating or editing a quest
class QuestForm extends StatefulWidget {
  /// The initial quest data (for editing)
  final Quest? initialQuest;
  
  /// The list of available characters
  final List<Character> characters;
  
  /// Callback for when the form is submitted
  final Function(String title, String characterId, QuestRank rank, String notes) onSubmit;
  
  /// Creates a new QuestForm
  const QuestForm({
    super.key,
    this.initialQuest,
    required this.characters,
    required this.onSubmit,
  });
  
  @override
  State<QuestForm> createState() => _QuestFormState();
}

class _QuestFormState extends State<QuestForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  QuestRank _selectedRank = QuestRank.troublesome;
  String? _selectedCharacterId;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with the initial quest data if provided
    if (widget.initialQuest != null) {
      _titleController.text = widget.initialQuest!.title;
      _notesController.text = widget.initialQuest!.notes;
      _selectedRank = widget.initialQuest!.rank;
      _selectedCharacterId = widget.initialQuest!.characterId;
    } else if (widget.characters.isNotEmpty) {
      // Otherwise, initialize with the first character
      _selectedCharacterId = widget.characters.first.id;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Quest Title',
              border: OutlineInputBorder(),
              hintText: 'Enter the quest title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          
          // Character dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Character',
              border: OutlineInputBorder(),
              hintText: 'Select a character',
            ),
            value: _selectedCharacterId,
            items: widget.characters.map((character) {
              return DropdownMenuItem<String>(
                value: character.id,
                child: Text(character.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCharacterId = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a character';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Rank dropdown
          DropdownButtonFormField<QuestRank>(
            decoration: const InputDecoration(
              labelText: 'Quest Rank',
              border: OutlineInputBorder(),
              hintText: 'Select a rank',
            ),
            value: _selectedRank,
            items: QuestRank.values.map((rank) {
              return DropdownMenuItem<QuestRank>(
                value: rank,
                child: Row(
                  children: [
                    Icon(rank.icon, color: rank.color, size: 16),
                    const SizedBox(width: 8),
                    Text(rank.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedRank = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Notes field
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Quest Notes',
              border: OutlineInputBorder(),
              hintText: 'Enter any notes about the quest',
            ),
            maxLines: 3,
            textDirection: TextDirection.ltr, // Ensure left-to-right text direction
          ),
          const SizedBox(height: 16),
          
          // Submit button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedCharacterId != null) {
                    widget.onSubmit(
                      _titleController.text,
                      _selectedCharacterId!,
                      _selectedRank,
                      _notesController.text,
                    );
                  }
                },
                child: Text(widget.initialQuest == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
