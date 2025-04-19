import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/move.dart';
import '../../models/quest.dart';
import '../../providers/game_provider.dart';

/// A panel for handling progress rolls.
/// 
/// This panel allows users to either:
/// 1. Select an existing quest and use its progress value
/// 2. Manually set a progress value using a slider
class ProgressRollPanel extends StatefulWidget {
  final Move move;
  final Function(Move, int) onRoll;
  final Function(Move, String)? onQuestRoll; // New callback for quest rolls
  
  const ProgressRollPanel({
    super.key,
    required this.move,
    required this.onRoll,
    this.onQuestRoll,
  });
  
  @override
  State<ProgressRollPanel> createState() => _ProgressRollPanelState();
}

class _ProgressRollPanelState extends State<ProgressRollPanel> {
  int _progressValue = 5; // Default progress value
  bool _useQuestProgress = true; // Default to quest progress mode
  String? _selectedQuestId;
  List<Quest> _quests = [];
  final FocusNode _rollButtonFocusNode = FocusNode();
  final GlobalKey _rollButtonKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    // Fetch quests when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuests();
    });
  }
  
  void _loadQuests() {
    // Get quests from GameProvider
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (gameProvider.currentGame != null) {
      setState(() {
        // Filter to only ongoing quests
        _quests = gameProvider.currentGame!.quests
            .where((q) => q.status == QuestStatus.ongoing)
            .toList();
        
        // Select the first quest by default if available
        if (_quests.isNotEmpty) {
          _selectedQuestId = _quests.first.id;
          _progressValue = _quests.first.progress;
        } else {
          // If no quests are available, switch to manual mode
          _useQuestProgress = false;
        }
      });
    } else {
      // If no game is loaded, switch to manual mode
      setState(() {
        _useQuestProgress = false;
      });
    }
  }
  
  void _onQuestSelected(String? questId) {
    if (questId != null) {
      final quest = _quests.firstWhere((q) => q.id == questId);
      setState(() {
        _selectedQuestId = questId;
        _progressValue = quest.progress;
      });
      
      // Schedule a post-frame callback to focus and scroll to the roll button
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusRollButton();
      });
    }
  }
  
  void _focusRollButton() {
    // Focus the roll button
    _rollButtonFocusNode.requestFocus();
    
    // Scroll to make the roll button visible
    final context = _rollButtonKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5, // Center the button in the viewport
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
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _useQuestProgress = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _useQuestProgress ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Quest Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _useQuestProgress = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: !_useQuestProgress ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Manual Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Quest selection or manual progress based on mode
        if (_useQuestProgress) ...[
          const Text(
            'Select Quest:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Quest dropdown
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
          
          const SizedBox(height: 16),
          
          // Display selected quest progress
          if (_selectedQuestId != null) ...[
            const Text(
              'Quest Progress:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Progress indicator
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
        ] else ...[
          // Manual progress selection
          const Text(
            'Select Progress:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Progress slider
          Slider(
            value: _progressValue.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _progressValue.toString(),
            onChanged: (value) {
              setState(() {
                _progressValue = value.round();
                
                // Schedule a post-frame callback to focus and scroll to the roll button
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _focusRollButton();
                });
              });
            },
          ),
          
          // Progress value indicator
          Center(
            child: Text(
              'Progress: $_progressValue',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
              if (_useQuestProgress && _selectedQuestId != null && widget.onQuestRoll != null) {
                // Use the quest-specific callback
                widget.onQuestRoll!(widget.move, _selectedQuestId!);
              } else {
                // Use regular callback for manual progress
                widget.onRoll(widget.move, _progressValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
