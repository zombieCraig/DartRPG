import '../utils/logging_service.dart';

class OracleTableRow {
  final int minRoll;
  final int maxRoll;
  final String result;
  final String? text2; // Additional information for table_text2 oracle type

  OracleTableRow({
    required this.minRoll,
    required this.maxRoll,
    required this.result,
    this.text2, // Optional field
  });

  factory OracleTableRow.fromJson(Map<String, dynamic> json) {
    return OracleTableRow(
      minRoll: json['minRoll'],
      maxRoll: json['maxRoll'],
      result: json['result'],
      text2: json['text2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minRoll': minRoll,
      'maxRoll': maxRoll,
      'result': result,
      'text2': text2,
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
  final String? text2Label; // Label for the text2 column in table_text2 oracle type
  final String? oracleType; // Type of oracle table (table_text, table_text2, etc.)

  OracleTable({
    required this.id,
    required this.name,
    this.description,
    required this.rows,
    required this.diceFormat,
    this.text2Label,
    this.oracleType,
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
      text2Label: json['text2Label'],
      oracleType: json['oracleType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'rows': rows.map((r) => r.toJson()).toList(),
      'diceFormat': diceFormat,
      'text2Label': text2Label,
      'oracleType': oracleType,
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
    final String oracleType = json['oracle_type'] ?? 'table_text';
    String? text2Label;
    
    // Add logging to debug text2 display issue
    final loggingService = LoggingService();
    loggingService.debug(
      'OracleTable.fromDatasworn: tableId=$tableId, name=$name, oracleType=$oracleType',
      tag: 'OracleTable',
    );
    
    List<OracleTableRow> rows = [];
    String diceFormat = '1d100'; // Default
    
    // Extract column labels if present
    if (json['column_labels'] != null) {
      final columnLabels = json['column_labels'];
      loggingService.debug(
        'OracleTable.fromDatasworn: columnLabels=${columnLabels.toString()}',
        tag: 'OracleTable',
      );
      
      if (columnLabels['text2'] != null) {
        text2Label = columnLabels['text2'];
        loggingService.debug(
          'OracleTable.fromDatasworn: text2Label=$text2Label',
          tag: 'OracleTable',
        );
      }
    } else {
      loggingService.debug(
        'OracleTable.fromDatasworn: No column_labels found in JSON',
        tag: 'OracleTable',
      );
    }
    
    // Handle both table_text and table_text2 oracle types
    if ((oracleType == 'table_text' || oracleType == 'table_text2') && json['rows'] != null) {
      rows = (json['rows'] as List).map((rowJson) {
        final roll = rowJson['roll'];
        final String result = rowJson['text'] ?? '';
        final String? text2Value = rowJson['text2'];
        
        // Log the text2 value for debugging
        loggingService.debug(
          'OracleTable.fromDatasworn: row text2=$text2Value',
          tag: 'OracleTable',
        );
        
        return OracleTableRow(
          minRoll: roll['min'],
          maxRoll: roll['max'],
          result: result,
          text2: text2Value,
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

    final table = OracleTable(
      id: tableId,
      name: name,
      description: description,
      rows: rows,
      diceFormat: diceFormat,
      text2Label: text2Label,
      oracleType: oracleType,
    );
    
    // Log the created table
    loggingService.debug(
      'OracleTable.fromDatasworn: Created table with id=$tableId, oracleType=${table.oracleType}, text2Label=${table.text2Label}, rows=${table.rows.length}',
      tag: 'OracleTable',
    );
    
    return table;
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
