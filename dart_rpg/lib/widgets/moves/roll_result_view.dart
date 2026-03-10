import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/move.dart';
import '../../models/journal_entry.dart';
import '../../providers/datasworn_provider.dart';
import '../../services/roll_service.dart';
import '../../utils/datasworn_link_parser.dart';
import '../character/panels/character_key_stats_panel.dart';
import 'outcome_oracle_panel.dart';

/// A widget for displaying the results of a move roll.
class RollResultView extends StatefulWidget {
  final Move move;
  final MoveRoll moveRoll;
  final Map<String, dynamic> rollResult;
  final VoidCallback onClose;
  final VoidCallback onRollAgain;
  final Function(MoveRoll) onAddToJournal;
  final Function(OracleRoll)? onOracleRollAdded;
  final bool canBurnMomentum;
  final Function()? onBurnMomentum;
  final Character? character;
  final Function(String text)? onInsertText;

  const RollResultView({
    super.key,
    required this.move,
    required this.moveRoll,
    required this.rollResult,
    required this.onClose,
    required this.onRollAgain,
    required this.onAddToJournal,
    this.onOracleRollAdded,
    this.canBurnMomentum = false,
    this.onBurnMomentum,
    this.character,
    this.onInsertText,
  });

  @override
  State<RollResultView> createState() => _RollResultViewState();
}

class _RollResultViewState extends State<RollResultView> {
  final ScrollController _scrollController = ScrollController();
  bool _showStats = false;
  int _snapMomentum = 0;
  int _snapHealth = 0;
  int _snapSpirit = 0;
  int _snapSupply = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _takeSnapshot() {
    final c = widget.character!;
    _snapMomentum = c.momentum;
    _snapHealth = c.health;
    _snapSpirit = c.spirit;
    _snapSupply = c.supply;
  }

  void _onStatsChanged(int momentum, int health, int spirit, int supply) {
    if (widget.onInsertText == null) return;
    final deltas = <String>[];
    if (momentum != _snapMomentum) deltas.add('Momentum ${_fmtDelta(momentum - _snapMomentum)}');
    if (health != _snapHealth) deltas.add('Health ${_fmtDelta(health - _snapHealth)}');
    if (spirit != _snapSpirit) deltas.add('Spirit ${_fmtDelta(spirit - _snapSpirit)}');
    if (supply != _snapSupply) deltas.add('Supply ${_fmtDelta(supply - _snapSupply)}');
    if (deltas.isNotEmpty) {
      widget.onInsertText!('\n*[${deltas.join(", ")}]*');
      _snapMomentum = momentum;
      _snapHealth = health;
      _snapSpirit = spirit;
      _snapSupply = supply;
    }
  }

