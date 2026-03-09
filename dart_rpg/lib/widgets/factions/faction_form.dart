import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/faction.dart';
import '../../providers/datasworn_provider.dart';
import 'faction_oracle_helper.dart';

/// A form for creating or editing a faction
class FactionForm extends StatefulWidget {
  final Faction? initialFaction;
  final Function(Map<String, dynamic> result) onSubmit;

  const FactionForm({
    super.key,
    this.initialFaction,
    required this.onSubmit,
  });

  @override
  State<FactionForm> createState() => _FactionFormState();
}

class _FactionFormState extends State<FactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _leadershipStyleController = TextEditingController();
  final _projectsController = TextEditingController();
  final _quirksController = TextEditingController();
  final _rumorsController = TextEditingController();
  FactionType _selectedType = FactionType.corporate;
  FactionInfluence _selectedInfluence = FactionInfluence.established;
  List<String> _subtypes = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFaction != null) {
      final f = widget.initialFaction!;
      _nameController.text = f.name;
      _descriptionController.text = f.description;
      _leadershipStyleController.text = f.leadershipStyle;
      _projectsController.text = f.projects;
      _quirksController.text = f.quirks;
      _rumorsController.text = f.rumors;
      _selectedType = f.type;
      _selectedInfluence = f.influence;
      _subtypes = List<String>.from(f.subtypes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _leadershipStyleController.dispose();
    _projectsController.dispose();
    _quirksController.dispose();
    _rumorsController.dispose();
    super.dispose();
  }

  DataswornProvider get _dataswornProvider =>
      Provider.of<DataswornProvider>(context, listen: false);

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'name': _nameController.text,
        'type': _selectedType,
        'influence': _selectedInfluence,
        'description': _descriptionController.text,
        'leadershipStyle': _leadershipStyleController.text,
        'subtypes': List<String>.from(_subtypes),
        'projects': _projectsController.text,
        'quirks': _quirksController.text,
        'rumors': _rumorsController.text,
      });
    }
  }

  Future<void> _generateAll() async {
    setState(() => _isGenerating = true);

    final provider = _dataswornProvider;

    // Roll type first (name and subtypes depend on it)
    final typeResult = FactionOracleHelper.rollFactionType(provider);
    if (typeResult != null) {
      _selectedType = typeResult['type'] as FactionType;
    }

    // Roll influence
    final influenceResult = FactionOracleHelper.rollInfluence(provider);
    if (influenceResult != null) {
      _selectedInfluence = influenceResult['influence'] as FactionInfluence;
    }

    // Roll name (uses type)
    final name = FactionOracleHelper.rollName(_selectedType, provider);
    if (name != null) _nameController.text = name;

    // Roll leadership style
    final leadership = FactionOracleHelper.rollLeadershipStyle(provider);
    if (leadership != null) _leadershipStyleController.text = leadership;

    // Roll subtypes
    _subtypes = FactionOracleHelper.rollSubtypes(_selectedType, provider);

    // Roll projects, quirks, rumors (async for oracle ref processing)
    _projectsController.text = await FactionOracleHelper.rollProjects(provider);
    _quirksController.text = await FactionOracleHelper.rollQuirks(provider);
    _rumorsController.text = await FactionOracleHelper.rollRumors(provider);

    setState(() => _isGenerating = false);
  }

  void _rollName() {
    final name = FactionOracleHelper.rollName(_selectedType, _dataswornProvider);
    if (name != null) {
      setState(() => _nameController.text = name);
    }
  }

  void _rollType() {
    final result = FactionOracleHelper.rollFactionType(_dataswornProvider);
    if (result != null) {
      setState(() {
        _selectedType = result['type'] as FactionType;
        // Auto-roll subtypes when type changes
        _subtypes = FactionOracleHelper.rollSubtypes(_selectedType, _dataswornProvider);
      });
    }
  }

  void _rollInfluence() {
    final result = FactionOracleHelper.rollInfluence(_dataswornProvider);
    if (result != null) {
      setState(() {
        _selectedInfluence = result['influence'] as FactionInfluence;
      });
    }
  }

  void _rollLeadershipStyle() {
    final result = FactionOracleHelper.rollLeadershipStyle(_dataswornProvider);
    if (result != null) {
      setState(() => _leadershipStyleController.text = result);
    }
  }

  void _rollSubtypes() {
    setState(() {
      _subtypes = FactionOracleHelper.rollSubtypes(_selectedType, _dataswornProvider);
    });
  }

  Future<void> _rollProjects() async {
    final result = await FactionOracleHelper.rollProjects(_dataswornProvider);
    if (result.isNotEmpty) {
      setState(() => _projectsController.text = result);
    }
  }

  Future<void> _rollQuirks() async {
    final result = await FactionOracleHelper.rollQuirks(_dataswornProvider);
    if (result.isNotEmpty) {
      setState(() => _quirksController.text = result);
    }
  }

  Future<void> _rollRumors() async {
    final result = await FactionOracleHelper.rollRumors(_dataswornProvider);
    if (result.isNotEmpty) {
      setState(() => _rumorsController.text = result);
    }
  }

  void _addSubtypeManually() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtype'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subtype',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _subtypes.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Random Faction" button
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateAll,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.casino),
            label: Text(_isGenerating ? 'Generating...' : 'Random Faction'),
          ),
          const SizedBox(height: 16),

          // Name
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Faction Name',
                    border: OutlineInputBorder(),
                    hintText: 'Enter the faction name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Name',
                onPressed: _rollName,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FactionType>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedType,
                  items: FactionType.values.map((type) {
                    return DropdownMenuItem<FactionType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.icon, color: type.color, size: 16),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Type',
                onPressed: _rollType,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Influence
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<FactionInfluence>(
                  decoration: const InputDecoration(
                    labelText: 'Influence',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedInfluence,
                  items: FactionInfluence.values.map((influence) {
                    return DropdownMenuItem<FactionInfluence>(
                      value: influence,
                      child: Text(influence.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInfluence = value!;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Influence',
                onPressed: _rollInfluence,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Leadership Style
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _leadershipStyleController,
                  decoration: const InputDecoration(
                    labelText: 'Leadership Style',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Oligarchical Elite',
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Leadership Style',
                onPressed: _rollLeadershipStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subtypes
          Row(
            children: [
              const Text('Subtypes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Subtype',
                onPressed: _addSubtypeManually,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Subtypes',
                onPressed: _rollSubtypes,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (_subtypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _subtypes.map((subtype) {
                  return Chip(
                    label: Text(subtype),
                    backgroundColor: _selectedType.color.withAlpha(30),
                    side: BorderSide(color: _selectedType.color.withAlpha(80)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _subtypes.remove(subtype));
                    },
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 8),

          // Projects
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _projectsController,
                  decoration: const InputDecoration(
                    labelText: 'Projects',
                    border: OutlineInputBorder(),
                    hintText: 'Current initiatives or schemes...',
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Projects',
                onPressed: _rollProjects,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quirks
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quirksController,
                  decoration: const InputDecoration(
                    labelText: 'Quirks',
                    border: OutlineInputBorder(),
                    hintText: 'Distinctive traits...',
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Quirks',
                onPressed: _rollQuirks,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rumors
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rumorsController,
                  decoration: const InputDecoration(
                    labelText: 'Rumors',
                    border: OutlineInputBorder(),
                    hintText: 'What people say...',
                  ),
                  maxLines: 3,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.casino),
                tooltip: 'Random Rumors',
                onPressed: _rollRumors,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              hintText: 'Additional notes...',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submit,
                child: Text(widget.initialFaction == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
