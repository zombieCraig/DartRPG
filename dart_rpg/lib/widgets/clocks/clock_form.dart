import 'package:flutter/material.dart';
import '../../models/clock.dart';

/// A form for creating or editing a clock
class ClockForm extends StatefulWidget {
  /// The initial clock data (for editing)
  final Clock? initialClock;
  
  /// Callback for when the form is submitted
  final Function(String title, int segments, ClockType type) onSubmit;
  
  /// Creates a new ClockForm
  const ClockForm({
    super.key,
    this.initialClock,
    required this.onSubmit,
  });
  
  @override
  State<ClockForm> createState() => _ClockFormState();
}

class _ClockFormState extends State<ClockForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int _selectedSegments = 4;
  ClockType _selectedType = ClockType.campaign;
  
  // Available segment options
  final List<int> _segmentOptions = [4, 6, 8, 10];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with the initial clock data if provided
    if (widget.initialClock != null) {
      _titleController.text = widget.initialClock!.title;
      _selectedSegments = widget.initialClock!.segments;
      _selectedType = widget.initialClock!.type;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
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
              labelText: 'Clock Title',
              border: OutlineInputBorder(),
              hintText: 'Enter the clock title',
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
          
          // Segments dropdown
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(
              labelText: 'Segments',
              border: OutlineInputBorder(),
              hintText: 'Select number of segments',
            ),
            value: _selectedSegments,
            items: _segmentOptions.map((segments) {
              return DropdownMenuItem<int>(
                value: segments,
                child: Text('$segments segments'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSegments = value!;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select number of segments';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Clock type dropdown
          DropdownButtonFormField<ClockType>(
            decoration: const InputDecoration(
              labelText: 'Clock Type',
              border: OutlineInputBorder(),
              hintText: 'Select a clock type',
            ),
            value: _selectedType,
            items: ClockType.values.map((type) {
              return DropdownMenuItem<ClockType>(
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
            validator: (value) {
              if (value == null) {
                return 'Please select a clock type';
              }
              return null;
            },
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
                  if (_formKey.currentState!.validate()) {
                    widget.onSubmit(
                      _titleController.text,
                      _selectedSegments,
                      _selectedType,
                    );
                  }
                },
                child: Text(widget.initialClock == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
