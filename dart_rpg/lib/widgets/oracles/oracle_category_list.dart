import 'package:flutter/material.dart';
import '../../models/oracle.dart';
import '../../services/oracle_service.dart';

/// A widget for displaying a list of oracle categories.
class OracleCategoryList extends StatelessWidget {
  final List<OracleCategory> categories;
  final Function(OracleTable) onTableSelected;
  
  const OracleCategoryList({
    super.key,
    required this.categories,
    required this.onTableSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text('No oracle categories available'),
      );
    }
    
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryColor = OracleService.getCategoryColor(category.name);
        
        return ExpansionTile(
          title: Text(category.name),
          subtitle: category.description != null
              ? Text(
                  category.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          leading: Icon(
            Icons.category,
            color: categoryColor,
          ),
          children: [
            // Subcategories
            if (category.subcategories.isNotEmpty)
              ...category.subcategories.map((subcategory) => 
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ExpansionTile(
                    title: Text(subcategory.name),
                    subtitle: subcategory.description != null
                        ? Text(
                            subcategory.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    leading: Icon(
                      Icons.subdirectory_arrow_right,
                      color: categoryColor.withAlpha(179), // 0.7 opacity = 179 alpha
                    ),
                    children: [
                      ...subcategory.tables.map((table) => 
                        ListTile(
                          title: Text(table.name),
                          subtitle: table.description != null
                              ? Text(
                                  table.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          leading: const Icon(Icons.table_chart),
                          trailing: IconButton(
                            icon: const Icon(Icons.casino),
                            tooltip: 'Roll on this oracle',
                            onPressed: () => onTableSelected(table),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Tables in this category
            ...category.tables.map((table) => 
              ListTile(
                title: Text(table.name),
                subtitle: table.description != null
                    ? Text(
                        table.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                leading: const Icon(Icons.table_chart),
                trailing: IconButton(
                  icon: const Icon(Icons.casino),
                  tooltip: 'Roll on this oracle',
                  onPressed: () => onTableSelected(table),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
