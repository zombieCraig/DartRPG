import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/connection.dart';
import '../../models/quest.dart';
import '../../providers/game_provider.dart';

/// Multi-step dialog implementing the "End a Session" move.
///
/// Steps:
/// 0. Connections — catch-up progress
/// 1. Quests — catch-up milestones
/// 2. Focus notes for next session
/// 3. Confirm and apply (+1 momentum, journal entry)
class EndSessionDialog extends StatefulWidget {
  const EndSessionDialog({super.key});

  @override
  State<EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<EndSessionDialog> {
  int _currentStep = 0;
  final List<String> _markedConnectionNames = [];
  final List<String> _markedQuestTitles = [];
  final TextEditingController _focusController = TextEditingController();

  static const _totalSteps = 4;

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('End a Session')),
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
        return _buildConnectionsStep();
      case 1:
        return _buildQuestsStep();
      case 2:
        return _buildFocusStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Connections
  Widget _buildConnectionsStep() {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final activeConnections = game.connections
        .where((c) => c.status == ConnectionStatus.active)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Connections — Catch-up Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Mark progress on connections you interacted with this session.'),
        const SizedBox(height: 16),
        if (activeConnections.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No active connections.'),
          )
        else
          ...activeConnections.map((conn) => _buildConnectionTile(conn, gameProvider)),
      ],
    );
  }

  Widget _buildConnectionTile(Connection connection, GameProvider gameProvider) {
    final wasMarked = _markedConnectionNames.contains(connection.name);
    return Card(
      child: ListTile(
        title: Text(connection.name),
        subtitle: Text('${connection.role} • ${connection.rank.displayName} • ${connection.progress}/10'),
        trailing: wasMarked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton.tonal(
                onPressed: () async {
                  await gameProvider.addConnectionTicksForRank(connection.id);
                  setState(() {
                    _markedConnectionNames.add(connection.name);
                  });
                },
                child: const Text('Mark Progress'),
              ),
      ),
    );
  }

  // Step 1: Quests
  Widget _buildQuestsStep() {
    final gameProvider = context.read<GameProvider>();
    final game = gameProvider.currentGame;
    if (game == null) return const SizedBox.shrink();

    final ongoingQuests = game.quests
        .where((q) => q.status == QuestStatus.ongoing)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Quests — Catch-up Milestones',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Mark progress on quests you advanced this session.'),
        const SizedBox(height: 16),
        if (ongoingQuests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No ongoing quests.'),
          )
        else
          ...ongoingQuests.map((quest) => _buildQuestTile(quest, gameProvider)),
      ],
    );
  }

  Widget _buildQuestTile(Quest quest, GameProvider gameProvider) {
    final wasMarked = _markedQuestTitles.contains(quest.title);
    return Card(
      child: ListTile(
        title: Text(quest.title),
        subtitle: Text('${quest.rank.displayName} • ${quest.progress}/10'),
        trailing: wasMarked
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton.tonal(
                onPressed: () async {
                  await gameProvider.addQuestTicksForRank(quest.id);
                  setState(() {
                    _markedQuestTitles.add(quest.title);
                  });
                },
                child: const Text('Reach Milestone'),
              ),
      ),
    );
  }

  // Step 2: Focus notes
  Widget _buildFocusStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Focus Notes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text('Optionally note what to focus on next session.'),
        const SizedBox(height: 16),
        TextField(
          controller: _focusController,
          decoration: const InputDecoration(
            labelText: 'Next session focus',
            hintText: 'What do you want to tackle next time?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // Step 3: Confirmation
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
        if (_markedConnectionNames.isNotEmpty) ...[
          const Text('Connections progressed:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_markedConnectionNames.map((name) => Text('  • $name'))),
          const SizedBox(height: 8),
        ],
        if (_markedQuestTitles.isNotEmpty) ...[
          const Text('Quests progressed:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_markedQuestTitles.map((title) => Text('  • $title'))),
          const SizedBox(height: 8),
        ],
        if (_focusController.text.isNotEmpty) ...[
          const Text('Next session focus:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('  ${_focusController.text}'),
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
          child: const Text('End Session'),
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
    buffer.writeln('## End a Session');
    buffer.writeln();
    if (_markedConnectionNames.isNotEmpty) {
      buffer.writeln('**Connections progressed:**');
      for (final name in _markedConnectionNames) {
        buffer.writeln('- $name');
      }
      buffer.writeln();
    }
    if (_markedQuestTitles.isNotEmpty) {
      buffer.writeln('**Quests progressed:**');
      for (final title in _markedQuestTitles) {
        buffer.writeln('- $title');
      }
      buffer.writeln();
    }
    if (_focusController.text.isNotEmpty) {
      buffer.writeln('**Next session focus:** ${_focusController.text}');
      buffer.writeln();
    }
    if (character != null) {
      buffer.writeln('**+1 momentum** to ${character.handle ?? character.getHandle()} (now ${character.momentum})');
    }

    // Create journal entry
    final entry = await gameProvider.createJournalEntry(buffer.toString().trim());
    entry.metadata = {
      'sourceScreen': 'session_move',
      if (_focusController.text.isNotEmpty)
        'focusNotes': _focusController.text,
    };
    await gameProvider.saveGame();

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
