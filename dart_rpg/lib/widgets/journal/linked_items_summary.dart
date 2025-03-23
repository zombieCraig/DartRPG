import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/character.dart';
import '../../models/location.dart';
import '../../models/move.dart';
import '../../models/oracle.dart';
import '../../models/journal_entry.dart';

class LinkedItemsSummary extends StatefulWidget {
  final JournalEntry journalEntry;
  final Function(String characterId)? onCharacterTap;
  final Function(String locationId)? onLocationTap;
  final Function(MoveRoll moveRoll)? onMoveRollTap;
  final Function(OracleRoll oracleRoll)? onOracleRollTap;

  const LinkedItemsSummary({
    super.key,
    required this.journalEntry,
    this.onCharacterTap,
    this.onLocationTap,
    this.onMoveRollTap,
    this.onOracleRollTap,
  });

  @override
  State<LinkedItemsSummary> createState() => _LinkedItemsSummaryState();
}

class _LinkedItemsSummaryState extends State<LinkedItemsSummary> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final currentGame = gameProvider.currentGame;
    
    if (currentGame == null) {
      return const SizedBox.shrink();
    }
    
    // Get linked characters
    final linkedCharacters = currentGame.characters
        .where((c) => widget.journalEntry.linkedCharacterIds.contains(c.id))
        .toList();
    
    // Get linked locations
    final linkedLocations = currentGame.locations
        .where((l) => widget.journalEntry.linkedLocationIds.contains(l.id))
        .toList();
    
    // Get move rolls
    final moveRolls = widget.journalEntry.moveRolls;
    
    // Get oracle rolls
    final oracleRolls = widget.journalEntry.oracleRolls;
    
    // Check if there are any linked items
    final hasLinkedItems = linkedCharacters.isNotEmpty || 
                          linkedLocations.isNotEmpty || 
                          moveRolls.isNotEmpty || 
                          oracleRolls.isNotEmpty;
    
    if (!hasLinkedItems) {
      return const SizedBox.shrink();
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.link),
                  const SizedBox(width: 8),
                  const Text(
                    'Linked Items',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${linkedCharacters.length + linkedLocations.length + moveRolls.length + oracleRolls.length} items',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          
          // Content (when expanded)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Characters
                  if (linkedCharacters.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Characters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: linkedCharacters.map((character) {
                        final handle = character.handle ?? character.getHandle();
                        return ActionChip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(handle),
                          onPressed: () {
                            if (widget.onCharacterTap != null) {
                              widget.onCharacterTap!(character.id);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Locations
                  if (linkedLocations.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Locations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: linkedLocations.map((location) {
                        return ActionChip(
                          avatar: const Icon(Icons.place, size: 16),
                          label: Text(location.name),
                          onPressed: () {
                            if (widget.onLocationTap != null) {
                              widget.onLocationTap!(location.id);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Move Rolls
                  if (moveRolls.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Move Outcomes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...moveRolls.map((moveRoll) {
                      final outcomeColor = _getOutcomeColor(moveRoll.outcome);
                      
                      String subtitleText;
                      if (moveRoll.rollType == 'action_roll') {
                        // Action roll subtitle
                        String statInfo = moveRoll.stat != null ? '${moveRoll.stat} (${moveRoll.statValue})' : '';
                        String modifierInfo = moveRoll.modifier != null && moveRoll.modifier != 0 
                            ? '${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}' 
                            : '';
                        
                        subtitleText = '${moveRoll.outcome.toUpperCase()} - Action Die: ${moveRoll.actionDie}';
                        if (statInfo.isNotEmpty) {
                          subtitleText += ', $statInfo';
                        }
                        if (modifierInfo.isNotEmpty) {
                          subtitleText += ', Mod: $modifierInfo';
                        }
                        subtitleText += ' vs ${moveRoll.challengeDice.join(', ')}';
                      } else if (moveRoll.rollType == 'progress_roll') {
                        // Progress roll subtitle
                        subtitleText = '${moveRoll.outcome.toUpperCase()} - Progress: ${moveRoll.progressValue} vs ${moveRoll.challengeDice.join(', ')}';
                      } else {
                        // No-roll move subtitle
                        subtitleText = 'Performed';
                      }
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _getRollTypeIcon(moveRoll.rollType, moveRoll.outcome),
                          color: outcomeColor,
                        ),
                        title: Text(moveRoll.moveName),
                        subtitle: Text(subtitleText),
                        dense: true,
                        onTap: () {
                          if (widget.onMoveRollTap != null) {
                            widget.onMoveRollTap!(moveRoll);
                          }
                        },
                      );
                    }).toList(),
                  ],
                  
                  // Oracle Rolls
                  if (oracleRolls.isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'Oracle Rolls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...oracleRolls.map((oracleRoll) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.casino),
                        title: Text(oracleRoll.oracleName),
                        subtitle: Text(
                          '${oracleRoll.result} (${oracleRoll.dice.join(', ')})',
                        ),
                        dense: true,
                        onTap: () {
                          if (widget.onOracleRollTap != null) {
                            widget.onOracleRollTap!(oracleRoll);
                          }
                        },
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  IconData _getRollTypeIcon(String rollType, String outcome) {
    if (rollType == 'no_roll') {
      return Icons.check_circle_outline;
    }
    
    if (rollType == 'progress_roll') {
      return Icons.trending_up;
    }
    
    // For action rolls, use outcome-based icons
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Icons.check_circle;
      case 'weak hit':
        return Icons.check_circle_outline;
      case 'miss':
        return Icons.cancel;
      default:
        return Icons.sports_martial_arts;
    }
  }
  
  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Colors.green;
      case 'weak hit':
        return Colors.orange;
      case 'miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
