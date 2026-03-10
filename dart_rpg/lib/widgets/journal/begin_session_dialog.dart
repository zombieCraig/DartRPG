import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/clock.dart';
import '../../models/move_oracle.dart';
import '../../providers/datasworn_provider.dart';
import '../../providers/game_provider.dart';
import '../../utils/dice_roller.dart';

/// Multi-step dialog implementing the "Begin a Session" move.
///
/// Steps:
/// 0. Advance campaign clocks
/// 1. Roll session vignette oracle (optional)
/// 2. Confirm and apply (+1 momentum, journal entry)
class BeginSessionDialog extends StatefulWidget {
  final String? previousFocusNotes;

  const BeginSessionDialog({super.key, this.previousFocusNotes});

  @override
  State<BeginSessionDialog> createState() => _BeginSessionDialogState();
}

class _BeginSessionDialogState extends State<BeginSessionDialog> {
  int _currentStep = 0;
  final List<String> _advancedClockNames = [];
  String? _vignetteResult;
  MoveOracle? _moveOracle;

  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _loadMoveOracle();
  }

  void _loadMoveOracle() {
    final datasworn = Provider.of<DataswornProvider>(context, listen: false);
    final move = datasworn.findMoveById('begin_a_session');
    if (move != null && move.oracles.isNotEmpty) {
      _moveOracle = move.oracles.values.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Begin a Session')),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _buildStepContent(),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildClockStep();
      case 1:
        return _buildVignetteStep();
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Campaign Clocks
  Widget _buildClockStep() {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final activeClocks = game.clocks
        .where((c) => c.type == ClockType.campaign && !c.isComplete)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.previousFocusNotes != null) ...[
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bookmark, size: 20,
                    color: Theme.of(context).colorScheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last session focus:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          )),
                        const SizedBox(height: 4),
                        Text(widget.previousFocusNotes!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onTertiaryContainer,
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Advance Campaign Clocks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Advance any campaign clocks that are threatened by time or circumstance.'),
        const SizedBox(height: 16),
        if (activeClocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No active campaign clocks.'),
          )
        else
          ...activeClocks.map((clock) => _buildClockTile(clock, gameProvider)),
      ],
    );
  }

  Widget _buildClockTile(Clock clock, GameProvider gameProvider) {
    final wasAdvanced = _advancedClockNames.contains(clock.title);
    return Card(
      child: ListTile(
        title: Text(clock.title),
        subtitle: Text('${clock.progress} / ${clock.segments} segments'),
        trailing: wasAdvanced
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton.tonal(
                onPressed: () async {
                  await gameProvider.advanceClock(clock.id);
                  setState(() {
                    _advancedClockNames.add(clock.title);
                  });
                },
                child: const Text('Advance'),
              ),
      ),
    );
  }

  // Step 1: Session Vignette Oracle
  Widget _buildVignetteStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Session Vignette',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Optionally roll for a session vignette to set the scene.'),
        const SizedBox(height: 16),
        if (_moveOracle == null)
          const Text('No vignette oracle found for this move.')
        else ...[
          Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.casino),
              label: Text(_vignetteResult == null ? 'Roll Vignette' : 'Re-roll'),
              onPressed: _rollVignette,
            ),
          ),
          if (_vignetteResult != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _vignetteResult!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _rollVignette() {
    if (_moveOracle == null) return;
    final table = _moveOracle!.toOracleTable();
    final roll = DiceRoller.rollOracle(_moveOracle!.dice);
    final total = roll['total'] as int;

    // Find matching row
    for (final row in table.rows) {
      if (total >= row.minRoll && total <= row.maxRoll) {
        setState(() {
          _vignetteResult = row.result;
        });
        return;
      }
    }
    setState(() {
      _vignetteResult = 'No result (rolled $total)';
    });
  }

  // Step 2: Confirmation
  Widget _buildConfirmStep() {
    final gameProvider = context.read<GameProvider>();
    final character = gameProvider.currentGame?.mainCharacter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (_advancedClockNames.isNotEmpty) ...[
          const Text('Clocks advanced:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_advancedClockNames.map((name) => Text('  • $name'))),
          const SizedBox(height: 8),
        ],
        if (_vignetteResult != null) ...[
          const Text('Vignette:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('  $_vignetteResult'),
          const SizedBox(height: 8),
        ],
        if (character != null) ...[
          Text(
            '+1 momentum to ${character.handle ?? character.getHandle()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            'Current: ${character.momentum} → ${(character.momentum + 1).clamp(-6, character.maxMomentum)}',
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Skip'),
      ),
      if (_currentStep > 0)
        TextButton(
          onPressed: () => setState(() => _currentStep--),
          child: const Text('Back'),
        ),
      if (_currentStep < _totalSteps - 1)
        FilledButton(
          onPressed: () => setState(() => _currentStep++),
          child: const Text('Next'),
        ),
      if (_currentStep == _totalSteps - 1)
        FilledButton(
          onPressed: _apply,
          child: const Text('Begin Session'),
        ),
    ];
  }

  Future<void> _apply() async {
    final gameProvider = context.read<GameProvider>();
    final character = gameProvider.currentGame?.mainCharacter;

    // Apply +1 momentum
    if (character != null) {
      character.momentum = (character.momentum + 1).clamp(-6, character.maxMomentum);
    }

    // Build summary markdown
    final buffer = StringBuffer();
    buffer.writeln('## Begin a Session');
    buffer.writeln();
    if (widget.previousFocusNotes != null) {
      buffer.writeln('**Last session focus:** ${widget.previousFocusNotes}');
      buffer.writeln();
    }
    if (_advancedClockNames.isNotEmpty) {
      buffer.writeln('**Clocks advanced:**');
      for (final name in _advancedClockNames) {
        buffer.writeln('- $name');
      }
      buffer.writeln();
    }
    if (_vignetteResult != null) {
      buffer.writeln('**Vignette:** $_vignetteResult');
      buffer.writeln();
    }
    if (character != null) {
      buffer.writeln('**+1 momentum** to ${character.handle ?? character.getHandle()} (now ${character.momentum})');
    }

    // Create journal entry
    final entry = await gameProvider.createJournalEntry(buffer.toString().trim());
    entry.metadata = {'sourceScreen': 'session_move'};
    await gameProvider.saveGame();

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
