import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../models/location.dart';
import '../../models/network_route.dart';
import '../../models/quest.dart';

/// A form for creating or editing a network route
class RouteForm extends StatefulWidget {
  final NetworkRoute? initialRoute;
  final List<Character> characters;
  final Function(String name, String characterId, LocationSegment origin,
      LocationSegment destination, QuestRank rank, String notes) onSubmit;

  const RouteForm({
    super.key,
    this.initialRoute,
    required this.characters,
    required this.onSubmit,
  });

  @override
  State<RouteForm> createState() => _RouteFormState();
}

class _RouteFormState extends State<RouteForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  QuestRank _selectedRank = QuestRank.troublesome;
  LocationSegment _selectedOrigin = LocationSegment.core;
  LocationSegment _selectedDestination = LocationSegment.core;
  String? _selectedCharacterId;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      _nameController.text = widget.initialRoute!.name;
      _notesController.text = widget.initialRoute!.notes;
      _selectedRank = widget.initialRoute!.rank;
      _selectedOrigin = widget.initialRoute!.origin;
      _selectedDestination = widget.initialRoute!.destination;
      _selectedCharacterId = widget.initialRoute!.characterId;
    } else if (widget.characters.isNotEmpty) {
      _selectedCharacterId = widget.characters.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              labelText: 'Route Name',
              border: OutlineInputBorder(),
              hintText: 'Enter a name for this route',
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

          // Origin segment
          DropdownButtonFormField<LocationSegment>(
            decoration: const InputDecoration(
              labelText: 'Origin Segment',
              border: OutlineInputBorder(),
            ),
            value: _selectedOrigin,
            items: LocationSegment.values.map((segment) {
              return DropdownMenuItem<LocationSegment>(
                value: segment,
                child: Row(
                  children: [
                    Icon(segment.icon, color: segment.color, size: 16),
                    const SizedBox(width: 8),
                    Text(segment.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedOrigin = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Destination segment
          DropdownButtonFormField<LocationSegment>(
            decoration: const InputDecoration(
              labelText: 'Destination Segment',
              border: OutlineInputBorder(),
            ),
            value: _selectedDestination,
            items: LocationSegment.values.map((segment) {
              return DropdownMenuItem<LocationSegment>(
                value: segment,
                child: Row(
                  children: [
                    Icon(segment.icon, color: segment.color, size: 16),
                    const SizedBox(width: 8),
                    Text(segment.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDestination = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          // Hide character dropdown when editing (characterId is immutable)
          if (widget.initialRoute == null)
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
              hintText: 'Select route rank',
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
              hintText: 'Notes about this route...',
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
                      _selectedOrigin,
                      _selectedDestination,
                      _selectedRank,
                      _notesController.text,
                    );
                  }
                },
                child: Text(widget.initialRoute == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
