import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/oracle.dart';
import '../utils/dice_roller.dart';

class OraclesScreen extends StatefulWidget {
  const OraclesScreen({super.key});

  @override
  State<OraclesScreen> createState() => _OraclesScreenState();
}

class _OraclesScreenState extends State<OraclesScreen> {
  String? _selectedCategoryId;
  OracleTable? _selectedTable;
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<DataswornProvider, GameProvider>(
      builder: (context, dataswornProvider, gameProvider, _) {
        final categories = dataswornProvider.oracles;
        
        if (categories.isEmpty) {
          return const Center(
            child: Text('No oracle categories available'),
          );
        }
        
        return Column(
          children: [
            // Category selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Oracle Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategoryId,
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedTable = null;
                  });
                },
              ),
            ),
            
            // Oracle list or details
            Expanded(
              child: _selectedTable != null
                  ? _buildOracleDetails(_selectedTable!)
                  : _selectedCategoryId != null
                      ? _buildOracleList(_getSelectedCategory(categories))
                      : const Center(
                          child: Text('Select an oracle category to begin'),
                        ),
            ),
          ],
        );
      },
    );
  }
  
  OracleCategory? _getSelectedCategory(List<OracleCategory> categories) {
    if (_selectedCategoryId == null) return null;
    try {
      return categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (e) {
      return null;
    }
  }
  
  Widget _buildOracleList(OracleCategory? category) {
    if (category == null) {
      return const Center(
        child: Text('Category not found'),
      );
    }
    
    final tables = category.tables;
    if (tables.isEmpty) {
      return const Center(
        child: Text('No oracle tables in this category'),
      );
    }
    
    final sortedTables = List<OracleTable>.from(tables)..sort((a, b) => a.name.compareTo(b.name));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTables.length,
      itemBuilder: (context, index) {
        final table = sortedTables[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(table.name),
            subtitle: Text(
              table.description ?? 'No description available',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.casino),
              tooltip: 'Roll on this oracle',
              onPressed: () {
                _rollOnOracle(context, table);
              },
            ),
            onTap: () {
              setState(() {
                _selectedTable = table;
              });
            },
          ),
        );
      },
    );
  }
  
  Widget _buildOracleDetails(OracleTable table) {
    return Column(
      children: [
        // Header with back button and roll button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Oracles'),
                onPressed: () {
                  setState(() {
                    _selectedTable = null;
                  });
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.casino),
                label: const Text('Roll'),
                onPressed: () {
                  _rollOnOracle(context, table);
                },
              ),
            ],
          ),
        ),
        
        // Oracle name and description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                table.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (table.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  table.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Oracle table
        Expanded(
          child: table.rows.isEmpty
              ? const Center(
                  child: Text('This oracle has no table entries'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: table.rows.length,
                  itemBuilder: (context, index) {
                    final row = table.rows[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Roll range
                            SizedBox(
                              width: 60,
                              child: Text(
                                row.minRoll == row.maxRoll
                                    ? '${row.minRoll}'
                                    : '${row.minRoll}-${row.maxRoll}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            
                            // Result
                            Expanded(
                              child: Text(row.result),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  void _rollOnOracle(BuildContext context, OracleTable table) {
    if (table.rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This oracle has no table entries'),
        ),
      );
      return;
    }
    
    // Roll on the oracle
    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    
    // Find the matching table entry
    OracleTableRow? matchingRow;
    for (final row in table.rows) {
      if (row.matchesRoll(total)) {
        matchingRow = row;
        break;
      }
    }
    
    if (matchingRow == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No result found for roll: $total'),
        ),
      );
      return;
    }
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${table.name} Result'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roll: $total'),
              const SizedBox(height: 16),
              Text(
                matchingRow!.result,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
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
                _rollOnOracle(context, table);
              },
              child: const Text('Roll Again'),
            ),
          ],
        );
      },
    );
  }
}
