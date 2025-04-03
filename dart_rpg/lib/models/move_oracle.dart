import 'oracle.dart';

/// Represents an oracle embedded within a move.
class MoveOracle {
  final String key;
  final String name;
  final Map<String, dynamic>? match;
  final String oracleType;
  final List<OracleTableRow> rows;
  final String dice;
  final String id;

  MoveOracle({
    required this.key,
    required this.name,
    this.match,
    required this.oracleType,
    required this.rows,
    required this.dice,
    required this.id,
  });

  /// Creates a MoveOracle from a JSON object and its key.
  factory MoveOracle.fromJson(String key, Map<String, dynamic> json) {
    // Parse rows from the JSON
    final List<OracleTableRow> rows = [];
    if (json['rows'] != null) {
      for (final rowJson in json['rows']) {
        rows.add(OracleTableRow(
          minRoll: rowJson['roll']['min'],
          maxRoll: rowJson['roll']['max'],
          result: rowJson['text'] ?? '',
          text2: null, // Embedded oracles typically don't have text2
        ));
      }
    }

    return MoveOracle(
      key: key,
      name: json['name'] ?? 'Unknown Oracle',
      match: json['match'],
      oracleType: json['oracle_type'] ?? 'column_text',
      rows: rows,
      dice: json['dice'] ?? '1d100',
      id: json['_id'] ?? '',
    );
  }

  /// Gets the match text if available.
  String? get matchText => match != null ? match!['text'] : null;

  /// Converts this MoveOracle to an OracleTable for use with the existing oracle system.
  OracleTable toOracleTable() {
    return OracleTable(
      id: id,
      name: name,
      description: matchText,
      rows: rows,
      diceFormat: dice,
      text2Label: null,
      oracleType: oracleType,
    );
  }
}
