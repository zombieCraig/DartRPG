import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/connection.dart';
import '../../models/quest.dart';

/// A form for creating or editing a connection
class ConnectionForm extends StatefulWidget {
  final Connection? initialConnection;
  final List<Character> characters;
  final Function(String name, String characterId, QuestRank rank, String role, String notes) onSubmit;

  const ConnectionForm({
    super.key,
    this.initialConnection,
    required this.characters,
    required this.onSubmit,
  });

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _notesController = TextEditingController();
  QuestRank _selectedRank = QuestRank.troublesome;
  String? _selectedCharacterId;

  @override
  void initState() {
    super.initState();
    if (widget.initialConnection != null) {
      _nameController.text = widget.initialConnection!.name;
      _roleController.text = widget.initialConnection!.role;
      _notesController.text = widget.initialConnection!.notes;
      _selectedRank = widget.initialConnection!.rank;
      _selectedCharacterId = widget.initialConnection!.characterId;
    } else if (widget.characters.isNotEmpty) {
      _selectedCharacterId = widget.characters.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
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
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'NPC Name',
              border: OutlineInputBorder(),
              hintText: 'Enter the NPC name',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              hintText: 'e.g. Fixer, Informant, Ally',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a role';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Hide character dropdown when editing (characterId is immutable)
          if (widget.initialConnection == null)
            ...[
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
            ],

          DropdownButtonFormField<QuestRank>(
            decoration: const InputDecoration(
              labelText: 'Rank',
              border: OutlineInputBorder(),
              hintText: 'Select connection rank',
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

          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              hintText: 'Notes about this connection...',
            ),
            maxLines: 3,
            textDirection: TextDirection.ltr,
          ),
          const SizedBox(height: 16),

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
                      _nameController.text,
                      _selectedCharacterId!,
                      _selectedRank,
                      _roleController.text,
                      _notesController.text,
                    );
                  }
                },
                child: Text(widget.initialConnection == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