  String _fmtDelta(int delta) => delta > 0 ? '+$delta' : '$delta';

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.move.name} Roll'),
      content: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.move.description != null) ...[
              MarkdownBody(
                data: widget.move.description!,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: Theme.of(context).textTheme.bodyMedium,
                ),
                selectable: true,
                softLineBreak: true,
                onTapLink: (text, href, title) {
                  final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
                  DataswornLinkParser.handleMarkdownLink(context, dataswornProvider, text, href, title);
                },
              ),
              const SizedBox(height: 16),
            ],
            
            if (widget.moveRoll.rollType == 'action_roll') ...[
              _buildActionRollDetails(),
            ] else if (widget.moveRoll.rollType == 'progress_roll') ...[
              _buildProgressRollDetails(),
            ] else ...[
              _buildNoRollDetails(),
            ],
            
            // Outcome
            Row(
              children: [
                Text(
                  'Outcome: ${widget.moveRoll.outcome.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: RollService.getOutcomeColor(widget.moveRoll.outcome),
                  ),
                ),
                if (widget.moveRoll.isMatch && 
                    (widget.moveRoll.outcome.contains('strong hit') || widget.moveRoll.outcome.contains('miss'))) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.moveRoll.outcome.contains('strong hit') 
                        ? '(Something special happens!)' 
                        : '(Something bad happens!)',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: RollService.getMatchColor(widget.moveRoll.outcome),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            
            // Find the matching outcome description
            if (widget.moveRoll.outcome != 'performed') ...[
              for (final outcome in widget.move.outcomes)
                if (outcome.type == widget.moveRoll.outcome)
                  MarkdownBody(
                    data: outcome.description,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selectable: true,
                    softLineBreak: true,
                    onTapLink: (text, href, title) {
                      final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
                      DataswornLinkParser.handleMarkdownLink(context, dataswornProvider, text, href, title);
                    },
                  ),
            ],
            
            // Burn Momentum button
            if (widget.canBurnMomentum && widget.onBurnMomentum != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.local_fire_department),
                  label: Text('Burn Momentum (${widget.rollResult['momentum']})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  onPressed: widget.onBurnMomentum,
                ),
              ),
            ],
            
            // Momentum burned indicator
            if (widget.rollResult['momentumBurned'] == true) ...[
              const SizedBox(height: 8),
              const Text(
                'Momentum has been burned!',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('New Momentum: ${widget.rollResult['momentum']}'),
            ],
            
            // Add outcome oracle panel if appropriate
            if (widget.onOracleRollAdded != null &&
                (widget.move.hasOraclesForOutcome(widget.moveRoll.outcome) ||
                 (widget.move.id == 'fe_runners/exploration/explore_the_system' &&
                  widget.moveRoll.outcome == 'weak hit'))) ...[
              const SizedBox(height: 16),
              NotificationListener<SizeChangedLayoutNotification>(
                onNotification: (_) {
                  _scrollToBottom();
                  return true;
                },
                child: SizeChangedLayoutNotifier(
                  child: OutcomeOraclePanel(
                    move: widget.move,
                    outcome: widget.moveRoll.outcome,
                    statUsed: widget.moveRoll.stat,
                    onOracleRollAdded: widget.onOracleRollAdded!,
                  ),
                ),
              ),
            ],

            // Inline stat adjustment
            if (widget.character != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              InkWell(
                onTap: () {
                  setState(() {
                    _showStats = !_showStats;
                    if (_showStats) _takeSnapshot();
                  });
                  if (_showStats) _scrollToBottom();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showStats ? Icons.expand_less : Icons.tune,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Adjust Stats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showStats)
                CharacterKeyStatsPanel(
                  character: widget.character!,
                  useCompactMode: true,
                  isEditable: true,
                  onStatsChanged: _onStatsChanged,
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: widget.onRollAgain,
          child: const Text('Roll Again'),
        ),
        TextButton(
          onPressed: () {
            widget.onAddToJournal(widget.moveRoll);
            widget.onClose();
          },
          child: const Text('Add to Journal'),
        ),
      ],
    );
  }
  
  Widget _buildActionRollDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Action Die: ${widget.rollResult['actionDie']}',
              style: widget.rollResult['actionDieCanceled'] == true
                  ? const TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    )
                  : null,
            ),
            if (widget.rollResult['actionDieCanceled'] == true) ...[
              const SizedBox(width: 8),
              const Text(
                '(Canceled by negative momentum)',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        
        if (widget.moveRoll.stat != null) ...[
          Text('Stat: ${widget.moveRoll.stat} (${widget.moveRoll.statValue})'),
          const SizedBox(height: 4),
        ],
        
        if (widget.moveRoll.modifier != null && widget.moveRoll.modifier != 0) ...[
          Text('Modifier: ${widget.moveRoll.modifier! > 0 ? '+' : ''}${widget.moveRoll.modifier}'),
          const SizedBox(height: 4),
        ],
        
        Text('Total Action Value: ${widget.rollResult['actionValue']}'),
        const SizedBox(height: 8),
        
        _buildChallengeDice(),
        
        // Momentum information
        if (widget.rollResult.containsKey('momentum')) ...[
          Text('Current Momentum: ${widget.rollResult['momentum']}'),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
  
  Widget _buildProgressRollDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Value: ${widget.moveRoll.progressValue}'),
        const SizedBox(height: 8),
        
        _buildChallengeDice(),
      ],
    );
  }
  
  Widget _buildNoRollDetails() {
    return const Text(
      'Move performed successfully',
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
    );
  }
  
  Widget _buildChallengeDice() {
    return Row(
      children: [
        Text('Challenge Dice: ${widget.moveRoll.challengeDice.join(' and ')}'),
        if (widget.moveRoll.isMatch) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: RollService.getMatchColor(widget.moveRoll.outcome),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  RollService.getMatchIcon(widget.moveRoll.outcome),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Match!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
