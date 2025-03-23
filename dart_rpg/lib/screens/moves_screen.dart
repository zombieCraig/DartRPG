import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/move.dart';
import '../models/character.dart';
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
        
        // Group moves by category
        final categories = <String>{};
        final movesByCategory = <String, List<Move>>{};
        
        for (final move in moves) {
          final category = move.category ?? 'Uncategorized';
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
                (move.description?.toLowerCase().contains(_searchQuery) ?? false)
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
            onTap: () {
              setState(() {
                _selectedMove = move;
              });
            },
          ),
        );
      },
    );
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
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Move name
          Text(
            move.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          
          const SizedBox(height: 8),
          
          // Move category
          if (move.category != null) ...[
            Text(
              move.category!,
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
          
          // Optional modifier field for action moves
          if (move.stat != null && !move.isProgressMove) ...[
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
          ],
          
          // Roll button
          if (move.stat != null || move.isProgressMove)
            ElevatedButton.icon(
              icon: const Icon(Icons.casino),
              label: Text('Roll ${move.isProgressMove ? "Progress" : "Action"} Move'),
              onPressed: () {
                _rollForMove(context, move);
                // Clear the modifier after rolling
                _modifierController.clear();
              },
            ),
        ],
      ),
    );
  }
  
  void _rollForMove(BuildContext context, Move move) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    
    // Determine which dice to roll based on the move type
    Map<String, dynamic> rollResult;
    
    if (move.isProgressMove) {
      // For progress moves, we'll use a default progress value of 3
      // In a real app, this would come from the character's progress track
      rollResult = DiceRoller.rollProgressMove(progressValue: 3);
    } else {
      // For action moves, we'll use the character's stat if available
      int? statValue;
      
      // Get the stat value from the character if possible
      if (character != null && move.stat != null) {
        final stat = character.stats.firstWhere(
          (s) => s.name.toLowerCase() == move.stat!.toLowerCase(),
          orElse: () => CharacterStat(name: move.stat!, value: 2),
        );
        statValue = stat.value;
      } else {
        statValue = 2; // Default stat value
      }
      
      // Get the character's momentum
      final momentum = character?.momentum ?? 2;
      
      // Parse the optional modifier
      int modifier = 0;
      if (_modifierController.text.isNotEmpty) {
        modifier = int.tryParse(_modifierController.text) ?? 0;
      }
      
      // Roll with momentum and modifier
      rollResult = DiceRoller.rollMove(
        statValue: statValue,
        momentum: momentum,
        modifier: modifier,
      );
    }
    
    // Show the roll result
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
                  if (rollResult.containsKey('actionDie')) ...[
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
                  ],
                  
                  if (rollResult.containsKey('statValue') && rollResult['statValue'] != null) ...[
                    Text('Stat Value: ${rollResult['statValue']}'),
                    const SizedBox(height: 4),
                  ],
                  
                  if (rollResult.containsKey('modifier') && rollResult['modifier'] != 0) ...[
                    Text('Modifier: ${rollResult['modifier'] > 0 ? '+' : ''}${rollResult['modifier']}'),
                    const SizedBox(height: 4),
                  ],
                  
                  if (rollResult.containsKey('actionValue')) ...[
                    Text('Total Action Value: ${rollResult['actionValue']}'),
                    const SizedBox(height: 8),
                  ],
                  
                  if (rollResult.containsKey('progressValue')) ...[
                    Text('Progress Value: ${rollResult['progressValue']}'),
                    const SizedBox(height: 8),
                  ],
                  
                  if (rollResult.containsKey('challengeDice')) ...[
                    Text('Challenge Dice: ${rollResult['challengeDice'][0]} and ${rollResult['challengeDice'][1]}'),
                    const SizedBox(height: 16),
                  ],
                  
                  // Momentum information
                  if (rollResult.containsKey('momentum') && !move.isProgressMove) ...[
                    Text('Current Momentum: ${rollResult['momentum']}'),
                    const SizedBox(height: 8),
                  ],
                  
                  // Outcome
                  if (rollResult.containsKey('outcome')) ...[
                    Text(
                      'Outcome: ${rollResult['outcome'].toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Find the matching outcome description
                  if (rollResult.containsKey('outcome')) ...[
                    for (final outcome in move.outcomes)
                      if (outcome.type == rollResult['outcome'])
                        Text(outcome.description),
                  ],
                  
                  // Burn Momentum button
                  if (rollResult['couldBurnMomentum'] == true && 
                      character != null && 
                      !move.isProgressMove) ...[
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
                          final challengeDice = rollResult['challengeDice'] as List<int>;
                          final strongHit = newActionValue > challengeDice[0] && newActionValue > challengeDice[1];
                          final weakHit = (newActionValue > challengeDice[0] && newActionValue <= challengeDice[1]) ||
                                          (newActionValue <= challengeDice[0] && newActionValue > challengeDice[1]);
                          
                          String newOutcome;
                          if (strongHit) newOutcome = 'strong hit';
                          else if (weakHit) newOutcome = 'weak hit';
                          else newOutcome = 'miss';
                          
                          // Burn momentum
                          character.burnMomentum();
                          
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
                    _rollForMove(context, move);
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
}
