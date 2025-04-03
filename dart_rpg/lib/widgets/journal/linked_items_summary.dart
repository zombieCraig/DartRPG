import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/game_provider.dart';
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
                        
                        subtitleText = moveRoll.outcome.toUpperCase();
                        
                        // Add Match indicator
                        if (moveRoll.isMatch && (moveRoll.outcome.contains('strong hit') || moveRoll.outcome.contains('miss'))) {
                          subtitleText += ' - MATCH!';
                        }
                        
                        subtitleText += ' - Action Die: ${moveRoll.actionDie}';
                        if (statInfo.isNotEmpty) {
                          subtitleText += ', $statInfo';
                        }
                        if (modifierInfo.isNotEmpty) {
                          subtitleText += ', Mod: $modifierInfo';
                        }
                        subtitleText += ' vs ${moveRoll.challengeDice.join(', ')}';
                      } else if (moveRoll.rollType == 'progress_roll') {
                        // Progress roll subtitle
                        subtitleText = moveRoll.outcome.toUpperCase();
                        
                        // Add Match indicator for progress rolls too
                        if (moveRoll.isMatch && (moveRoll.outcome.contains('strong hit') || moveRoll.outcome.contains('miss'))) {
                          subtitleText += ' - MATCH!';
                        }
                        
                        subtitleText += ' - Progress: ${moveRoll.progressValue} vs ${moveRoll.challengeDice.join(', ')}';
                      } else if (moveRoll.rollType == 'oracle_roll' && 
                                moveRoll.moveData != null && 
                                moveRoll.moveData!.containsKey('oracleResult')) {
                        // Oracle roll subtitle
                        subtitleText = 'Oracle Result: ${moveRoll.moveData!['oracleResult']}';
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
                        title: Row(
                          children: [
                            Expanded(child: Text(moveRoll.moveName)),
                            // Add a match indicator icon if applicable
                            if (moveRoll.isMatch && (moveRoll.outcome.contains('strong hit') || moveRoll.outcome.contains('miss')))
                              Icon(
                                moveRoll.outcome.contains('strong hit') ? Icons.star : Icons.warning,
                                size: 16,
                                color: moveRoll.outcome.contains('strong hit') ? Colors.green[700] : Colors.red[700],
                              ),
                          ],
                        ),
                        subtitle: Text(subtitleText),
                        dense: true,
                      onTap: () {
                        if (widget.onMoveRollTap != null) {
                          widget.onMoveRollTap!(moveRoll);
                        } else {
                          // If no tap handler is provided, show a dialog with the move details
                          _showMoveDetailsDialog(context, moveRoll);
                        }
                      },
                      );
                    }),
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
                        } else {
                          // If no tap handler is provided, show a dialog with the oracle details
                          _showOracleDetailsDialog(context, oracleRoll);
                        }
                      },
                      );
                    }),
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
    
    if (rollType == 'oracle_roll') {
      return Icons.casino;
    }
    
    // For action rolls, use outcome-based icons
    if (outcome.toLowerCase().contains('strong hit with a match')) {
      return Icons.star; // Special icon for strong hit with match
    } else if (outcome.toLowerCase().contains('strong hit')) {
      return Icons.check_circle;
    } else if (outcome.toLowerCase().contains('weak hit')) {
      return Icons.check_circle_outline;
    } else if (outcome.toLowerCase().contains('miss with a match')) {
      return Icons.warning; // Special icon for miss with match
    } else if (outcome.toLowerCase().contains('miss')) {
      return Icons.cancel;
    } else {
      return Icons.sports_martial_arts;
    }
  }
  
  Color _getOutcomeColor(String outcome) {
    if (outcome.toLowerCase().contains('strong hit with a match')) {
      return Colors.green[700]!; // Darker green for strong hit with match
    } else if (outcome.toLowerCase().contains('strong hit')) {
      return Colors.green;
    } else if (outcome.toLowerCase().contains('weak hit')) {
      return Colors.orange;
    } else if (outcome.toLowerCase().contains('miss with a match')) {
      return Colors.red[700]!; // Darker red for miss with match
    } else if (outcome.toLowerCase().contains('miss')) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
  
  // Show a dialog with move details
  void _showMoveDetailsDialog(BuildContext context, MoveRoll moveRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(moveRoll.moveName),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Outcome
                Row(
                  children: [
                    Text(
                      'Outcome: ${moveRoll.outcome.toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getOutcomeColor(moveRoll.outcome),
                      ),
                    ),
                    if (moveRoll.isMatch && 
                        (moveRoll.outcome.contains('strong hit') || moveRoll.outcome.contains('miss'))) ...[
                      const SizedBox(width: 8),
                      Icon(
                        moveRoll.outcome.contains('strong hit') ? Icons.star : Icons.warning,
                        size: 16,
                        color: moveRoll.outcome.contains('strong hit') ? Colors.green[700] : Colors.red[700],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Roll details
                if (moveRoll.rollType == 'action_roll') ...[
                  Text('Action Die: ${moveRoll.actionDie}'),
                  if (moveRoll.stat != null)
                    Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                  if (moveRoll.modifier != null && moveRoll.modifier != 0)
                    Text('Modifier: ${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}'),
                  Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                ] else if (moveRoll.rollType == 'progress_roll') ...[
                  Text('Progress Value: ${moveRoll.progressValue}'),
                  Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                ] else if (moveRoll.rollType == 'oracle_roll' && 
                           moveRoll.moveData != null && 
                           moveRoll.moveData!.containsKey('oracleResult')) ...[
                  Text(
                    'Oracle Result: ${moveRoll.moveData!['oracleResult']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Move description
                if (moveRoll.moveDescription != null) ...[
                  const Text(
                    'Move Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: moveRoll.moveDescription!,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selectable: true,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  
  // Show a dialog with oracle details
  void _showOracleDetailsDialog(BuildContext context, OracleRoll oracleRoll) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(oracleRoll.oracleName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Result: ${oracleRoll.result}'),
              Text('Dice: ${oracleRoll.dice.join(', ')}'),
              if (oracleRoll.oracleTable != null) ...[
                const SizedBox(height: 8),
                Text('Table: ${oracleRoll.oracleTable}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
