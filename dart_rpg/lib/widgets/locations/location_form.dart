import 'package:flutter/material.dart';
import '../../models/location.dart';

/// A form for creating or editing a location
class LocationForm extends StatefulWidget {
  /// The initial location data (for editing)
  final Location? initialLocation;
  
  /// The list of valid segments that can be selected
  final List<LocationSegment> validSegments;
  
  /// Callback when the form is saved
  final Function(String name, String? description, LocationSegment segment, String? imageUrl) onSave;
  
  /// Creates a new LocationForm
  const LocationForm({
    super.key,
    this.initialLocation,
    required this.validSegments,
    required this.onSave,
  });

  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late LocationSegment _selectedSegment;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with initial values if provided
    _nameController = TextEditingController(text: widget.initialLocation?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialLocation?.description ?? '');
    _imageUrlController = TextEditingController(text: widget.initialLocation?.imageUrl ?? '');
    
    // Initialize selected segment
    _selectedSegment = widget.initialLocation?.segment ?? 
                      (widget.validSegments.contains(LocationSegment.core) 
                        ? LocationSegment.core 
                        : widget.validSegments.first);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter location name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a name';
              }
              return null;
            },
            autofocus: widget.initialLocation == null, // Autofocus on name field for new locations
          ),
          const SizedBox(height: 16),
          
          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter location description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Image URL field
          TextFormField(
            controller: _imageUrlController,
            decoration: const InputDecoration(
              labelText: 'Image URL (optional)',
              hintText: 'Enter URL to location image',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Segment selector
          DropdownButtonFormField<LocationSegment>(
            value: _selectedSegment,
            decoration: const InputDecoration(
              labelText: 'Segment',
              border: OutlineInputBorder(),
            ),
            items: widget.validSegments.map((segment) {
              return DropdownMenuItem<LocationSegment>(
                value: segment,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: segment.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(segment.displayName),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSegment = value;
                });
              }
            },
          ),
          
          // Save button
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(
                      _nameController.text,
                      _descriptionController.text.isEmpty ? null : _descriptionController.text,
                      _selectedSegment,
                      _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
                    );
                  }
                },
                child: Text(widget.initialLocation == null ? 'Create' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
