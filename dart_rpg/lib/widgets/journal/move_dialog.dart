import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/roll_service.dart';
import '../moves/move_list.dart';
import '../moves/move_details.dart';
import '../moves/roll_result_view.dart';

/// A dialog for selecting and rolling moves in the journal entry screen.
class MoveDialog {
  /// Shows a dialog for selecting and rolling moves.
  /// 
  /// The [onMoveRollAdded] callback is called when a move roll is added to the journal entry.
  /// The [onInsertText] callback is called when text should be inserted at the cursor position.
  static void show(
    BuildContext context, {
    required Function(MoveRoll moveRoll) onMoveRollAdded,
    required Function(String text) onInsertText,
    required bool isEditing,
  }) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';
    String? selectedCategory;
    Move? selectedMove;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer2<DataswornProvider, GameProvider>(
              builder: (context, dataswornProvider, gameProvider, _) {
                final moves = dataswornProvider.moves;
                
                if (moves.isEmpty) {
                  return AlertDialog(
                    title: const Text('Moves'),
                    content: const Center(
                      child: Text('No moves available'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                }
                
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
                if (searchQuery.isNotEmpty) {
                  for (final category in movesByCategory.keys) {
                    filteredMoves.addAll(
                      movesByCategory[category]!.where((move) => 
                        move.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (move.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                        (move.trigger?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                      )
                    );
                  }
                }
                
                return AlertDialog(
                  title: const Text('Moves'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 500,
                    child: Column(
                      children: [
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              labelText: 'Search Moves',
                              hintText: 'Enter move name or description',
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        setState(() {
                                          searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                                selectedMove = null;
                              });
                            },
                          ),
                        ),
                        
                        // Category selector (only shown when not searching)
                        if (searchQuery.isEmpty && selectedMove == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Move Category',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCategory,
                              items: sortedCategories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value;
                                  selectedMove = null;
                                });
                              },
                            ),
                          ),
                        
                        // Move list or details
                        Expanded(
                          child: selectedMove != null
                              ? MoveDetails(
                                  move: selectedMove!,
                                  onBack: () {
                                    setState(() {
                                      selectedMove = null;
                                    });
                                  },
                                  onActionRoll: (move, stat, statValue, modifier) {
                                    Navigator.pop(context);
                                    _rollActionMove(
                                      context, 
                                      move, 
                                      stat, 
                                      statValue, 
                                      modifier, 
                                      onMoveRollAdded, 
                                      onInsertText, 
                                      isEditing,
                                    );
                                  },
                                  onProgressRoll: (move, progressValue) {
                                    Navigator.pop(context);
                                    _rollProgressMove(
                                      context, 
                                      move, 
                                      progressValue, 
                                      onMoveRollAdded, 
                                      onInsertText, 
                                      isEditing,
                                    );
                                  },
                                  onNoRoll: (move) {
                                    Navigator.pop(context);
                                    _performNoRollMove(
                                      context, 
                                      move, 
                                      onMoveRollAdded, 
                                      onInsertText, 
                                      isEditing,
                                    );
                                  },
                                )
                              : searchQuery.isNotEmpty
                                  ? MoveList(
                                      moves: filteredMoves,
                                      onMoveTap: (move) {
                                        setState(() {
                                          selectedMove = move;
                                        });
                                      },
                                    )
                                  : selectedCategory != null && movesByCategory.containsKey(selectedCategory)
                                      ? MoveList(
                                          moves: movesByCategory[selectedCategory]!,
                                          onMoveTap: (move) {
                                            setState(() {
                                              selectedMove = move;
                                            });
                                          },
                                        )
                                      : const Center(
                                          child: Text('Select a move category or search for moves'),
                                        ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Rolls an action move with a specific stat and modifier.
  static void _rollActionMove(
    BuildContext context, 
    Move move, 
    String stat, 
    int statValue, 
    int modifier, 
    Function(MoveRoll moveRoll) onMoveRollAdded,
    Function(String text) onInsertText,
    bool isEditing,
  ) {
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
    final momentum = character.momentum ?? 0;
    
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
    
    // Add the move roll to the journal entry
    onMoveRollAdded(moveRoll);
    
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
                _rollActionMove(
                  context, 
                  move, 
                  stat, 
                  statValue, 
                  modifier, 
                  onMoveRollAdded, 
                  onInsertText, 
                  isEditing,
                );
              },
              onAddToJournal: (moveRoll) {
                // Insert the move roll text at the cursor position
                if (isEditing) {
                  final formattedText = moveRoll.getFormattedText();
                  onInsertText(formattedText);
                }
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Move roll added to journal entry'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
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

  /// Rolls a progress move with a specific progress value.
  static void _rollProgressMove(
    BuildContext context, 
    Move move, 
    int progressValue, 
    Function(MoveRoll moveRoll) onMoveRollAdded,
    Function(String text) onInsertText,
    bool isEditing,
  ) {
    // Use the RollService to perform the roll
    final result = RollService.performProgressRoll(
      move: move,
      progressValue: progressValue,
    );
    
    final rollResult = result['rollResult'] as Map<String, dynamic>;
    final moveRoll = result['moveRoll'] as MoveRoll;
    
    // Add the move roll to the journal entry
    onMoveRollAdded(moveRoll);
    
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
            _rollProgressMove(
              context, 
              move, 
              progressValue, 
              onMoveRollAdded, 
              onInsertText, 
              isEditing,
            );
          },
          onAddToJournal: (moveRoll) {
            // Insert the move roll text at the cursor position
            if (isEditing) {
              final formattedText = moveRoll.getFormattedText();
              onInsertText(formattedText);
            }
            
            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Progress roll added to journal entry'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  /// Performs a move that doesn't require a roll.
  static void _performNoRollMove(
    BuildContext context, 
    Move move, 
    Function(MoveRoll moveRoll) onMoveRollAdded,
    Function(String text) onInsertText,
    bool isEditing,
  ) {
    // Use the RollService to perform the move
    final moveRoll = RollService.performNoRollMove(move: move);
    
    // Add the move roll to the journal entry
    onMoveRollAdded(moveRoll);
    
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
                // Insert the move text at the cursor position
                if (isEditing) {
                  final formattedText = moveRoll.getFormattedText();
                  onInsertText(formattedText);
                }
                
                Navigator.pop(context);
                
                // Show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Move added to journal entry'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Add to Journal'),
            ),
          ],
        );
      },
    );
  }
}
