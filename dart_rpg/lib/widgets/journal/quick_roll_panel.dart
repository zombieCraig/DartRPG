import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../models/quest.dart';
import '../../models/recent_move_entry.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/roll_service.dart';
import '../sentient_ai_dialog.dart';
import '../moves/roll_result_view.dart';
import '../common/search_text_field.dart';
import 'quick_roll_result_banner.dart';

/// A slide-in panel for quickly rolling moves from the journal editor.
/// Shows favorites, recent moves, and search — with inline results.
class QuickRollPanel extends StatefulWidget {
  final Function(MoveRoll moveRoll) onMoveRollAdded;
  final Function(String text) onInsertText;
  final Function(OracleRoll oracleRoll)? onOracleRollAdded;
  final VoidCallback onClose;

  const QuickRollPanel({
    super.key,
    required this.onMoveRollAdded,
    required this.onInsertText,
    this.onOracleRollAdded,
    required this.onClose,
  });

  @override
  State<QuickRollPanel> createState() => _QuickRollPanelState();
}

class _QuickRollPanelState extends State<QuickRollPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Last roll result for inline display
  Move? _lastRolledMove;
  MoveRoll? _lastMoveRoll;
  Map<String, dynamic>? _lastRollResult;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final currentGame = gameProvider.currentGame;
    final mainCharacter = currentGame?.mainCharacter;
    final moves = dataswornProvider.moves;

    if (currentGame == null || mainCharacter == null) {
      return _buildNoCharacterState();
    }

    final favorites = currentGame.favoriteRecentMoves;
    final recents = currentGame.nonFavoriteRecentMoves;

    // Filter moves by search
    List<Move> searchResults = [];
    if (_searchQuery.isNotEmpty) {
      searchResults = moves
          .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          const Divider(height: 1),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Last roll result
                if (_lastRolledMove != null && _lastMoveRoll != null && _lastRollResult != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: QuickRollResultBanner(
                      move: _lastRolledMove!,
                      moveRoll: _lastMoveRoll!,
                      rollResult: _lastRollResult!,
                      onRollAgain: () => _rollMove(
                        _lastRolledMove!,
                        _lastMoveRoll!.stat,
                      ),
                      onShowDetails: () => _showFullDetails(
                        context,
                        _lastRolledMove!,
                        _lastMoveRoll!,
                        _lastRollResult!,
                      ),
                      canBurnMomentum: _lastRollResult!['couldBurnMomentum'] == true,
                      onBurnMomentum: _lastRollResult!['couldBurnMomentum'] == true
                          ? () => _burnMomentum()
                          : null,
                    ),
                  ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SearchTextField(
                    controller: _searchController,
                    labelText: 'Search moves',
                    hintText: 'Type to search...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Search results
                if (_searchQuery.isNotEmpty) ...[
                  _buildSectionHeader('Search Results'),
                  if (searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No moves found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...searchResults.map((move) => _buildMoveTile(
                      move: move,
                      mainCharacter: mainCharacter,
                      recentEntry: currentGame.recentMoves
                          .firstWhereOrNull((r) => r.moveId == move.id),
                    )),
                ] else ...[
                  // Favorites
                  if (favorites.isNotEmpty) ...[
                    _buildSectionHeader('Favorites'),
                    ...favorites.map((entry) {
                      final move = moves.firstWhereOrNull((m) => m.id == entry.moveId);
                      if (move == null) return const SizedBox.shrink();
                      return _buildMoveTile(
                        move: move,
                        mainCharacter: mainCharacter,
                        recentEntry: entry,
                      );
                    }),
                  ],

                  // Recents
                  if (recents.isNotEmpty) ...[
                    _buildSectionHeader('Recent'),
                    ...recents.take(8).map((entry) {
                      final move = moves.firstWhereOrNull((m) => m.id == entry.moveId);
                      if (move == null) return const SizedBox.shrink();
                      return _buildMoveTile(
                        move: move,
                        mainCharacter: mainCharacter,
                        recentEntry: entry,
                      );
                    }),
                  ],

                  // Empty state
                  if (favorites.isEmpty && recents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No recent moves yet.\nUse the search bar to find a move, or roll from the full Moves dialog.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Quick Roll',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
            tooltip: 'Close panel',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMoveTile({
    required Move move,
    required dynamic mainCharacter,
    RecentMoveEntry? recentEntry,
  }) {
    final statName = recentEntry?.lastStat ?? move.stat;
    final statValue = statName != null ? _getStatValue(mainCharacter, statName) : null;
    final isFavorite = recentEntry?.isFavorite ?? false;
    final rollType = move.rollType;

    return InkWell(
      onTap: () {
        if (rollType == 'action_roll') {
          if (statName != null) {
            _rollMove(move, statName);
          } else {
            _showStatPicker(move, mainCharacter);
          }
        } else if (rollType == 'progress_roll') {
          _showProgressOptions(move);
        } else {
          _performNoRoll(move);
        }
      },
      onLongPress: () {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final game = gameProvider.currentGame;
        if (game != null) {
          // Ensure a recent entry exists before toggling
          if (recentEntry == null) {
            game.recordMoveUse(move.id, move.name, statName);
          }
          game.toggleMoveFavorite(move.id);
          gameProvider.saveGame();
          setState(() {});
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Favorite indicator
                if (isFavorite)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.star, size: 14, color: Colors.amber),
                  ),

                // Move name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        move.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getRollTypeLabel(rollType),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stat chip (for action rolls)
                if (rollType == 'action_roll' && statName != null)
                  GestureDetector(
                    onTap: () => _showStatPicker(move, mainCharacter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${statName.substring(0, 1).toUpperCase()}${statName.substring(1)} ${statValue != null ? "($statValue)" : ""}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(width: 4),

                // Roll icon
                Icon(
                  RollService.getRollTypeIcon(rollType),
                  size: 18,
                  color: RollService.getRollTypeColor(rollType),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCharacterState() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Create a main character to use Quick Roll.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Roll Logic ---

  void _rollMove(Move move, String? statName) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    if (character == null) return;

    final game = gameProvider.currentGame!;
    final stat = statName ?? move.stat;
    if (stat == null) {
      _showStatPicker(move, character);
      return;
    }

    final statValue = _getStatValue(character, stat);
    if (statValue == null) return;

    final result = RollService.performActionRoll(
      move: move,
      stat: stat,
      statValue: statValue,
      momentum: character.momentum,
      game: game,
    );

    final rollResult = result['rollResult'] as Map<String, dynamic>;
    final moveRoll = result['moveRoll'] as MoveRoll;

    // Record usage
    game.recordMoveUse(move.id, move.name, stat);

    // Add roll to journal entry
    widget.onMoveRollAdded(moveRoll);

    // Auto-insert formatted text
    final formattedText = moveRoll.getFormattedText();
    widget.onInsertText(formattedText);

    // Update UI
    setState(() {
      _lastRolledMove = move;
      _lastMoveRoll = moveRoll;
      _lastRollResult = rollResult;
    });

    // Save game (persists recent moves + any momentum changes)
    gameProvider.saveGame();

    // Handle Sentient AI trigger
    final sentientAiTriggered = result['sentientAiTriggered'] as bool? ?? false;
    if (sentientAiTriggered && game.aiConfig.sentientAiEnabled) {
      _handleSentientAi(game, gameProvider, move);
    }
  }

  void _performNoRoll(Move move) {
    final moveRoll = RollService.performNoRollMove(move: move);

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final game = gameProvider.currentGame;
    if (game != null) {
      game.recordMoveUse(move.id, move.name, null);
    }

    widget.onMoveRollAdded(moveRoll);
    widget.onInsertText(moveRoll.getFormattedText());

    setState(() {
      _lastRolledMove = move;
      _lastMoveRoll = moveRoll;
      _lastRollResult = {};
    });

    gameProvider.saveGame();
  }

  void _showStatPicker(Move move, dynamic character) {
    final availableStats = move.getAvailableStats();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Choose stat for ${move.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...availableStats.map((stat) {
                final value = _getStatValue(character, stat);
                return ListTile(
                  title: Text(stat),
                  trailing: Text(
                    value?.toString() ?? '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _rollMove(move, stat);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showProgressOptions(Move move) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final game = gameProvider.currentGame;
    if (game == null) return;

    // For quest-related progress moves, show quest picker
    final quests = game.quests.where((q) => q.status == QuestStatus.ongoing).toList();

    if (quests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active quests to make a progress roll against'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select quest for progress roll',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...quests.map((quest) => ListTile(
                title: Text(quest.title),
                subtitle: Text('Progress: ${quest.progress}/10'),
                onTap: () {
                  Navigator.pop(context);
                  _rollProgressMove(move, quest.id);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rollProgressMove(Move move, String questId) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final game = gameProvider.currentGame;
    if (game == null) return;

    try {
      final result = await gameProvider.makeQuestProgressRoll(questId);
      final quest = game.quests.firstWhereOrNull((q) => q.id == questId);
      if (quest == null) return;

      final moveRoll = MoveRoll(
        moveName: move.name,
        moveDescription: move.description,
        rollType: 'progress_roll',
        progressValue: quest.progress,
        challengeDice: result['challengeDice'] as List<int>,
        outcome: result['outcome'] as String,
        actionDie: 0,
        isMatch: (result['challengeDice'] as List<int>)[0] == (result['challengeDice'] as List<int>)[1],
        moveData: {
          'moveId': move.id,
          'questId': questId,
          'questTitle': quest.title,
          'questProgress': quest.progress,
        },
      );

      game.recordMoveUse(move.id, move.name, null);
      widget.onMoveRollAdded(moveRoll);

      final formattedText = moveRoll.getFormattedText();
      final questInfo = '\n**Quest:** ${quest.title} (Progress: ${quest.progress}/10)\n';
      widget.onInsertText(formattedText + questInfo);

      setState(() {
        _lastRolledMove = move;
        _lastMoveRoll = moveRoll;
        _lastRollResult = {
          'outcome': result['outcome'],
          'challengeDice': result['challengeDice'],
          'progressValue': quest.progress,
        };
      });

      gameProvider.saveGame();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _burnMomentum() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    if (character == null || _lastMoveRoll == null || _lastRollResult == null) return;

    final newActionValue = character.momentum;
    final challengeDice = _lastMoveRoll!.challengeDice;
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

    character.burnMomentum();
    _lastMoveRoll!.outcome = newOutcome;
    _lastMoveRoll!.momentumBurned = true;

    setState(() {
      _lastRollResult!['actionValue'] = newActionValue;
      _lastRollResult!['outcome'] = newOutcome;
      _lastRollResult!['momentumBurned'] = true;
      _lastRollResult!['couldBurnMomentum'] = false;
    });

    // Update the inserted text
    widget.onInsertText(' (Momentum Burned -> ${_formatOutcome(newOutcome)})');

    gameProvider.saveGame();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Momentum burned! New outcome: ${_formatOutcome(newOutcome)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFullDetails(
    BuildContext context,
    Move move,
    MoveRoll moveRoll,
    Map<String, dynamic> rollResult,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return RollResultView(
          move: move,
          moveRoll: moveRoll,
          rollResult: rollResult,
          onClose: () => Navigator.pop(context),
          onRollAgain: () {
            Navigator.pop(context);
            _rollMove(move, moveRoll.stat);
          },
          onAddToJournal: (moveRoll) {
            // Already auto-inserted, just confirm
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Roll was already added to journal'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          onOracleRollAdded: widget.onOracleRollAdded != null
              ? (oracleRoll) {
                  widget.onOracleRollAdded!(oracleRoll);
                  widget.onInsertText(oracleRoll.getFormattedText());
                }
              : null,
        );
      },
    );
  }

  Future<void> _handleSentientAi(dynamic game, GameProvider gameProvider, Move move) async {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);

    if (game.aiConfig.sentientAiName == null && game.aiConfig.sentientAiPersona == null) {
      final randomPersona = gameProvider.getRandomAiPersona(dataswornProvider);
      if (randomPersona != null) {
        await gameProvider.updateSentientAiPersona(randomPersona);
      }
    }

    if (!mounted) return;
    SentientAiDialog.show(
      context: context,
      aiName: game.aiConfig.sentientAiName,
      aiPersona: game.aiConfig.sentientAiPersona,
      aiImagePath: game.aiConfig.sentientAiImagePath,
      onOracleSelected: (oracleKey, dataswornProvider) async {
        final oracleResult = await SentientAiDialog.rollOnAiOracle(
          oracleKey: oracleKey,
          dataswornProvider: dataswornProvider,
        );

        if (oracleResult['success'] == true) {
          final oracleRoll = oracleResult['oracleRoll'] as OracleRoll;
          widget.onInsertText('\n\n**AI Outcome:** ${oracleRoll.result}\n\n');
        }
      },
      onAskOraclePressed: () {
        Navigator.pop(context);
      },
    );
  }

  // --- Helpers ---

  int? _getStatValue(dynamic character, String stat) {
    final lowerStat = stat.toLowerCase();
    final stats = character.stats as List;
    for (final s in stats) {
      if ((s.name as String).toLowerCase() == lowerStat) {
        return s.value as int;
      }
    }
    return null;
  }

  String _getRollTypeLabel(String rollType) {
    switch (rollType) {
      case 'action_roll':
        return 'Action Roll';
      case 'progress_roll':
        return 'Progress Roll';
      case 'no_roll':
        return 'No Roll';
      default:
        return 'Move';
    }
  }

  String _formatOutcome(String outcome) {
    return outcome.split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
