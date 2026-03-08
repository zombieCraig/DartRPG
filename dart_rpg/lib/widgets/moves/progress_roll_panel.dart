import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/move.dart';
import '../../models/quest.dart';
import '../../models/connection.dart';
import '../../providers/game_provider.dart';

/// A panel for handling progress rolls.
///
/// This panel allows users to either:
/// 1. Select an existing quest and use its progress value
/// 2. Select a connection and use its progress value (Forge a Bond)
/// 3. Manually set a progress value using a slider
class ProgressRollPanel extends StatefulWidget {
  final Move move;
  final Function(Move, int) onRoll;
  final Function(Move, String)? onQuestRoll;

  const ProgressRollPanel({
    super.key,
    required this.move,
    required this.onRoll,
    this.onQuestRoll,
  });

  @override
  State<ProgressRollPanel> createState() => _ProgressRollPanelState();
}

enum _ProgressMode { quest, connection, manual }

class _ProgressRollPanelState extends State<ProgressRollPanel> {
  int _progressValue = 5;
  _ProgressMode _mode = _ProgressMode.quest;
  String? _selectedQuestId;
  String? _selectedConnectionId;
  List<Quest> _quests = [];
  List<Connection> _connections = [];
  final FocusNode _rollButtonFocusNode = FocusNode();
  final GlobalKey _rollButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final game = gameProvider.currentGame;
    if (game == null) {
      setState(() => _mode = _ProgressMode.manual);
      return;
    }

    setState(() {
      _quests = game.quests
          .where((q) => q.status == QuestStatus.ongoing)
          .toList();
      _connections = game.connections
          .where((c) => c.status == ConnectionStatus.active)
          .toList();

      if (_quests.isNotEmpty) {
        _selectedQuestId = _quests.first.id;
        _progressValue = _quests.first.progress;
      } else if (_connections.isNotEmpty) {
        _mode = _ProgressMode.connection;
        _selectedConnectionId = _connections.first.id;
        _progressValue = _connections.first.progress;
      } else {
        _mode = _ProgressMode.manual;
      }
    });
  }

  void _onQuestSelected(String? questId) {
    if (questId != null) {
      final quest = _quests.firstWhere((q) => q.id == questId);
      setState(() {
        _selectedQuestId = questId;
        _progressValue = quest.progress;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusRollButton());
    }
  }

  void _onConnectionSelected(String? connectionId) {
    if (connectionId != null) {
      final connection = _connections.firstWhere((c) => c.id == connectionId);
      setState(() {
        _selectedConnectionId = connectionId;
        _progressValue = connection.progress;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusRollButton());
    }
  }

  void _focusRollButton() {
    _rollButtonFocusNode.requestFocus();
    final context = _rollButtonKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _rollButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode selection tabs
        Row(
          children: [
            _buildModeTab('Quest', _ProgressMode.quest),
            _buildModeTab('Connection', _ProgressMode.connection),
            _buildModeTab('Manual', _ProgressMode.manual),
          ],
        ),

        const SizedBox(height: 16),

        // Content based on mode
        if (_mode == _ProgressMode.quest) ...[
          _buildQuestSection(),
        ] else if (_mode == _ProgressMode.connection) ...[
          _buildConnectionSection(),
        ] else ...[
          _buildManualSection(),
        ],

        const SizedBox(height: 16),

        // Roll button
        Center(
          child: ElevatedButton.icon(
            key: _rollButtonKey,
            focusNode: _rollButtonFocusNode,
            icon: const Icon(Icons.trending_up),
            label: const Text('Perform Move'),
            onPressed: () {
              if (_mode == _ProgressMode.quest && _selectedQuestId != null && widget.onQuestRoll != null) {
                widget.onQuestRoll!(widget.move, _selectedQuestId!);
              } else {
                widget.onRoll(widget.move, _progressValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(String label, _ProgressMode mode) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _mode == mode ? Theme.of(context).primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: _mode == mode ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Quest:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_quests.isEmpty)
          const Text('No ongoing quests available')
        else
          DropdownButtonFormField<String>(
            value: _selectedQuestId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _quests.map((quest) => DropdownMenuItem<String>(
              value: quest.id,
              child: Text('${quest.title} (Progress: ${quest.progress}/10)'),
            )).toList(),
            onChanged: _onQuestSelected,
          ),
        if (_selectedQuestId != null) ...[
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ],
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Connection:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_connections.isEmpty)
          const Text('No active connections available')
        else
          DropdownButtonFormField<String>(
            value: _selectedConnectionId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _connections.map((conn) => DropdownMenuItem<String>(
              value: conn.id,
              child: Text('${conn.name} - ${conn.role} (Progress: ${conn.progress}/10)'),
            )).toList(),
            onChanged: _onConnectionSelected,
          ),
        if (_selectedConnectionId != null) ...[
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ],
    );
  }

  Widget _buildManualSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          value: _progressValue.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          label: _progressValue.toString(),
          onChanged: (value) {
            setState(() {
              _progressValue = value.round();
              WidgetsBinding.instance.addPostFrameCallback((_) => _focusRollButton());
            });
          },
        ),
        Center(
          child: Text(
            'Progress: $_progressValue',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _progressValue / 10,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Progress: $_progressValue/10',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
