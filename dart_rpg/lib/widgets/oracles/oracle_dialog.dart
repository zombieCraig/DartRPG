import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/logging_service.dart';
import 'oracle_category_list.dart';
import 'oracle_table_list.dart';
import 'oracle_result_view.dart';

/// A dialog for selecting and rolling on oracle tables.
class OracleDialog {
  /// Shows a dialog for selecting and rolling on oracle tables.
  /// 
  /// The [onOracleRollAdded] callback is called when an oracle roll is added to the journal entry.
  /// The [onInsertText] callback is called when text should be inserted at the cursor position.
  static void show(
    BuildContext context, {
    required Function(OracleRoll oracleRoll) onOracleRollAdded,
    required Function(String text) onInsertText,
    required bool isEditing,
  }) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer<DataswornProvider>(
              builder: (context, dataswornProvider, _) {
                final categories = dataswornProvider.oracles;
                
                if (categories.isEmpty) {
                  return AlertDialog(
                    title: const Text('Oracle Tables'),
                    content: const Center(
                      child: Text('No oracle categories available'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                }
                
                // Filter oracles by search query if provided
                List<OracleTable> filteredTables = [];
                if (searchQuery.isNotEmpty) {
                  for (final category in categories) {
                    // Add tables from this category
                    filteredTables.addAll(
                      category.tables.where((table) => 
                        table.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (table.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                      )
                    );
                    
                    // Add tables from subcategories
                    if (category.subcategories.isNotEmpty) {
                      for (final subcategory in category.subcategories) {
                        filteredTables.addAll(
                          subcategory.tables.where((table) => 
                            table.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                            (table.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                          )
                        );
                      }
                    }
                  }
                }
                
                return AlertDialog(
                  title: const Text('Oracle Tables'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 500,
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Oracles',
                              hintText: 'Enter oracle name or description',
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                          ),
                        ),
                        
                        // Oracle list
                        Expanded(
                          child: searchQuery.isNotEmpty
                              ? OracleTableList(
                                  tables: filteredTables,
                                  onTableSelected: (table) {
                                    _rollOnOracleTable(
                                      context,
                                      table,
                                      onOracleRollAdded,
                                      onInsertText,
                                      isEditing,
                                    );
                                  },
                                )
                              : OracleCategoryList(
                                  categories: categories,
                                  onTableSelected: (table) {
                                    _rollOnOracleTable(
                                      context,
                                      table,
                                      onOracleRollAdded,
                                      onInsertText,
                                      isEditing,
                                    );
                                  },
                                ),
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
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Rolls on an oracle table and shows the result.
  static void _rollOnOracleTable(
    BuildContext context,
    OracleTable table,
    Function(OracleRoll oracleRoll) onOracleRollAdded,
    Function(String text) onInsertText,
    bool isEditing,
  ) async {
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
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    
    // Check if the result contains oracle references
    final processResult = await OracleService.processOracleReferences(
      oracleRoll.result,
      dataswornProvider,
    );
    
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
          // Log the result for debugging
          final loggingService = LoggingService();
          loggingService.debug(
            'Oracle result: ${oracleRoll.result}',
            tag: 'OracleDialog',
          );
          
          return OracleResultView(
            table: table,
            oracleRoll: oracleRoll,
            onClose: () {
              Navigator.pop(context);
            },
            onRollAgain: () {
              Navigator.pop(context);
              _rollOnOracleTable(
                context,
                table,
                onOracleRollAdded,
                onInsertText,
                isEditing,
              );
            },
            onAddToJournal: (roll) {
              // Add the oracle roll to the journal entry
              onOracleRollAdded(roll);
              
              // Insert the oracle roll text at the cursor position
              if (isEditing) {
                final formattedText = roll.getFormattedText();
                onInsertText(formattedText);
              }
              
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Oracle roll added to journal entry'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          );
        },
      );
    }
  }
}
