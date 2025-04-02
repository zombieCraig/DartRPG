import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dart_rpg/models/oracle.dart';
import 'package:dart_rpg/models/node_type_info.dart';
import 'package:dart_rpg/utils/logging_service.dart';

// Create a mock version of the DataswornProvider to test the getAllNodeTypes logic
class MockDataswornProvider extends ChangeNotifier {
  List<OracleCategory> _oracles = [];
  
  // Expose a setter for testing
  set oracles(List<OracleCategory> value) {
    _oracles = value;
  }
  
  List<OracleCategory> get oracles => _oracles;
  
  // Copy of the getAllNodeTypes method from DataswornProvider
  List<NodeTypeInfo> getAllNodeTypes() {
    final loggingService = LoggingService();
    final List<NodeTypeInfo> nodeTypes = [];
    
    // Log all top-level categories to help with debugging
    loggingService.debug(
      'Oracle categories: ${_oracles.map((c) => "${c.id}: ${c.name} (${c.subcategories.length} subcategories)").join(", ")}',
      tag: 'MockDataswornProvider',
    );
    
    // Method 1: Find the node_type category by ID
    try {
      final nodeTypeCategory = _oracles.firstWhere(
        (category) => category.id == 'node_type',
      );
      
      loggingService.debug(
        'Found node_type category by ID: ${nodeTypeCategory.name} with ${nodeTypeCategory.subcategories.length} subcategories',
        tag: 'MockDataswornProvider',
      );
      
      // Add all subcategories as node types
      for (final subcategory in nodeTypeCategory.subcategories) {
        // Extract the key from the subcategory ID
        final key = subcategory.id;
        
        nodeTypes.add(NodeTypeInfo(
          key: key,
          displayName: subcategory.name,
        ));
        
        loggingService.debug(
          'Added node type: ${subcategory.name} (${subcategory.id})',
          tag: 'MockDataswornProvider',
        );
      }
    } catch (e) {
      loggingService.warning(
        'No node_type category found by ID: ${e.toString()}',
        tag: 'MockDataswornProvider',
      );
      
      // Method 2: Try to find by name if ID search failed
      try {
        final nodeTypeCategory = _oracles.firstWhere(
          (category) => category.name.toLowerCase().contains('node type'),
        );
        
        loggingService.debug(
          'Found node_type category by name: ${nodeTypeCategory.name} with ${nodeTypeCategory.subcategories.length} subcategories',
          tag: 'MockDataswornProvider',
        );
        
        // Add all subcategories as node types
        for (final subcategory in nodeTypeCategory.subcategories) {
          nodeTypes.add(NodeTypeInfo(
            key: subcategory.id,
            displayName: subcategory.name,
          ));
          
          loggingService.debug(
            'Added node type: ${subcategory.name} (${subcategory.id})',
            tag: 'MockDataswornProvider',
          );
        }
      } catch (e2) {
        loggingService.warning(
          'No node_type category found by name: ${e2.toString()}',
          tag: 'MockDataswornProvider',
        );
      }
    }
    
    // Sort alphabetically by display name
    nodeTypes.sort((a, b) => a.displayName.compareTo(b.displayName));
    
    loggingService.debug(
      'Returning ${nodeTypes.length} node types',
      tag: 'MockDataswornProvider',
    );
    
    return nodeTypes;
  }
}

void main() {
  group('Node Types Tests', () {
    late MockDataswornProvider provider;

    setUp(() {
      provider = MockDataswornProvider();
    });

    test('getAllNodeTypes returns empty list when no oracles are loaded', () {
      final nodeTypes = provider.getAllNodeTypes();
      expect(nodeTypes, isEmpty);
    });

    test('getAllNodeTypes finds node types by ID', () {
      // Create a mock node_type category with subcategories
      final socialNodeType = OracleCategory(
        id: 'social',
        name: 'Social / Communications',
        description: 'Social node type',
        tables: [],
      );

      final commerceNodeType = OracleCategory(
        id: 'commerce',
        name: 'Commerce',
        description: 'Commerce node type',
        tables: [],
      );

      final nodeTypeCategory = OracleCategory(
        id: 'node_type',
        name: 'Node Types',
        description: 'Different types of nodes',
        tables: [],
        subcategories: [socialNodeType, commerceNodeType],
      );

      // Set the oracles list with our mock data
      provider.oracles = [nodeTypeCategory];

      // Get node types
      final nodeTypes = provider.getAllNodeTypes();

      // Verify results
      expect(nodeTypes.length, 2);
      expect(nodeTypes[0].key, 'commerce'); // Alphabetical order
      expect(nodeTypes[0].displayName, 'Commerce');
      expect(nodeTypes[1].key, 'social');
      expect(nodeTypes[1].displayName, 'Social / Communications');
    });

    test('getAllNodeTypes finds node types by name', () {
      // Create a mock node_type category with subcategories but different ID
      final socialNodeType = OracleCategory(
        id: 'social',
        name: 'Social / Communications',
        description: 'Social node type',
        tables: [],
      );

      final commerceNodeType = OracleCategory(
        id: 'commerce',
        name: 'Commerce',
        description: 'Commerce node type',
        tables: [],
      );

      final nodeTypeCategory = OracleCategory(
        id: 'different_id', // Different ID
        name: 'Node Types', // But correct name
        description: 'Different types of nodes',
        tables: [],
        subcategories: [socialNodeType, commerceNodeType],
      );

      // Set the oracles list with our mock data
      provider.oracles = [nodeTypeCategory];

      // Get node types
      final nodeTypes = provider.getAllNodeTypes();

      // Verify results
      expect(nodeTypes.length, 2);
      expect(nodeTypes[0].key, 'commerce'); // Alphabetical order
      expect(nodeTypes[0].displayName, 'Commerce');
      expect(nodeTypes[1].key, 'social');
      expect(nodeTypes[1].displayName, 'Social / Communications');
    });
  });
}
