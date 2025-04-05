import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/oracle.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';
import '../widgets/oracle_result_text.dart';

class OracleCategoryScreen extends StatelessWidget {
  final OracleCategory category;
  
  const OracleCategoryScreen({super.key, required this.category});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Display subcategories if any
          if (category.subcategories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Subcategories',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            ...category.subcategories.map((subcategory) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(subcategory.name),
                subtitle: subcategory.description != null
                    ? Text(
                        subcategory.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OracleCategoryScreen(category: subcategory),
                    ),
                  );
                },
              ),
            )),
            
            if (category.tables.isNotEmpty)
              const Divider(height: 32),
          ],
          
          // Display tables if any
          if (category.tables.isNotEmpty) ...[
            if (category.subcategories.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Tables',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ...category.tables.map((table) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(table.name),
                subtitle: table.description != null
                    ? Text(
                        table.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.casino),
                  tooltip: 'Roll on this oracle',
                  onPressed: () {
                    _rollOnOracleFromCategory(context, table);
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OracleTableScreen(table: table),
                    ),
                  );
                },
              ),
            )),
          ],
          
          // Show a message if no content
          if (category.tables.isEmpty && category.subcategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No oracle tables or subcategories available'),
              ),
            ),
        ],
      ),
    );
  }
  
  void _rollOnOracleFromCategory(BuildContext context, OracleTable table) {
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
    
    // We've already checked that matchingRow is not null above
    final row = matchingRow;
    
    // Log the result for debugging
    final loggingService = LoggingService();
    loggingService.debug(
      'Oracle result: ${row.result}, text2: ${row.text2}',
      tag: 'OracleCategoryScreen',
    );
    
    // Show the result using OracleResultDialog
    showDialog(
      context: context,
      builder: (context) {
        return OracleResultDialog(
          table: table,
          roll: total,
          result: row.result,
          text2: row.text2,
        );
      },
    );
  }
}

class OracleTableScreen extends StatelessWidget {
  final OracleTable table;
  
  const OracleTableScreen({super.key, required this.table});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(table.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino),
            tooltip: 'Roll on this oracle',
            onPressed: () {
              _rollOnOracleTable(context, table);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Oracle description
          if (table.description != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                table.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
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
                                    child: OracleResultText(
                                      text: row.result,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Display text2 if available
                              if (row.text2 != null && table.text2Label != null) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 60.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${table.text2Label}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      OracleResultText(
                                        text: row.text2!,
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  void _rollOnOracleTable(BuildContext context, OracleTable table) {
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
    
    // We've already checked that matchingRow is not null above
    final row = matchingRow;
    
    // Log the result for debugging
    final loggingService = LoggingService();
    loggingService.debug(
      'Oracle result: ${row.result}, text2: ${row.text2}',
      tag: 'OracleTableScreen',
    );
    
    // Show the result using OracleResultDialog
    showDialog(
      context: context,
      builder: (context) {
        return OracleResultDialog(
          table: table,
          roll: total,
          result: row.result,
          text2: row.text2,
        );
      },
    );
  }
}

class OraclesScreen extends StatefulWidget {
  const OraclesScreen({super.key});

  @override
  State<OraclesScreen> createState() => _OraclesScreenState();
}

class _OraclesScreenState extends State<OraclesScreen> {
  OracleTable? _selectedTable;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
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
        
        // Filter oracles by search query if provided
        List<OracleTable> filteredTables = [];
        if (_searchQuery.isNotEmpty) {
          for (final category in categories) {
            // Add tables from this category
            filteredTables.addAll(
              category.tables.where((table) => 
                table.name.toLowerCase().contains(_searchQuery) ||
                (table.description?.toLowerCase().contains(_searchQuery) ?? false)
              )
            );
            
            // Add tables from subcategories
            if (category.subcategories.isNotEmpty) {
              for (final subcategory in category.subcategories) {
                filteredTables.addAll(
                  subcategory.tables.where((table) => 
                    table.name.toLowerCase().contains(_searchQuery) ||
                    (table.description?.toLowerCase().contains(_searchQuery) ?? false)
                  )
                );
              }
            }
          }
        }
        
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Oracles',
                  hintText: 'Enter oracle name or description',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
            
            // Oracle list or details
            Expanded(
              child: _selectedTable != null
                  ? _buildOracleDetails(_selectedTable!)
                  : _searchQuery.isNotEmpty
                      ? _buildOracleTableList(filteredTables)
                      : _buildExpandableCategoryList(categories),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildExpandableCategoryList(List<OracleCategory> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        
        // Determine if we can roll on this category
        final bool canRoll = category.tables.isNotEmpty;
        
        // Get a rollable table from this category or its subcategories
        OracleTable? getRollableTable() {
          if (category.tables.isNotEmpty) {
            return category.tables.first;
          }
          
          // Try to find a table in subcategories
          for (final subcategory in category.subcategories) {
            if (subcategory.tables.isNotEmpty) {
              return subcategory.tables.first;
            }
          }
          
          return null;
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(category.name),
            subtitle: category.description != null
                ? Text(
                    category.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: canRoll
                ? IconButton(
                    icon: const Icon(Icons.casino),
                    tooltip: 'Roll on this category',
                    onPressed: () {
                      final table = getRollableTable();
                      if (table != null) {
                        _rollOnOracle(context, table);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No rollable tables found in this category'),
                          ),
                        );
                      }
                    },
                  )
                : const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Navigate to the oracle list for this category
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OracleCategoryScreen(category: category),
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildOracleTableList(List<OracleTable> tables) {
    if (tables.isEmpty) {
      return const Center(
        child: Text('No matching oracle tables found'),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                  child: OracleResultText(
                                    text: row.result,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Display text2 if available
                            if (row.text2 != null && table.text2Label != null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 60.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${table.text2Label}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    OracleResultText(
                                      text: row.text2!,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    
    // We've already checked that matchingRow is not null above
    final row = matchingRow;
    
    // Log the result for debugging
    final loggingService = LoggingService();
    loggingService.debug(
      'Oracle result: ${row.result}, text2: ${row.text2}',
      tag: 'OraclesScreen',
    );
    
    // Show the result using OracleResultDialog
    showDialog(
      context: context,
      builder: (context) {
        return OracleResultDialog(
          table: table,
          roll: total,
          result: row.result,
          text2: row.text2,
        );
      },
    );
  }
}
