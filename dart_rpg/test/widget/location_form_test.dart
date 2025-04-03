import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dart_rpg/models/location.dart';
import 'package:dart_rpg/models/node_type_info.dart';
import 'package:dart_rpg/providers/datasworn_provider.dart';
import 'package:dart_rpg/widgets/locations/location_form.dart';

// Mock DataswornProvider for testing
class MockDataswornProvider extends ChangeNotifier implements DataswornProvider {
  List<NodeTypeInfo> _nodeTypes = [];
  
  @override
  List<NodeTypeInfo> getAllNodeTypes() => _nodeTypes;
  
  void setNodeTypes(List<NodeTypeInfo> nodeTypes) {
    _nodeTypes = nodeTypes;
    notifyListeners();
  }
  
  // Implement required methods from DataswornProvider
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LocationForm Widget Tests', () {
    late MockDataswornProvider mockDataswornProvider;
    
    setUp(() {
      mockDataswornProvider = MockDataswornProvider();
    });
    
    testWidgets('LocationForm shows disabled node type field when no node types available', 
        (WidgetTester tester) async {
      // Set up empty node types
      mockDataswornProvider.setNodeTypes([]);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DataswornProvider>.value(
              value: mockDataswornProvider,
              child: LocationForm(
                validSegments: LocationSegment.values,
                onSave: (name, description, segment, imageUrl, nodeType) {},
              ),
            ),
          ),
        ),
      );
      
      // Verify that a disabled text field is shown
      expect(find.text('No node types available'), findsOneWidget);
      
      // Verify that the random buttons exist
      expect(find.text('Random Segment Location'), findsOneWidget);
      expect(find.text('Random Any Node Type'), findsOneWidget);
    });
    
    testWidgets('LocationForm shows dropdown when node types are available', 
        (WidgetTester tester) async {
      // Set up node types
      mockDataswornProvider.setNodeTypes([
        const NodeTypeInfo(key: 'social', displayName: 'Social / Communications'),
        const NodeTypeInfo(key: 'commerce', displayName: 'Commerce'),
      ]);
      
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DataswornProvider>.value(
              value: mockDataswornProvider,
              child: LocationForm(
                validSegments: LocationSegment.values,
                onSave: (name, description, segment, imageUrl, nodeType) {},
              ),
            ),
          ),
        ),
      );
      
      // Verify that a dropdown is shown
      expect(find.byType(DropdownButtonFormField<NodeTypeInfo>), findsOneWidget);
      
      // Verify that the random buttons exist
      expect(find.text('Random Segment Location'), findsOneWidget);
      expect(find.text('Random Any Node Type'), findsOneWidget);
    });
  });
}
