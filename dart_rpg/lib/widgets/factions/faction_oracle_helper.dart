import 'dart:math';
import '../../models/faction.dart';
import '../../models/oracle.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/dice_roller.dart';
import '../../utils/logging_service.dart';

/// Encapsulates all faction oracle rolling logic.
class FactionOracleHelper {
  static final _log = LoggingService();
  static final _random = Random();

  /// Rolls on the faction type oracle.
  /// Returns a map with 'type' (FactionType) and 'label' (String).
  static Map<String, dynamic>? rollFactionType(DataswornProvider provider) {
    final table = _findFactionOracle('type', provider);
    if (table == null) {
      _log.warning('Could not find faction type oracle', tag: 'FactionOracleHelper');
      return null;
    }

    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    final row = table.rows.cast<OracleTableRow?>().firstWhere(
      (r) => r!.matchesRoll(total),
      orElse: () => null,
    );
    if (row == null) return null;

    final label = row.result;
    final typeName = label.toLowerCase();
    FactionType type;
    if (typeName.contains('corporate')) {
      type = FactionType.corporate;
    } else if (typeName.contains('political')) {
      type = FactionType.political;
    } else {
      type = FactionType.underground;
    }

    return {'type': type, 'label': label};
  }

  /// Rolls on the faction influence oracle.
  /// Returns a map with 'influence' (FactionInfluence) and 'label' (String).
  static Map<String, dynamic>? rollInfluence(DataswornProvider provider) {
    final table = _findFactionOracle('influence', provider);
    if (table == null) {
      _log.warning('Could not find faction influence oracle', tag: 'FactionOracleHelper');
      return null;
    }

    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    final row = table.rows.cast<OracleTableRow?>().firstWhere(
      (r) => r!.matchesRoll(total),
      orElse: () => null,
    );
    if (row == null) return null;

    final label = row.result;
    final influenceName = label.toLowerCase();
    FactionInfluence influence = FactionInfluence.established;
    for (final value in FactionInfluence.values) {
      if (influenceName.contains(value.name)) {
        influence = value;
        break;
      }
    }

    return {'influence': influence, 'label': label};
  }

  /// Rolls on the leadership style oracle.
  static String? rollLeadershipStyle(DataswornProvider provider) {
    return _rollSingleFromFaction('leadership_style', provider);
  }

  /// Rolls a faction name based on the faction type.
  static String? rollName(FactionType type, DataswornProvider provider) {
    String tableKey;
    switch (type) {
      case FactionType.corporate:
        tableKey = 'corporate_name';
      case FactionType.political:
        tableKey = 'political_name';
      case FactionType.underground:
        tableKey = 'underground_name';
    }

    final table = _findFactionOracle(tableKey, provider);
    if (table == null) {
      _log.warning('Could not find $tableKey oracle', tag: 'FactionOracleHelper');
      return null;
    }

    final rollResult = DiceRoller.rollOracle(table.diceFormat);
    final total = rollResult['total'] as int;
    final row = table.rows.cast<OracleTableRow?>().firstWhere(
      (r) => r!.matchesRoll(total),
      orElse: () => null,
    );
    if (row == null) return null;

    // For table_text2 oracles, combine result + text2
    if (row.text2 != null && row.text2!.isNotEmpty) {
      return '${row.result} ${row.text2}';
    }
    return row.result;
  }

  /// Rolls subtypes based on faction type.
  /// Corporate: 1-3 rolls, Political: 1-2 rolls, Underground: 1 roll (with "Roll Twice" handling).
  static List<String> rollSubtypes(FactionType type, DataswornProvider provider) {
    String tableKey;
    int rollCount;
    switch (type) {
      case FactionType.corporate:
        tableKey = 'corporate';
        rollCount = _random.nextInt(3) + 1; // 1-3
      case FactionType.political:
        tableKey = 'political';
        rollCount = _random.nextInt(2) + 1; // 1-2
      case FactionType.underground:
        tableKey = 'underground';
        rollCount = 1;
    }

    final table = _findFactionOracle(tableKey, provider);
    if (table == null) {
      _log.warning('Could not find $tableKey oracle', tag: 'FactionOracleHelper');
      return [];
    }

    return _rollMultipleDeduped(table, rollCount, handleRollTwice: true);
  }

  /// Rolls on the projects oracle (1-2 times).
  static Future<String> rollProjects(DataswornProvider provider) async {
    return _rollMultipleFactionOracleText(
      'projects', provider, _random.nextInt(2) + 1,
    );
  }

  /// Rolls on the quirks oracle (1-2 times).
  static Future<String> rollQuirks(DataswornProvider provider) async {
    return _rollMultipleFactionOracleText(
      'quirks', provider, _random.nextInt(2) + 1,
    );
  }

