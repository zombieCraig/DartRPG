import 'package:flutter/material.dart';
import '../../models/oracle.dart';

/// A widget for displaying a list of oracle tables.
class OracleTableList extends StatelessWidget {
  final List<OracleTable> tables;
  final Function(OracleTable) onTableSelected;
  
  const OracleTableList({
    super.key,
    required this.tables,
    required this.onTableSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return const Center(
        child: Text('No matching oracle tables found'),
      );
    }
    
    final sortedTables = List<OracleTable>.from(tables)..sort((a, b) => a.name.compareTo(b.name));
    
    return ListView.builder(
      itemCount: sortedTables.length,
      itemBuilder: (context, index) {
        final table = sortedTables[index];
        
        return ListTile(
          title: Text(table.name),
          subtitle: table.description != null
              ? Text(
                  table.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.casino),
            tooltip: 'Roll on this oracle',
            onPressed: () => onTableSelected(table),
          ),
        );
      },
    );
  }
}
