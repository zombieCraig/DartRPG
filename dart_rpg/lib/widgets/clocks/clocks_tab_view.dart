import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/clock.dart';
import '../../providers/game_provider.dart';
import 'clock_card.dart';
import 'clock_dialog.dart';
import 'clock_service.dart';

/// A tab view for displaying and managing clocks
class ClocksTabView extends StatefulWidget {
  /// The ID of the game
  final String gameId;
  
  /// Creates a new ClocksTabView
  const ClocksTabView({
    super.key,
    required this.gameId,
  });
  
  @override
  State<ClocksTabView> createState() => _ClocksTabViewState();
}

class _ClocksTabViewState extends State<ClocksTabView> {
  late ClockService _clockService;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the clock service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _clockService = ClockService(gameProvider: gameProvider);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final game = gameProvider.games.firstWhere(
          (g) => g.id == widget.gameId,
          orElse: () => throw Exception('Game not found'),
        );
        
        // Get all clocks
        final clocks = game.getAllClocks();
        
        // Ensure the clock service is initialized
        _clockService = ClockService(gameProvider: gameProvider);
        
        return Column(
          children: [
            // "Advance all" buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Campaign button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.public),
                      label: const Text('Advance all Campaign'),
                      onPressed: () => _advanceAllOfType(ClockType.campaign),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48), // Full width button
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  // Tension button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.warning),
                    label: const Text('Advance all Tension'),
                    onPressed: () => _advanceAllOfType(ClockType.tension),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48), // Full width button
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Clock list
            Expanded(
              child: clocks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: clocks.length,
                      itemBuilder: (context, index) {
                        final clock = clocks[index];
                        return ClockCard(
                          clock: clock,
                          onAdvance: () => _advanceClock(clock.id),
                          onReset: () => _resetClock(clock),
                          onDelete: () => _deleteClock(clock),
                          onEdit: () => _editClock(clock),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
  
  /// Build the empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No countdown clocks',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new clock using the + button',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Advance a clock by one segment
  Future<void> _advanceClock(String clockId) async {
    await _clockService.advanceClock(clockId);
  }
  
  /// Reset a clock's progress
  Future<void> _resetClock(Clock clock) async {
    final shouldReset = await ClockDialog.showResetConfirmation(
      context: context,
      clock: clock,
    );
    
    if (shouldReset == true && context.mounted) {
      await _clockService.resetClock(clock.id);
    }
  }
  
  /// Delete a clock
  Future<void> _deleteClock(Clock clock) async {
    final shouldDelete = await ClockDialog.showDeleteConfirmation(
      context: context,
      clock: clock,
    );
    
    if (shouldDelete == true && context.mounted) {
      await _clockService.deleteClock(clock.id);
    }
  }
  
  /// Edit a clock
  Future<void> _editClock(Clock clock) async {
    final result = await ClockDialog.showEditDialog(
      context: context,
      clock: clock,
    );
    
    if (result != null && context.mounted) {
      // Update the clock title (segments and type can't be changed after creation)
      await _clockService.updateClockTitle(clock.id, result['title']);
    }
  }
  
  /// Advance all clocks of a specific type
  Future<void> _advanceAllOfType(ClockType type) async {
    await _clockService.advanceAllClocksOfType(type);
  }
}
