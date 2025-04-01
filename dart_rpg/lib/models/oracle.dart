class OracleTableRow {
  final int minRoll;
  final int maxRoll;
  final String result;

  OracleTableRow({
    required this.minRoll,
    required this.maxRoll,
    required this.result,
  });

  factory OracleTableRow.fromJson(Map<String, dynamic> json) {
    return OracleTableRow(
      minRoll: json['minRoll'],
      maxRoll: json['maxRoll'],
      result: json['result'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minRoll': minRoll,
      'maxRoll': maxRoll,
      'result': result,
    };
  }

  // Check if a roll falls within this row's range
  bool matchesRoll(int roll) {
    return roll >= minRoll && roll <= maxRoll;
  }
}

class OracleTable {
  final String id;
  final String name;
  final String? description;
  final List<OracleTableRow> rows;
  final String diceFormat; // e.g., "1d100", "2d10", etc.

  OracleTable({
    required this.id,
    required this.name,
    this.description,
    required this.rows,
    required this.diceFormat,
  });

  factory OracleTable.fromJson(Map<String, dynamic> json) {
    return OracleTable(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rows: (json['rows'] as List)
          .map((r) => OracleTableRow.fromJson(r))
          .toList(),
      diceFormat: json['diceFormat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rows': rows.map((r) => r.toJson()).toList(),
      'diceFormat': diceFormat,
    };
  }

  // Get the result for a specific roll
  String getResult(int roll) {
    for (final row in rows) {
      if (row.matchesRoll(roll)) {
        return row.result;
      }
    }
    return 'No result found for roll: $roll';
  }

  // Parse an oracle table from the Datasworn JSON format
  factory OracleTable.fromDatasworn(Map<String, dynamic> json, String tableId) {
    final String name = json['name'] ?? 'Unknown Oracle';
    final String? description = json['summary'];
    
    List<OracleTableRow> rows = [];
    String diceFormat = '1d100'; // Default
    
    if (json['oracle_type'] == 'table_text' && json['rows'] != null) {
      rows = (json['rows'] as List).map((rowJson) {
        final roll = rowJson['roll'];
        return OracleTableRow(
          minRoll: roll['min'],
          maxRoll: roll['max'],
          result: rowJson['text'] ?? '',
        );
      }).toList();
      
      // Try to determine dice format
      if (json['dice'] != null) {
        diceFormat = json['dice'];
      } else if (rows.isNotEmpty) {
        final maxValue = rows.map((r) => r.maxRoll).reduce((a, b) => a > b ? a : b);
        if (maxValue <= 6) {
          diceFormat = '1d6';
        } else if (maxValue <= 10) {
          diceFormat = '1d10';
        } else if (maxValue <= 12) {
          diceFormat = '1d12';
        } else if (maxValue <= 20) {
          diceFormat = '1d20';
        } else if (maxValue <= 100) {
          diceFormat = '1d100';
        }
      }
    }

    return OracleTable(
      id: tableId,
      name: name,
      description: description,
      rows: rows,
      diceFormat: diceFormat,
    );
  }
}

class OracleCategory {
  final String id;
  final String name;
  final String? description;
  final List<OracleTable> tables;
  final List<OracleCategory> subcategories;
  final bool isNodeType; // Flag to identify if this is a node type collection

  OracleCategory({
    required this.id,
    required this.name,
    this.description,
    required this.tables,
    this.subcategories = const [],
    this.isNodeType = false,
  });

  factory OracleCategory.fromJson(Map<String, dynamic> json) {
    return OracleCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      tables: (json['tables'] as List)
          .map((t) => OracleTable.fromJson(t))
          .toList(),
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List)
              .map((c) => OracleCategory.fromJson(c))
              .toList()
          : [],
      isNodeType: json['isNodeType'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tables': tables.map((t) => t.toJson()).toList(),
      'subcategories': subcategories.map((c) => c.toJson()).toList(),
      'isNodeType': isNodeType,
    };
  }

  // Parse an oracle category from the Datasworn JSON format
  factory OracleCategory.fromDatasworn(Map<String, dynamic> json, String categoryId) {
    final String name = json['name'] ?? 'Unknown Category';
    final String? description = json['summary'];
    
    List<OracleTable> tables = [];
    List<OracleCategory> subcategories = [];
    
    if (json['contents'] != null) {
      json['contents'].forEach((contentId, contentJson) {
        if (contentJson['type'] == 'oracle_rollable') {
          tables.add(OracleTable.fromDatasworn(contentJson, contentId));
        } else if (contentJson['type'] == 'oracle_collection') {
          // This is a subcategory
          subcategories.add(OracleCategory.fromDatasworn(contentJson, contentId));
        }
      });
    }

    return OracleCategory(
      id: categoryId,
      name: name,
      description: description,
      tables: tables,
      subcategories: subcategories,
    );
  }
  
  // Get all tables from this category and its subcategories
  List<OracleTable> getAllTables() {
    List<OracleTable> allTables = List.from(tables);
    for (final subcategory in subcategories) {
      allTables.addAll(subcategory.getAllTables());
    }
    return allTables;
  }
}
