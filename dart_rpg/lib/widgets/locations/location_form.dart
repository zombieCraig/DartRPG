import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location.dart';
import '../../models/node_type_info.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/logging_service.dart';

/// A form for creating or editing a location
class LocationForm extends StatefulWidget {
  /// The initial location data (for editing)
  final Location? initialLocation;
  
  /// The list of valid segments that can be selected
  final List<LocationSegment> validSegments;
  
  /// List of available locations to connect to (optional)
  final List<Location>? availableConnections;
  
  /// Callback when the form is saved
  final Function(String name, String? description, LocationSegment segment, String? imageUrl, String? nodeType, String? connectionId) onSave;
  
  /// Creates a new LocationForm
  const LocationForm({
    super.key,
    this.initialLocation,
    required this.validSegments,
    this.availableConnections,
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
  NodeTypeInfo? _selectedNodeType;
  String? _selectedConnectionId;
  final LoggingService _loggingService = LoggingService();
  List<NodeTypeInfo> _nodeTypes = [];
  
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get node types from DataswornProvider
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    _nodeTypes = dataswornProvider.getAllNodeTypes();
    
    _loggingService.debug(
      'Fetched ${_nodeTypes.length} node types from DataswornProvider',
      tag: 'LocationForm',
    );
    
    // Initialize selected node type if available
    if (widget.initialLocation?.nodeType != null) {
      _selectedNodeType = NodeTypeUtils.findNodeTypeByKey(
        _nodeTypes,
        widget.initialLocation!.nodeType!,
      );
      
      if (_selectedNodeType == null) {
        _loggingService.warning(
          'Could not find node type with key: ${widget.initialLocation!.nodeType}',
          tag: 'LocationForm',
        );
      }
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  
  /// Roll for a random node type based on the selected segment
  void _rollSegmentNodeType(BuildContext context) {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    // Get the oracle table ID for the selected segment
    final oracleTableId = NodeTypeUtils.getSegmentNodeTypeOracleId(_selectedSegment);
    
    // Find the oracle table
    final oracleTable = dataswornProvider.findOracleTableById(oracleTableId);
    
    if (oracleTable == null) {
      _loggingService.error(
        'Oracle table not found: $oracleTableId',
        tag: 'LocationForm',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the appropriate oracle table for this segment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Roll on the oracle table
    final rollResult = OracleService.rollOnOracleTable(oracleTable);
    
    if (!rollResult['success']) {
      _loggingService.error(
        'Failed to roll on oracle table: ${rollResult['error']}',
        tag: 'LocationForm',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to roll on oracle: ${rollResult['error']}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get the result
    final oracleRoll = rollResult['oracleRoll'];
    final result = oracleRoll.result;
    
    _loggingService.debug(
      'Rolled on oracle table $oracleTableId: $result',
      tag: 'LocationForm',
    );
    
    // Try to find a matching node type
    for (final nodeType in _nodeTypes) {
      if (result.toLowerCase().contains(nodeType.key.toLowerCase()) ||
          result.toLowerCase().contains(nodeType.displayName.toLowerCase())) {
        setState(() {
          _selectedNodeType = nodeType;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rolled node type: ${nodeType.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
    }
    
    // If no match found, log an error
    _loggingService.error(
      'Could not match oracle result to a node type: $result',
      tag: 'LocationForm',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not determine a node type from the oracle result'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  /// Roll for a random node type from any category
  void _rollAnyNodeType() {
    final nodeType = NodeTypeUtils.getRandomNodeType(_nodeTypes);
    
    if (nodeType != null) {
      setState(() {
        _selectedNodeType = nodeType;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected random node type: ${nodeType.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No node types available to select from'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
          const SizedBox(height: 16),
          
          // Node Type selector
          _nodeTypes.isEmpty
              ? TextFormField(
                  enabled: false,
                  initialValue: 'No node types available',
                  decoration: const InputDecoration(
                    labelText: 'Node Type (optional)',
                    border: OutlineInputBorder(),
                  ),
                )
              : DropdownButtonFormField<NodeTypeInfo>(
                  value: _selectedNodeType,
                  decoration: const InputDecoration(
                    labelText: 'Node Type (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _nodeTypes.map((nodeType) {
                    return DropdownMenuItem<NodeTypeInfo>(
                      value: nodeType,
                      child: Text(nodeType.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedNodeType = value;
                    });
                  },
                ),
          
          // Connection selector (only shown when creating a new location and connections are available)
          if (widget.initialLocation == null && widget.availableConnections != null && widget.availableConnections!.isNotEmpty) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedConnectionId,
              decoration: const InputDecoration(
                labelText: 'Connect to (optional)',
                hintText: 'Select a location to connect to',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.availableConnections!.map((location) {
                  return DropdownMenuItem<String>(
                    value: location.id,
                    // Use a simpler layout to avoid flex layout issues
                    child: Text(
                      '${location.name} (${location.segment.displayName})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedConnectionId = value;
                });
              },
            ),
          ],
          
          // Random buttons
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Check if we're on a small screen (e.g., mobile)
              final isSmallScreen = MediaQuery.of(context).size.width <= 600;
              
              if (isSmallScreen) {
                // Stack buttons vertically on small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Random Segment Location button
                    Tooltip(
                      message: _nodeTypes.isEmpty 
                          ? 'No node types available' 
                          : 'Random Segment Location: Roll for a node type appropriate for this segment',
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.casino, size: 16),
                        label: const Text('Random Segment Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _nodeTypes.isEmpty ? null : () => _rollSegmentNodeType(context),
                      ),
                    ),
                    
                    const SizedBox(height: 8), // Add spacing between buttons
                    
                    // Random Any Node Type button
                    Tooltip(
                      message: _nodeTypes.isEmpty 
                          ? 'No node types available' 
                          : 'Random Any Node Type: Roll for any node type regardless of segment',
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shuffle, size: 16),
                        label: const Text('Random Any Node Type'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _nodeTypes.isEmpty ? null : () => _rollAnyNodeType(),
                      ),
                    ),
                  ],
                );
              } else {
                // Side by side buttons on larger screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Random Segment Location button
                    Flexible(
                      flex: 1,
                      child: Tooltip(
                        message: _nodeTypes.isEmpty 
                            ? 'No node types available' 
                            : 'Random Segment Location: Roll for a node type appropriate for this segment',
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.casino, size: 16),
                          label: const Text('Segment Type'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _nodeTypes.isEmpty ? null : () => _rollSegmentNodeType(context),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8), // Add spacing between buttons
                    
                    // Random Any Node Type button
                    Flexible(
                      flex: 1,
                      child: Tooltip(
                        message: _nodeTypes.isEmpty 
                            ? 'No node types available' 
                            : 'Random Any Node Type: Roll for any node type regardless of segment',
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.shuffle, size: 16),
                          label: const Text('Any Type'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _nodeTypes.isEmpty ? null : () => _rollAnyNodeType(),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          
          // Save button
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(
                      _nameController.text,
                      _descriptionController.text.isEmpty ? null : _descriptionController.text,
                      _selectedSegment,
                      _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
                      _selectedNodeType?.key,
                      _selectedConnectionId,
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
