import 'package:flutter_test/flutter_test.dart';
import 'package:dart_rpg/utils/datasworn_parser.dart';

void main() {
  group('DataswornParser', () {
    test('parseOracles handles categories with collections', () {
      // Create a mock JSON structure that mimics the structure of the actual JSON file
      final mockJson = {
        'oracles': {
          'regular_category': {
            'name': 'Regular Category',
            'type': 'oracle_collection',
            'summary': 'A regular category with contents',
            'contents': {
              'table1': {
                'type': 'oracle_rollable',
                'name': 'Table 1',
                'summary': 'A regular table',
                'oracle_type': 'table_text',
                'dice': '1d6',
                'rows': [
                  {
                    'roll': {'min': 1, 'max': 3},
                    'text': 'Result 1'
                  },
                  {
                    'roll': {'min': 4, 'max': 6},
                    'text': 'Result 2'
                  }
                ]
              }
            }
          },
          'collection_category': {
            'name': 'Collection Category',
            'type': 'oracle_collection',
            'summary': 'A category with collections',
            'collections': {
              'subcategory1': {
                'name': 'Subcategory 1',
                'type': 'oracle_collection',
                'summary': 'A subcategory',
                'contents': {
                  'table2': {
                    'type': 'oracle_rollable',
                    'name': 'Table 2',
                    'summary': 'A table in a subcategory',
                    'oracle_type': 'table_text',
                    'dice': '1d6',
                    'rows': [
                      {
                        'roll': {'min': 1, 'max': 3},
                        'text': 'Result A'
                      },
                      {
                        'roll': {'min': 4, 'max': 6},
                        'text': 'Result B'
                      }
                    ]
                  }
                }
              }
            }
          },
          'node_type': {
            'name': 'Node Types',
            'type': 'oracle_collection',
            'summary': 'Different types of nodes',
            'collections': {
              'science': {
                'name': 'Science & Research',
                'type': 'oracle_collection',
                'summary': 'Science and research nodes',
                'contents': {
                  'area': {
                    'type': 'oracle_rollable',
                    'name': 'Area',
                    'summary': 'Science area',
                    'oracle_type': 'table_text',
                    'dice': '1d6',
                    'rows': [
                      {
                        'roll': {'min': 1, 'max': 3},
                        'text': 'Lab'
                      },
                      {
                        'roll': {'min': 4, 'max': 6},
                        'text': 'Research Center'
                      }
                    ]
                  },
                  'feature': {
                    'type': 'oracle_rollable',
                    'name': 'Feature',
                    'summary': 'Science feature',
                    'oracle_type': 'table_text',
                    'dice': '1d6',
                    'rows': [
                      {
                        'roll': {'min': 1, 'max': 3},
                        'text': 'Equipment'
                      },
                      {
                        'roll': {'min': 4, 'max': 6},
                        'text': 'Data'
                      }
                    ]
                  },
                  'peril': {
                    'type': 'oracle_rollable',
                    'name': 'Peril',
                    'summary': 'Science peril',
                    'oracle_type': 'table_text',
                    'dice': '1d6',
                    'rows': [
                      {
                        'roll': {'min': 1, 'max': 3},
                        'text': 'Experiment gone wrong'
                      },
                      {
                        'roll': {'min': 4, 'max': 6},
                        'text': 'Data breach'
                      }
                    ]
                  },
                  'opportunity': {
                    'type': 'oracle_rollable',
                    'name': 'Opportunity',
                    'summary': 'Science opportunity',
                    'oracle_type': 'table_text',
                    'dice': '1d6',
                    'rows': [
                      {
                        'roll': {'min': 1, 'max': 3},
                        'text': 'New discovery'
                      },
                      {
                        'roll': {'min': 4, 'max': 6},
                        'text': 'Valuable research'
                      }
                    ]
                  }
                }
              }
            }
          }
        }
      };

      // Parse the oracles
      final categories = DataswornParser.parseOracles(mockJson);

      // Verify that the regular category was parsed correctly
      expect(categories.length, equals(3));
      
      // Find the regular category
      final regularCategory = categories.firstWhere((c) => c.id == 'regular_category');
      expect(regularCategory.name, equals('Regular Category'));
      expect(regularCategory.tables.length, equals(1));
      expect(regularCategory.tables[0].name, equals('Table 1'));
      
      // Find the collection category
      final collectionCategory = categories.firstWhere((c) => c.id == 'collection_category');
      expect(collectionCategory.name, equals('Collection Category'));
      expect(collectionCategory.subcategories.length, equals(1));
      expect(collectionCategory.subcategories[0].name, equals('Subcategory 1'));
      expect(collectionCategory.subcategories[0].tables.length, equals(1));
      expect(collectionCategory.subcategories[0].tables[0].name, equals('Table 2'));
      
      // Find the node_type category
      final nodeTypeCategory = categories.firstWhere((c) => c.id == 'node_type');
      expect(nodeTypeCategory.name, equals('Node Types'));
      expect(nodeTypeCategory.subcategories.length, equals(1));
      
      // Verify the Science & Research subcategory
      final scienceCategory = nodeTypeCategory.subcategories.firstWhere((c) => c.id == 'science');
      expect(scienceCategory.name, equals('Science & Research'));
      expect(scienceCategory.tables.length, equals(4));
      
      // Verify the tables in the Science & Research subcategory
      final areaTable = scienceCategory.tables.firstWhere((t) => t.id == 'area');
      expect(areaTable.name, equals('Area'));
      expect(areaTable.rows.length, equals(2));
      
      final featureTable = scienceCategory.tables.firstWhere((t) => t.id == 'feature');
      expect(featureTable.name, equals('Feature'));
      expect(featureTable.rows.length, equals(2));
      
      final perilTable = scienceCategory.tables.firstWhere((t) => t.id == 'peril');
      expect(perilTable.name, equals('Peril'));
      expect(perilTable.rows.length, equals(2));
      
      final opportunityTable = scienceCategory.tables.firstWhere((t) => t.id == 'opportunity');
      expect(opportunityTable.name, equals('Opportunity'));
      expect(opportunityTable.rows.length, equals(2));
    });
  });
}
