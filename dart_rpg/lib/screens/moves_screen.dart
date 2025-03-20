import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/move.dart';
import '../utils/dice_roller.dart';

class MovesScreen extends StatefulWidget {
  const MovesScreen({super.key});

  @override
  State<MovesScreen> createState() => _MovesScreenState();
}

class _MovesScreenState extends State<MovesScreen> {
  String? _selectedCategory;
  Move? _selectedMove;
  
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
        
        return Column(
          children: [
            // Category selector
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                  : _selectedCategory != null && movesByCategory.containsKey(_selectedCategory)
                      ? _buildMoveList(movesByCategory[_selectedCategory]!)
                      : const Center(
                          child: Text('Select a move category to begin'),
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
          
          // Roll button
          if (move.stat != null || move.isProgressMove)
            ElevatedButton.icon(
              icon: const Icon(Icons.casino),
              label: Text('Roll ${move.isProgressMove ? "Progress" : "Action"} Move'),
              onPressed: () {
                _rollForMove(context, move);
              },
            ),
        ],
      ),
    );
  }
  
  void _rollForMove(BuildContext context, Move move) {
    // Determine which dice to roll based on the move type
    Map<String, dynamic> rollResult;
    
    if (move.isProgressMove) {
      // For progress moves, we'll use a default progress value of 3
      // In a real app, this would come from the character's progress track
      rollResult = DiceRoller.rollProgressMove(progressValue: 3);
    } else {
      // For action moves, we'll use the character's stat if available
      // In a real app, this would come from the character's stats
      final statValue = 2; // Default stat value
      rollResult = DiceRoller.rollMove(statValue: statValue);
    }
    
    // Show the roll result
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${move.name} Roll'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rollResult.containsKey('actionDie')) ...[
                Text('Action Die: ${rollResult['actionDie']}'),
                const SizedBox(height: 4),
              ],
              
              if (rollResult.containsKey('statValue') && rollResult['statValue'] != null) ...[
                Text('Stat Value: ${rollResult['statValue']}'),
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
  }
}
