import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/combat.dart';
import '../../models/move.dart';
import '../../models/move_oracle.dart';
import '../../models/journal_entry.dart';
import '../../utils/dice_roller.dart';
import '../../models/quest.dart';
import '../../models/recent_move_entry.dart';
import '../../providers/ai_config_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/roll_service.dart';
import '../character/panels/character_key_stats_panel.dart';
import '../combat/combat_create_dialog.dart';
import '../combat/combat_tracker_panel.dart';
import '../sentient_ai_dialog.dart';
import '../moves/roll_result_view.dart';
import '../common/search_text_field.dart';
import 'move_dialog.dart';
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
  bool _showHeaderStats = false;
  bool _showCombatSection = true;

  // Snapshot for header stat changes
  int _snapMomentum = 0;
  int _snapHealth = 0;
  int _snapSpirit = 0;
  int _snapSupply = 0;

  // Last roll result for inline display
  Move? _lastRolledMove;
  MoveRoll? _lastMoveRoll;
  Map<String, dynamic>? _lastRollResult;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _takeHeaderSnapshot(Character c) {
    _snapMomentum = c.momentum;
    _snapHealth = c.health;
    _snapSpirit = c.spirit;
    _snapSupply = c.supply;
  }

  void _onHeaderStatsChanged(int momentum, int health, int spirit, int supply) {
    final deltas = <String>[];
    if (momentum != _snapMomentum) deltas.add('Momentum ${_fmtDelta(momentum - _snapMomentum)}');
    if (health != _snapHealth) deltas.add('Health ${_fmtDelta(health - _snapHealth)}');
    if (spirit != _snapSpirit) deltas.add('Spirit ${_fmtDelta(spirit - _snapSpirit)}');
    if (supply != _snapSupply) deltas.add('Supply ${_fmtDelta(supply - _snapSupply)}');

    if (deltas.isNotEmpty) {
      widget.onInsertText('\n*[${deltas.join(", ")}]*');
      _snapMomentum = momentum;
      _snapHealth = health;
      _snapSpirit = spirit;
      _snapSupply = supply;
    }
  }

  String _fmtDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

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
          _buildHeader(context, mainCharacter),

          const Divider(height: 1),

          // Collapsible stat adjustment strip
          if (_showHeaderStats) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: CharacterKeyStatsPanel(
                character: mainCharacter,
                useCompactMode: true,
                isEditable: true,
                onStatsChanged: _onHeaderStatsChanged,
              ),
            ),
            const Divider(height: 1),
          ],

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
                      character: mainCharacter,
                      onInsertText: widget.onInsertText,
                    ),
                  ),

                // Combat section
                _buildCombatSection(context, currentGame, mainCharacter, gameProvider),

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

  Widget _buildHeader(BuildContext context, Character? mainCharacter) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final activeCombats = gameProvider.currentGame?.activeCombats ?? [];
    final latestCombat = activeCombats.isNotEmpty ? activeCombats.last : null;

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
          // In Control toggle (only when active combats exist)
          if (latestCombat != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await gameProvider.toggleCombatControl(latestCombat.id);
                final newState = latestCombat.isInControl ? 'In Control' : 'In a Bad Spot';
                widget.onInsertText('\n*[Combat: $newState]*');
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: latestCombat.isInControl
                      ? Colors.green.withAlpha(40)
                      : Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: latestCombat.isInControl ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Text(
                  latestCombat.isInControl ? 'In Control' : 'Bad Spot',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: latestCombat.isInControl ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (mainCharacter != null)
            IconButton(
              icon: Icon(
                _showHeaderStats ? Icons.expand_less : Icons.tune,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _showHeaderStats = !_showHeaderStats;
                  if (_showHeaderStats) _takeHeaderSnapshot(mainCharacter);
                });
              },
              visualDensity: VisualDensity.compact,
              tooltip: _showHeaderStats ? 'Hide stats' : 'Adjust stats',
            ),
          IconButton(
            icon: const Icon(Icons.menu_book, size: 18),
            onPressed: () {
              MoveDialog.show(
                context,
                onMoveRollAdded: widget.onMoveRollAdded,
                onInsertText: widget.onInsertText,
                isEditing: true,
              );
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Browse all moves',
          ),
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
          _buildHeader(context, null),
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

    // Auto-update combat state based on combat move outcomes
    if (_isCombatMove(move.id)) {
      _applyCombatAutoUpdate(move.id, moveRoll.outcome, gameProvider);
    }

    // Save game (persists recent moves + any momentum changes)
    gameProvider.saveGame();

    // Handle Sentient AI trigger
    final sentientAiTriggered = result['sentientAiTriggered'] as bool? ?? false;
    if (sentientAiTriggered && game.aiConfig.sentientAiEnabled) {
      _handleSentientAi(game, gameProvider, move);
    }
  }

  void _performNoRoll(Move move) {
    // If the move has embedded oracles (e.g. Ask the Oracle), show likelihood picker
    if (move.hasEmbeddedOracles) {
      _showOracleLikelihoodPicker(move);
      return;
    }

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

  void _showOracleLikelihoodPicker(Move move) {
    final oracles = move.oracles;

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
                  'Choose likelihood for ${move.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...oracles.entries.map((entry) {
                final oracle = entry.value;
                // Build odds subtitle from rows (e.g. "1-75 Yes, 76-100 No")
                final odds = oracle.rows
                    .map((r) => '${r.minRoll}-${r.maxRoll} ${r.result}')
                    .join(', ');
                return ListTile(
                  title: Text(oracle.name),
                  subtitle: Text(odds, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  onTap: () {
                    Navigator.pop(context);
                    _rollAskTheOracle(move, entry.key, oracle);
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

  void _rollAskTheOracle(Move move, String oracleKey, MoveOracle oracle) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final game = gameProvider.currentGame;

    // Roll the dice
    final rollResult = DiceRoller.rollOracle(oracle.dice);
    final total = rollResult['total'] as int;

    // Find matching row
    String result = 'Unknown';
    for (final row in oracle.rows) {
      if (total >= row.minRoll && total <= row.maxRoll) {
        result = row.result;
        break;
      }
    }

    // Detect d100 match (doubles: 11, 22, 33, ..., 99, 00)
    final isMatch = oracle.dice == '1d100' && total >= 11 && total % 11 == 0;

    // Create a MoveRoll for the move usage
    final moveRoll = RollService.performNoRollMove(move: move);
    widget.onMoveRollAdded(moveRoll);

    // Create an OracleRoll
    final oracleName = '${move.name} (${oracle.name})';
    final oracleRoll = OracleRoll(
      oracleName: oracleName,
      dice: [total],
      result: isMatch ? '$result - Match!' : result,
    );
    widget.onOracleRollAdded?.call(oracleRoll);

    // Format journal text
    final matchSuffix = isMatch ? ' - Match!' : '';
    final journalText = '[${move.name} (${oracle.name}) $total: $result$matchSuffix]';
    widget.onInsertText(journalText);

    // Record usage
    if (game != null) {
      game.recordMoveUse(move.id, move.name, null);
      gameProvider.saveGame();
    }

    setState(() {
      _lastRolledMove = move;
      _lastMoveRoll = moveRoll;
      _lastRollResult = {};
    });
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

    final quests = game.quests.where((q) => q.status == QuestStatus.ongoing).toList();
    final isCombatMove = move.id == 'move:fe_runners/combat/take_decisive_action';
    final activeCombats = isCombatMove ? game.activeCombats : <Combat>[];

    if (quests.isEmpty && activeCombats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCombatMove
              ? 'No active quests or combats to make a progress roll against'
              : 'No active quests to make a progress roll against'),
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
                  'Select target for progress roll',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Combats first (only shown for Take Decisive Action)
              ...activeCombats.map((combat) => ListTile(
                leading: const Icon(Icons.sports_martial_arts, size: 20, color: Colors.red),
                title: Text('Combat: ${combat.title}'),
                subtitle: Text('Progress: ${combat.progress}/10'),
                onTap: () {
                  Navigator.pop(context);
                  _rollCombatProgressMove(combat);
                },
              )),
              // Quests (shown for all progress moves)
              ...quests.map((quest) => ListTile(
                leading: const Icon(Icons.task_alt, size: 20),
                title: Text('Quest: ${quest.title}'),
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
        moveId: move.id,
        rollType: 'progress_roll',
        progressValue: quest.progress,
        challengeDice: result['challengeDice'] as List<int>,
        outcome: result['outcome'] as String,
        actionDie: 0,
        isMatch: (result['challengeDice'] as List<int>)[0] == (result['challengeDice'] as List<int>)[1],
        moveData: {
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
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;

    showDialog(
      context: context,
      builder: (context) {
        return RollResultView(
          move: move,
          moveRoll: moveRoll,
          rollResult: rollResult,
          character: character,
          onInsertText: widget.onInsertText,
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
      final aiConfigProvider = Provider.of<AiConfigProvider>(context, listen: false);
      final randomPersona = aiConfigProvider.getRandomAiPersona(dataswornProvider);
      if (randomPersona != null) {
        await aiConfigProvider.updateSentientAiPersona(randomPersona);
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

  // --- Combat ---

  /// Map of combat move IDs to their auto-update rules
  static const _combatMoveIds = {
    'move:fe_runners/combat/enter_the_fray',
    'move:fe_runners/combat/gain_ground',
    'move:fe_runners/combat/strike',
    'move:fe_runners/combat/clash',
    'move:fe_runners/combat/react_under_fire',
    'move:fe_runners/combat/take_decisive_action',
  };

  bool _isCombatMove(String moveId) => _combatMoveIds.contains(moveId);

  void _applyCombatAutoUpdate(String moveId, String outcome, GameProvider gameProvider) {
    final game = gameProvider.currentGame;
    if (game == null) return;

    final activeCombats = game.activeCombats;
    if (activeCombats.isEmpty) return;

    final combat = activeCombats.last;
    final combatId = combat.id;

    final isStrongHit = outcome == 'strong hit';
    final isWeakHit = outcome == 'weak hit';
    final isMiss = outcome == 'miss';

    switch (moveId) {
      case 'move:fe_runners/combat/enter_the_fray':
        if (isStrongHit) {
          gameProvider.setCombatControl(combatId, true);
          widget.onInsertText('\n*[Combat: In Control]*');
        } else if (isMiss) {
          gameProvider.setCombatControl(combatId, false);
          widget.onInsertText('\n*[Combat: In a Bad Spot]*');
        }
        break;

      case 'move:fe_runners/combat/gain_ground':
        if (isStrongHit || isWeakHit) {
          gameProvider.setCombatControl(combatId, true);
          widget.onInsertText('\n*[Combat: In Control]*');
        } else if (isMiss) {
          gameProvider.setCombatControl(combatId, false);
          widget.onInsertText('\n*[Combat: In a Bad Spot]*');
        }
        break;

      case 'move:fe_runners/combat/strike':
        if (isStrongHit) {
          gameProvider.setCombatControl(combatId, true);
          gameProvider.addCombatTicksForRankDouble(combatId);
          widget.onInsertText('\n*[Combat "${combat.title}": In Control, +progress x2 (${combat.progress}/10)]*');
        } else if (isWeakHit) {
          gameProvider.setCombatControl(combatId, false);
          gameProvider.addCombatTicksForRankDouble(combatId);
          widget.onInsertText('\n*[Combat "${combat.title}": In a Bad Spot, +progress x2 (${combat.progress}/10)]*');
        } else if (isMiss) {
          gameProvider.setCombatControl(combatId, false);
          widget.onInsertText('\n*[Combat: In a Bad Spot]*');
        }
        break;

      case 'move:fe_runners/combat/clash':
        if (isStrongHit) {
          gameProvider.setCombatControl(combatId, true);
          gameProvider.addCombatTicksForRankDouble(combatId);
          widget.onInsertText('\n*[Combat "${combat.title}": In Control, +progress x2 (${combat.progress}/10)]*');
        } else if (isWeakHit) {
          gameProvider.setCombatControl(combatId, false);
          gameProvider.addCombatTicksForRank(combatId);
          widget.onInsertText('\n*[Combat "${combat.title}": In a Bad Spot, +progress (${combat.progress}/10)]*');
        } else if (isMiss) {
          gameProvider.setCombatControl(combatId, false);
          widget.onInsertText('\n*[Combat: In a Bad Spot]*');
        }
        break;

      case 'move:fe_runners/combat/react_under_fire':
        if (isStrongHit) {
          gameProvider.setCombatControl(combatId, true);
          widget.onInsertText('\n*[Combat: In Control]*');
        }
        // weak hit/miss: stay in bad spot (no change needed)
        break;
    }

    setState(() {});
  }

  Widget _buildCombatSection(BuildContext context, dynamic currentGame, Character mainCharacter, GameProvider gameProvider) {
    final activeCombats = currentGame.activeCombats as List<Combat>;

    if (activeCombats.isEmpty && !_showCombatSection) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with toggle and new combat button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showCombatSection = !_showCombatSection),
                child: Row(
                  children: [
                    Icon(
                      _showCombatSection ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Combat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (activeCombats.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${activeCombats.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () {
                  CombatCreateDialog.show(
                    context,
                    onCreate: (title, rank) async {
                      await gameProvider.createCombat(
                        title,
                        mainCharacter.id,
                        rank,
                      );
                      widget.onInsertText('\n*[Combat Started: $title (${rank.displayName})]*');
                      setState(() => _showCombatSection = true);
                    },
                  );
                },
                visualDensity: VisualDensity.compact,
                tooltip: 'New Combat',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ),

        // Active combat trackers
        if (_showCombatSection)
          ...activeCombats.map((combat) => CombatTrackerPanel(
            combat: combat,
            onMarkProgress: () async {
              await gameProvider.addCombatTicksForRank(combat.id);
              widget.onInsertText('\n*[Combat "${combat.title}": +progress (${combat.progress}/10)]*');
              setState(() {});
            },
            onMarkProgressDouble: () async {
              await gameProvider.addCombatTicksForRankDouble(combat.id);
              widget.onInsertText('\n*[Combat "${combat.title}": +progress x2 (${combat.progress}/10)]*');
              setState(() {});
            },
            onDecrease: () async {
              await gameProvider.removeCombatTicksForRank(combat.id);
              widget.onInsertText('\n*[Combat "${combat.title}": -progress (${combat.progress}/10)]*');
              setState(() {});
            },
            onProgressRoll: () => _rollCombatProgressMove(combat),
            onToggleControl: () async {
              await gameProvider.toggleCombatControl(combat.id);
              final newState = combat.isInControl ? 'In Control' : 'In a Bad Spot';
              widget.onInsertText('\n*[Combat: $newState]*');
              setState(() {});
            },
            onEnd: (status) async {
              await gameProvider.endCombat(combat.id, status);
              widget.onInsertText('\n*[Combat "${combat.title}" ended: ${status.displayName}]*');
              setState(() {});
            },
            onTickChanged: (ticks) async {
              await gameProvider.updateCombatProgressTicks(combat.id, ticks);
              setState(() {});
            },
          )),

        if (activeCombats.isNotEmpty || _showCombatSection)
          const Divider(height: 8),
      ],
    );
  }

  Future<void> _rollCombatProgressMove(Combat combat) async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);

    try {
      final result = await gameProvider.makeCombatProgressRoll(combat.id);

      // Find the Take Decisive Action move
      final move = dataswornProvider.moves.firstWhereOrNull(
        (m) => m.id == 'move:fe_runners/combat/take_decisive_action',
      );

      final moveName = move?.name ?? 'Take Decisive Action';
      final moveId = move?.id ?? 'take_decisive_action';

      final moveRoll = MoveRoll(
        moveName: moveName,
        moveId: moveId,
        rollType: 'progress_roll',
        progressValue: combat.progress,
        challengeDice: result['challengeDice'] as List<int>,
        outcome: result['outcome'] as String,
        actionDie: 0,
        isMatch: (result['challengeDice'] as List<int>)[0] == (result['challengeDice'] as List<int>)[1],
        moveData: {
          'combatId': combat.id,
          'combatTitle': combat.title,
          'combatProgress': combat.progress,
        },
      );

      widget.onMoveRollAdded(moveRoll);

      final formattedText = moveRoll.getFormattedText();
      final combatInfo = '\n**Combat:** ${combat.title} (Progress: ${combat.progress}/10)\n';
      widget.onInsertText(formattedText + combatInfo);

      setState(() {
        _lastRolledMove = move;
        _lastMoveRoll = moveRoll;
        _lastRollResult = {
          'outcome': result['outcome'],
          'challengeDice': result['challengeDice'],
          'progressValue': combat.progress,
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
