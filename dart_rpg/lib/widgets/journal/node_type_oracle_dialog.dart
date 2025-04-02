import 'package:flutter/material.dart';
import '../../providers/datasworn_provider.dart';
import '../../models/location.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart'; // Import for OracleRoll
import '../../utils/logging_service.dart';
import '../../services/oracle_service.dart';

/// A dialog that displays oracle options for a specific node type.
class NodeTypeOracleDialog extends StatefulWidget {
  /// The location with the node type.
  final Location location;

  /// The datasworn provider to use for oracle data.
  final DataswornProvider dataswornProvider;

  /// Callback for when an oracle roll is added.
  final Function(OracleRoll oracleRoll)? onOracleRollAdded;

  /// Callback for when text should be inserted at the cursor.
  final Function(String text)? onInsertText;

  /// Creates a new NodeTypeOracleDialog.
  const NodeTypeOracleDialog({
    super.key,
    required this.location,
    required this.dataswornProvider,
    this.onOracleRollAdded,
    this.onInsertText,
  });

  @override
  State<NodeTypeOracleDialog> createState() => _NodeTypeOracleDialogState();
}

class _NodeTypeOracleDialogState extends State<NodeTypeOracleDialog> {
  List<OracleTable>? _oracleTables;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOracleTables();
  }

  /// Loads oracle tables for the location's node type.
  Future<void> _loadOracleTables() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.location.nodeType == null || widget.location.nodeType!.isEmpty) {
        throw Exception('Location does not have a node type');
      }

      // Find the node type category
      final nodeTypeKey = widget.location.nodeType!;
      final loggingService = LoggingService();
      
      loggingService.debug(
        'Looking for oracle tables for node type: $nodeTypeKey',
        tag: 'NodeTypeOracleDialog',
      );

      // Find the node type category in the oracles
      OracleCategory? nodeTypeCategory;
      
      // First try to find the node_type category
      try {
        final nodeTypeMainCategory = widget.dataswornProvider.oracles.firstWhere(
          (category) => category.id == 'node_type' || category.name.toLowerCase().contains('node type'),
        );
        
        loggingService.debug(
          'Found node_type category: ${nodeTypeMainCategory.name} with ${nodeTypeMainCategory.subcategories.length} subcategories',
          tag: 'NodeTypeOracleDialog',
        );
        
        // Find the specific node type subcategory
        nodeTypeCategory = nodeTypeMainCategory.subcategories.firstWhere(
          (subcategory) => subcategory.id == nodeTypeKey,
          orElse: () => throw Exception('Node type subcategory not found: $nodeTypeKey'),
        );
        
        loggingService.debug(
          'Found node type subcategory: ${nodeTypeCategory.name} with ${nodeTypeCategory.tables.length} tables and ${nodeTypeCategory.subcategories.length} subcategories',
          tag: 'NodeTypeOracleDialog',
        );
      } catch (e) {
        loggingService.warning(
          'Error finding node type category: ${e.toString()}',
          tag: 'NodeTypeOracleDialog',
        );
        throw Exception('Could not find node type category: ${e.toString()}');
      }

      // Get all tables from the node type category
      final allTables = nodeTypeCategory.getAllTables();
      
      loggingService.debug(
        'Found ${allTables.length} tables for node type: $nodeTypeKey',
        tag: 'NodeTypeOracleDialog',
      );
      
      // Filter for the standard oracle tables (area, feature, peril, opportunity)
      final standardTableNames = ['area', 'feature', 'peril', 'opportunity'];
      
      // Try to find tables that contain these standard names
      final standardTables = allTables.where((table) {
        final tableName = table.name.toLowerCase();
        return standardTableNames.any((name) => tableName.contains(name));
      }).toList();
      
      loggingService.debug(
        'Found ${standardTables.length} standard tables for node type: $nodeTypeKey',
        tag: 'NodeTypeOracleDialog',
      );
      
      // If we didn't find any standard tables, use all tables
      _oracleTables = standardTables.isNotEmpty ? standardTables : allTables;
      
      // Sort tables by name
      _oracleTables!.sort((a, b) => a.name.compareTo(b.name));
      
      loggingService.debug(
        'Using ${_oracleTables!.length} tables for node type: $nodeTypeKey',
        tag: 'NodeTypeOracleDialog',
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      LoggingService().error(
        'Error loading oracle tables: ${e.toString()}',
        tag: 'NodeTypeOracleDialog',
        error: e,
        stackTrace: StackTrace.current,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Rolls on an oracle table and handles the result.
  void _rollOnOracleTable(OracleTable table) {
    // Use the OracleService to roll on the table
    final result = OracleService.rollOnOracleTable(table);
    
    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']),
        ),
      );
      return;
    }
    
    final oracleRoll = result['oracleRoll'] as OracleRoll;
    
    // Process nested oracle references
    OracleService.processOracleReferences(
      oracleRoll.result,
      widget.dataswornProvider,
    ).then((processResult) {
      if (processResult['success']) {
        final processedText = processResult['processedText'] as String;
        final nestedRolls = processResult['nestedRolls'] as List<OracleRoll>;
        
        // Update the oracle roll with the processed text and nested rolls
        oracleRoll.result = processedText;
        oracleRoll.nestedRolls.addAll(nestedRolls);
      }
      
      // Show the result
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('${table.name} Result'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Roll: ${oracleRoll.dice.join(', ')}'),
                    const SizedBox(height: 16),
                    Text(
                      'Result: ${oracleRoll.result}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _rollOnOracleTable(table);
                  },
                  child: const Text('Roll Again'),
                ),
                TextButton(
                  onPressed: () {
                    // Add the oracle roll to the journal entry
                    if (widget.onOracleRollAdded != null) {
                      widget.onOracleRollAdded!(oracleRoll);
                    }
                    
                    // Insert the oracle roll text at the cursor position
                    if (widget.onInsertText != null) {
                      final formattedText = '**${table.name}**: ${oracleRoll.result}\n';
                      widget.onInsertText!(formattedText);
                    }
                    
                    Navigator.pop(context);
                    Navigator.pop(context); // Close both dialogs
                    
                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Oracle roll added to journal entry'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Add to Journal'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.location.name} Oracles'),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_oracleTables == null || _oracleTables!.isEmpty) {
      return const Center(
        child: Text('No oracle tables found for this node type.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _oracleTables!.length,
      itemBuilder: (context, index) {
        final table = _oracleTables![index];
        return ListTile(
          leading: const Icon(Icons.casino),
          title: Text(table.name),
          onTap: () {
            _rollOnOracleTable(table);
          },
        );
      },
    );
  }
}