  /// Rolls on the rumors oracle (1-2 times).
  static Future<String> rollRumors(DataswornProvider provider) async {
    return _rollMultipleFactionOracleText(
      'rumors', provider, _random.nextInt(2) + 1,
    );
  }

  /// Rolls a relationship descriptor.
  static String? rollRelationship(DataswornProvider provider) {
    return _rollSingleFromFaction('relationships', provider);
  }

  /// Rolls relationships between all factions.
  /// Returns a map of factionId -> {otherFactionId -> relationship}.
  static Map<String, Map<String, String>> rollAllRelationships(
    List<Faction> factions,
    DataswornProvider provider,
  ) {
    final result = <String, Map<String, String>>{};

    for (final faction in factions) {
      result[faction.id] = {};
    }

    // For each pair, roll a relationship
    for (int i = 0; i < factions.length; i++) {
      for (int j = i + 1; j < factions.length; j++) {
        final relationship = rollRelationship(provider);
        if (relationship != null) {
          result[factions[i].id]![factions[j].id] = relationship;
          result[factions[j].id]![factions[i].id] = relationship;
        }
      }
    }

    return result;
  }

  // --- Private helpers ---

  /// Finds an oracle table within the faction oracle category.
  /// Searches the faction category specifically to avoid collisions
  /// with identically-named tables in other categories.
  static OracleTable? _findFactionOracle(String tableKey, DataswornProvider provider) {
    for (final category in provider.oracles) {
      if (category.id == 'faction' ||
          category.id.endsWith('/faction') ||
          category.name.toLowerCase() == 'faction') {
        // Search within this faction category
        for (final table in category.tables) {
          if (table.id == tableKey) {
            return table;
          }
        }
        // Also check subcategories
        for (final sub in category.subcategories) {
          for (final table in sub.tables) {
            if (table.id == tableKey) {
              return table;
            }
          }
        }
      }
    }

    // Fallback to global search
    _log.debug(
      'Faction oracle "$tableKey" not found in faction category, falling back to global search',
      tag: 'FactionOracleHelper',
    );
    return OracleService.findOracleTableByKeyAnywhere(tableKey, provider);
  }

  /// Rolls once on a faction oracle and returns the result string.
  static String? _rollSingleFromFaction(String tableKey, DataswornProvider provider) {
    final table = _findFactionOracle(tableKey, provider);
    if (table == null) {
      _log.warning('Could not find faction/$tableKey oracle', tag: 'FactionOracleHelper');
      return null;
    }

    final rollResult = OracleService.rollOnOracleTable(table);
    if (rollResult['success'] == true) {
      return (rollResult['oracleRoll']).result as String;
    }
    return null;
  }

  /// Rolls multiple times on a table, deduplicates results.
  /// Handles "Roll Twice" entries by rolling two additional times.
  static List<String> _rollMultipleDeduped(
    OracleTable table,
    int count, {
    bool handleRollTwice = false,
  }) {
    final results = <String>{};
    int attempts = 0;
    int remaining = count;

    while (remaining > 0 && attempts < count + 10) {
      attempts++;
      final rollResult = DiceRoller.rollOracle(table.diceFormat);
      final total = rollResult['total'] as int;
      final row = table.rows.cast<OracleTableRow?>().firstWhere(
        (r) => r!.matchesRoll(total),
        orElse: () => null,
      );
      if (row == null) continue;

      final text = row.result;
      if (handleRollTwice && text.toLowerCase().contains('roll twice')) {
        // Roll two more times instead
        remaining += 1; // Add an extra roll (current one replaced by 2)
        continue;
      }

      results.add(text);
      remaining--;
    }

    return results.toList();
  }

  /// Rolls N times on a faction oracle, processes references, and joins with newlines.
  static Future<String> _rollMultipleFactionOracleText(
    String tableKey,
    DataswornProvider provider,
    int count,
  ) async {
    final table = _findFactionOracle(tableKey, provider);
    if (table == null) {
      _log.warning('Could not find faction/$tableKey oracle', tag: 'FactionOracleHelper');
      return '';
    }

    final results = <String>[];
    for (int i = 0; i < count; i++) {
      final rollResult = OracleService.rollOnOracleTable(table);
      if (rollResult['success'] == true) {
        String text = (rollResult['oracleRoll']).result as String;

        // Process any oracle references (e.g., [Action]+[Theme])
        final processResult = await OracleService.processOracleReferences(text, provider);
        if (processResult['success'] == true) {
          text = processResult['processedText'] as String;
        }

        if (!results.contains(text)) {
          results.add(text);
        }
      }
    }

    return results.join('\n');
  }
}
