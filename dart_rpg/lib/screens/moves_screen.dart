import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/move.dart';
import '../models/character.dart';
import '../models/journal_entry.dart';
import '../utils/dice_roller.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  String? _selectedCategory;
  Move? _selectedMove;
  final TextEditingController _modifierController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _progressValue = 5; // Default progress value for progress rolls
  String? _selectedStat; // Selected stat for action rolls
  
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
    _modifierController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<DataswornProvider, GameProvider>(
      builder: (context, dataswornProvider, gameProvider, _) {
        final moves = dataswornProvider.moves;
        
        // Group moves by move_category instead of category
        final categories = <String>{};
        final movesByCategory = <String, List<Move>>{};
        
        for (final move in moves) {
          final category = move.moveCategory ?? move.category ?? 'Uncategorized';
          categories.add(category);
          
          if (!movesByCategory.containsKey(category)) {
            movesByCategory[category] = [];
          }
          
          movesByCategory[category]!.add(move);
        }
        
        final sortedCategories = categories.toList()..sort();
        
        // Filter moves by search query if provided
        List<Move> filteredMoves = [];
        if (_searchQuery.isNotEmpty) {
          for (final category in movesByCategory.keys) {
            filteredMoves.addAll(
              movesByCategory[category]!.where((move) => 
                move.name.toLowerCase().contains(_searchQuery) ||
                (move.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                (move.trigger?.toLowerCase().contains(_searchQuery) ?? false)
              )
            );
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
                  labelText: 'Search Moves',
                  hintText: 'Enter move name or description',
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
            
            // Category selector (only shown when not searching)
            if (_searchQuery.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Move Category',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategory,
                  items: sortedCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedMove = null;
                    });
                  },
                ),
              ),
            
            // Move list or details
            Expanded(
              child: _selectedMove != null
                  ? _buildMoveDetails(_selectedMove!)
                  : _searchQuery.isNotEmpty
                      ? _buildMoveList(filteredMoves)
                      : _selectedCategory != null && movesByCategory.containsKey(_selectedCategory)
                          ? _buildMoveList(movesByCategory[_selectedCategory]!)
                          : const Center(
                              child: Text('Select a move category or search for moves'),
                            ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMoveList(List<Move> moves) {
    final sortedMoves = List<Move>.from(moves)..sort((a, b) => a.name.compareTo(b.name));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMoves.length,
      itemBuilder: (context, index) {
        final move = sortedMoves[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(move.name),
            subtitle: Text(
              move.trigger ?? move.description ?? 'No description available',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Use a person kicking icon instead of casino
            trailing: Tooltip(
              message: _getRollTypeTooltip(move.rollType),
              child: Icon(
                _getRollTypeIcon(move.rollType),
                color: _getRollTypeColor(move.rollType),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedMove = move;
                _selectedStat = null; // Reset selected stat when selecting a new move
              });
            },
          ),
        );
      },
    );
  }
  
  IconData _getRollTypeIcon(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return Icons.sports_martial_arts; // Person kicking icon
      case 'progress_roll':
        return Icons.trending_up;
      case 'no_roll':
        return Icons.check_circle_outline;
      default:
        return Icons.sports_martial_arts;
    }
  }
  
  Color _getRollTypeColor(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return Colors.blue;
      case 'progress_roll':
        return Colors.green;
      case 'no_roll':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
  
  String _getRollTypeTooltip(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return 'Action Roll';
      case 'progress_roll':
        return 'Progress Roll';
      case 'no_roll':
        return 'No Roll Required';
      default:
        return 'Move';
    }
  }
  
  Widget _buildMoveDetails(Move move) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Moves'),
            onPressed: () {
              setState(() {
                _selectedMove = null;
                _selectedStat = null;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Move name and roll type icon
          Row(
            children: [
              Expanded(
                child: Text(
                  move.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Icon(
                _getRollTypeIcon(move.rollType),
                color: _getRollTypeColor(move.rollType),
                size: 32,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Move category
          if (move.moveCategory != null || move.category != null) ...[
            Text(
              move.moveCategory ?? move.category!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Move trigger
          if (move.trigger != null) ...[
            Text(
              move.trigger!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Move description
          if (move.description != null) ...[
            Text(
              move.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
          ],
          
          // Outcomes
          if (move.outcomes.isNotEmpty) ...[
            const Text(
              'Outcomes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...move.outcomes.map((outcome) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      outcome.type.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(outcome.description),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Different UI based on roll type
          if (move.rollType == 'action_roll') ...[
            _buildActionRollUI(move),
          ] else if (move.rollType == 'progress_roll') ...[
            _buildProgressRollUI(move),
          ] else if (move.rollType == 'no_roll') ...[
            _buildNoRollUI(move),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActionRollUI(Move move) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    final availableStats = move.getAvailableStats();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat selection
        const Text(
          'Select Stat:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableStats.map((stat) {
            // Get the stat value from the character if available
            int statValue = 2; // Default value
            if (character != null) {
              final characterStat = character.stats.firstWhere(
                (s) => s.name.toLowerCase() == stat.toLowerCase(),
                orElse: () => CharacterStat(name: stat, value: 2),
              );
              statValue = characterStat.value;
            }
            
            return ChoiceChip(
              label: Text('$stat ($statValue)'),
              selected: _selectedStat == stat,
              onSelected: (selected) {
                setState(() {
                  _selectedStat = selected ? stat : null;
                });
              },
            );
          }).toList(),
        ),
        
        // Only show modifier field if a stat is selected
        if (_selectedStat != null) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _modifierController,
            decoration: const InputDecoration(
              labelText: 'Optional Modifier',
              hintText: 'e.g., +2, -1',
              helperText: 'One-time adjustment to Action Score',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
          ),
          
          const SizedBox(height: 16),
          
          // Roll button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sports_martial_arts),
              label: const Text('Roll Dice'),
              onPressed: () {
                _rollActionMove(context, move);
              },
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildProgressRollUI(Move move) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Progress:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Progress slider
        Slider(
          value: _progressValue.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _progressValue.toString(),
          onChanged: (value) {
            setState(() {
              _progressValue = value.round();
            });
          },
        ),
        
        // Progress value indicator
        Center(
          child: Text(
            'Progress: $_progressValue',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Roll button
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.trending_up),
            label: const Text('Perform Move'),
            onPressed: () {
              _rollProgressMove(context, move);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildNoRollUI(Move move) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Perform Move'),
        onPressed: () {
          _performNoRollMove(context, move);
        },
      ),
    );
  }
  
  void _rollActionMove(BuildContext context, Move move) {
    if (_selectedStat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a stat first'),
        ),
      );
      return;
    }
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    
    // Get the stat value from the character if available
    int statValue = 2; // Default value
    if (character != null) {
      final characterStat = character.stats.firstWhere(
        (s) => s.name.toLowerCase() == _selectedStat!.toLowerCase(),
        orElse: () => CharacterStat(name: _selectedStat!, value: 2),
      );
      statValue = characterStat.value;
    }
    
    // Get the character's momentum
    final momentum = character?.momentum ?? 2;
    
    // Parse the optional modifier
    int modifier = 0;
    if (_modifierController.text.isNotEmpty) {
      modifier = int.tryParse(_modifierController.text) ?? 0;
    }
    
    // Roll with momentum and modifier
    final rollResult = DiceRoller.rollMove(
      statValue: statValue,
      momentum: momentum,
      modifier: modifier,
    );
    
    // Create a MoveRoll object for the journal entry
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      stat: _selectedStat,
      statValue: statValue,
      actionDie: rollResult['actionDie'],
      challengeDice: rollResult['challengeDice'],
      outcome: rollResult['outcome'],
      rollType: 'action_roll',
      modifier: modifier,
      moveData: {'moveId': move.id},
    );
    
    // Show the roll result
    _showRollResultDialog(context, move, rollResult, moveRoll);
  }
  
  void _rollProgressMove(BuildContext context, Move move) {
    // Roll for progress move
    final rollResult = DiceRoller.rollProgressMove(progressValue: _progressValue);
    
    // Create a MoveRoll object for the journal entry
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      actionDie: 0, // No action die for progress moves
      challengeDice: rollResult['challengeDice'],
      outcome: rollResult['outcome'],
      rollType: 'progress_roll',
      progressValue: _progressValue,
      moveData: {'moveId': move.id},
    );
    
    // Show the roll result
    _showRollResultDialog(context, move, rollResult, moveRoll);
  }
  
  void _performNoRollMove(BuildContext context, Move move) {
    // Create a MoveRoll object for the journal entry
    final moveRoll = MoveRoll(
      moveName: move.name,
      moveDescription: move.description,
      actionDie: 0, // No action die for no-roll moves
      challengeDice: [], // No challenge dice for no-roll moves
      outcome: 'performed', // Custom outcome for no-roll moves
      rollType: 'no_roll',
      moveData: {'moveId': move.id},
    );
    
    // Show a simple dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(move.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (move.description != null) ...[
                Text(move.description!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Move performed successfully',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                _addMoveToJournal(context, moveRoll);
              },
              child: const Text('Add to Journal'),
            ),
          ],
        );
      },
    );
  }
  
  void _showRollResultDialog(BuildContext context, Move move, Map<String, dynamic> rollResult, MoveRoll moveRoll) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${move.name} Roll'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (moveRoll.rollType == 'action_roll') ...[
                    Row(
                      children: [
                        Text(
                          'Action Die: ${rollResult['actionDie']}',
                          style: rollResult['actionDieCanceled'] == true
                              ? const TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.lineThrough,
                                )
                              : null,
                        ),
                        if (rollResult['actionDieCanceled'] == true) ...[
                          const SizedBox(width: 8),
                          const Text(
                            '(Canceled by negative momentum)',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    if (moveRoll.stat != null) ...[
                      Text('Stat: ${moveRoll.stat} (${moveRoll.statValue})'),
                      const SizedBox(height: 4),
                    ],
                    
                    if (moveRoll.modifier != null && moveRoll.modifier != 0) ...[
                      Text('Modifier: ${moveRoll.modifier! > 0 ? '+' : ''}${moveRoll.modifier}'),
                      const SizedBox(height: 4),
                    ],
                    
                    Text('Total Action Value: ${rollResult['actionValue']}'),
                    const SizedBox(height: 8),
                  ],
                  
                  if (moveRoll.rollType == 'progress_roll') ...[
                    Text('Progress Value: ${moveRoll.progressValue}'),
                    const SizedBox(height: 8),
                  ],
                  
                  if (moveRoll.challengeDice.isNotEmpty) ...[
                    Text('Challenge Dice: ${moveRoll.challengeDice.join(' and ')}'),
                    const SizedBox(height: 16),
                  ],
                  
                  // Momentum information
                  if (rollResult.containsKey('momentum') && moveRoll.rollType == 'action_roll') ...[
                    Text('Current Momentum: ${rollResult['momentum']}'),
                    const SizedBox(height: 8),
                  ],
                  
                  // Outcome
                  Text(
                    'Outcome: ${moveRoll.outcome.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getOutcomeColor(moveRoll.outcome),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Find the matching outcome description
                  if (moveRoll.outcome != 'performed') ...[
                    for (final outcome in move.outcomes)
                      if (outcome.type == moveRoll.outcome)
                        Text(outcome.description),
                  ],
                  
                  // Burn Momentum button
                  if (rollResult['couldBurnMomentum'] == true && 
                      character != null && 
                      moveRoll.rollType == 'action_roll') ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.local_fire_department),
                        label: Text('Burn Momentum (${character.momentum})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () {
                          // Calculate new result with burned momentum
                          final newActionValue = character.momentum;
                          
                          // Determine new outcome
                          final challengeDice = moveRoll.challengeDice;
                          final strongHit = newActionValue > challengeDice[0] && newActionValue > challengeDice[1];
                          final weakHit = (newActionValue > challengeDice[0] && newActionValue <= challengeDice[1]) ||
                                          (newActionValue <= challengeDice[0] && newActionValue > challengeDice[1]);
                          
                          String newOutcome;
                          if (strongHit) newOutcome = 'strong hit';
                          else if (weakHit) newOutcome = 'weak hit';
                          else newOutcome = 'miss';
                          
                          // Burn momentum
                          character.burnMomentum();
                          
                          // Update the moveRoll
                          moveRoll.outcome = newOutcome;
                          
                          // Update the UI
                          setState(() {
                            rollResult['actionValue'] = newActionValue;
                            rollResult['outcome'] = newOutcome;
                            rollResult['momentumBurned'] = true;
                            rollResult['couldBurnMomentum'] = false;
                            rollResult['momentum'] = character.momentum;
                          });
                          
                          // Save the game
                          gameProvider.saveGame();
                        },
                      ),
                    ),
                  ],
                  
                  // Momentum burned indicator
                  if (rollResult['momentumBurned'] == true) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Momentum has been burned!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('New Momentum: ${rollResult['momentum']}'),
                  ],
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
                    _addMoveToJournal(context, moveRoll);
                  },
                  child: const Text('Add to Journal'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (moveRoll.rollType == 'action_roll') {
                      _rollActionMove(context, move);
                    } else if (moveRoll.rollType == 'progress_roll') {
                      _rollProgressMove(context, move);
                    } else {
                      _performNoRollMove(context, move);
                    }
                  },
                  child: const Text('Roll Again'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _addMoveToJournal(BuildContext context, MoveRoll moveRoll) {
    // Show a snackbar to indicate the move was added to the journal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${moveRoll.moveName} added to journal'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to the journal entry screen
            // This would be implemented in a real app
          },
        ),
      ),
    );
  }
  
  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'strong hit':
        return Colors.green;
      case 'weak hit':
        return Colors.orange;
      case 'miss':
        return Colors.red;
      case 'performed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
