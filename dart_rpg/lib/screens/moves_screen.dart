import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/move.dart';
import '../models/journal_entry.dart';
import '../services/roll_service.dart';
import '../widgets/moves/move_list.dart';
import '../widgets/moves/move_details.dart';
import '../widgets/moves/roll_result_view.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  String? _selectedCategory;
  Move? _selectedMove;
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
              move.name.toLowerCase().contains(_searchQuery)
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
                  hintText: 'Enter move title',
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
                  ? MoveDetails(
                      move: _selectedMove!,
                      onBack: () {
                        setState(() {
                          _selectedMove = null;
                        });
                      },
                      onActionRoll: _rollActionMove,
                      onProgressRoll: _rollProgressMove,
                      onNoRoll: _performNoRollMove,
                      onOracleRollAdded: _addOracleToJournal,
                    )
                  : _searchQuery.isNotEmpty
                      ? MoveList(
                          moves: filteredMoves,
                          onMoveTap: (move) {
                            setState(() {
                              _selectedMove = move;
                            });
                          },
                        )
                      : _selectedCategory != null && movesByCategory.containsKey(_selectedCategory)
                          ? MoveList(
                              moves: movesByCategory[_selectedCategory]!,
                              onMoveTap: (move) {
                                setState(() {
                                  _selectedMove = move;
                                });
                              },
                            )
                          : const Center(
                              child: Text('Select a move category or search for moves'),
                            ),
            ),
          ],
        );
      },
    );
  }
  
  void _rollActionMove(Move move, String stat, int statValue, int modifier) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No main character selected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get the character's momentum
    final momentum = character.momentum;
    
    // Use the RollService to perform the roll
    final result = RollService.performActionRoll(
      move: move,
      stat: stat,
      statValue: statValue,
      modifier: modifier,
      momentum: momentum,
    );
    
    final rollResult = result['rollResult'] as Map<String, dynamic>;
    final moveRoll = result['moveRoll'] as MoveRoll;
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return RollResultView(
              move: move,
              moveRoll: moveRoll,
              rollResult: rollResult,
              onClose: () {
                Navigator.pop(context);
              },
              onRollAgain: () {
                Navigator.pop(context);
                _rollActionMove(move, stat, statValue, modifier);
              },
              onAddToJournal: _addMoveToJournal,
              onOracleRollAdded: _addOracleToJournal,
              canBurnMomentum: rollResult['couldBurnMomentum'] == true,
              onBurnMomentum: rollResult['couldBurnMomentum'] == true ? () {
                // Calculate new result with burned momentum
                final newActionValue = character.momentum;
                
                // Determine new outcome
                final challengeDice = moveRoll.challengeDice;
                final strongHit = newActionValue > challengeDice[0] && newActionValue > challengeDice[1];
                final weakHit = (newActionValue > challengeDice[0] && newActionValue <= challengeDice[1]) ||
                                (newActionValue <= challengeDice[0] && newActionValue > challengeDice[1]);
                
                String newOutcome;
                if (strongHit) {
                  newOutcome = 'strong hit';
                } else if (weakHit) {
                   newOutcome = 'weak hit';
                } else {
                  newOutcome = 'miss';
                }
                
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
              } : null,
            );
          },
        );
      },
    );
  }
  
  void _rollProgressMove(Move move, int progressValue) {
    // Use the RollService to perform the roll
    final result = RollService.performProgressRoll(
      move: move,
      progressValue: progressValue,
    );
    
    final rollResult = result['rollResult'] as Map<String, dynamic>;
    final moveRoll = result['moveRoll'] as MoveRoll;
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return RollResultView(
          move: move,
          moveRoll: moveRoll,
          rollResult: rollResult,
          onClose: () {
            Navigator.pop(context);
          },
          onRollAgain: () {
            Navigator.pop(context);
            _rollProgressMove(move, progressValue);
          },
          onAddToJournal: _addMoveToJournal,
          onOracleRollAdded: _addOracleToJournal,
        );
      },
    );
  }
  
  void _performNoRollMove(Move move) {
    // Use the RollService to perform the move
    final moveRoll = RollService.performNoRollMove(move: move);
    
    // Show the result
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${move.name} Performed'),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
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
                _addMoveToJournal(moveRoll);
              },
              child: const Text('Add to Journal'),
            ),
          ],
        );
      },
    );
  }
  
  void _addMoveToJournal(MoveRoll moveRoll) {
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
  
  void _addOracleToJournal(OracleRoll oracleRoll) {
    // Show a snackbar to indicate the oracle roll was added to the journal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${oracleRoll.oracleName} roll added to journal'),
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
}
