import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../models/character.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../widgets/progress_track_widget.dart';

class QuestsScreen extends StatefulWidget {
  final String gameId;
  
  const QuestsScreen({
    Key? key,
    required this.gameId,
  }) : super(key: key);
  
  @override
  _QuestsScreenState createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCharacterId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with the main character if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      final game = gameProvider.games.firstWhere(
        (g) => g.id == widget.gameId,
        orElse: () => throw Exception('Game not found'),
      );
      
      if (game.mainCharacter != null) {
        setState(() {
          _selectedCharacterId = game.mainCharacter!.id;
        });
      } else if (game.characters.isNotEmpty) {
        setState(() {
          _selectedCharacterId = game.characters.first.id;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final game = gameProvider.games.firstWhere(
          (g) => g.id == widget.gameId,
          orElse: () => throw Exception('Game not found'),
        );
        
        final charactersWithStats = game.getCharactersWithStats();
        
        // If no character is selected yet, select the first one
        if (_selectedCharacterId == null && charactersWithStats.isNotEmpty) {
          _selectedCharacterId = charactersWithStats.first.id;
        }
        
        // Get quests for the selected character
        final characterQuests = _selectedCharacterId != null
            ? game.getQuestsForCharacter(_selectedCharacterId!)
            : <Quest>[];
        
        // Filter quests by status
        final ongoingQuests = characterQuests
            .where((q) => q.status == QuestStatus.ongoing)
            .toList();
        final completedQuests = characterQuests
            .where((q) => q.status == QuestStatus.completed)
            .toList();
        final forsakenQuests = characterQuests
            .where((q) => q.status == QuestStatus.forsaken)
            .toList();
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quests'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Forsaken'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Character selector
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Character',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCharacterId,
                  items: charactersWithStats.map((character) {
                    return DropdownMenuItem<String>(
                      value: character.id,
                      child: Text(character.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCharacterId = value;
                    });
                  },
                ),
              ),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Ongoing quests tab
                    _buildQuestList(
                      context,
                      ongoingQuests,
                      charactersWithStats,
                      gameProvider,
                      QuestStatus.ongoing,
                    ),
                    
                    // Completed quests tab
                    _buildQuestList(
                      context,
                      completedQuests,
                      charactersWithStats,
                      gameProvider,
                      QuestStatus.completed,
                    ),
                    
                    // Forsaken quests tab
                    _buildQuestList(
                      context,
                      forsakenQuests,
                      charactersWithStats,
                      gameProvider,
                      QuestStatus.forsaken,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateQuestDialog(context, charactersWithStats, gameProvider),
            child: const Icon(Icons.add),
            tooltip: 'Create Quest',
          ),
        );
      },
    );
  }
  
  Widget _buildQuestList(
    BuildContext context,
    List<Quest> quests,
    List<Character> characters,
    GameProvider gameProvider,
    QuestStatus status,
  ) {
    if (quests.isEmpty) {
      return Center(
        child: Text(
          status == QuestStatus.ongoing
              ? 'No ongoing quests'
              : status == QuestStatus.completed
                  ? 'No completed quests'
                  : 'No forsaken quests',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    
    return ListView.builder(
      itemCount: quests.length,
      itemBuilder: (context, index) {
        final quest = quests[index];
        final character = characters.firstWhere(
          (c) => c.id == quest.characterId,
          orElse: () => throw Exception('Character not found'),
        );
        
        return QuestCardWidget(
          quest: quest,
          character: character,
          onProgressChanged: (value) {
            gameProvider.updateQuestProgress(quest.id, value);
          },
          onProgressRoll: () async {
            final result = await gameProvider.makeQuestProgressRoll(quest.id);
            if (context.mounted) {
              _showProgressRollResult(context, quest, result);
            }
          },
          onComplete: () {
            gameProvider.completeQuest(quest.id);
          },
          onForsake: () {
            gameProvider.forsakeQuest(quest.id);
          },
          onDelete: () {
            _showDeleteConfirmation(context, quest, gameProvider);
          },
          onNotesChanged: (notes) {
            gameProvider.updateQuestNotes(quest.id, notes);
          },
        );
      },
    );
  }
  
  void _showCreateQuestDialog(
    BuildContext context,
    List<Character> characters,
    GameProvider gameProvider,
  ) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to create a quest'),
        ),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateQuestDialog(characters: characters),
    );
    
    if (result != null && context.mounted) {
      gameProvider.createQuest(
        result['title'],
        result['characterId'],
        result['rank'],
        notes: result['notes'],
      );
    }
  }
  
  void _showProgressRollResult(
    BuildContext context,
    Quest quest,
    Map<String, dynamic> result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Progress Roll for "${quest.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${quest.progress}/10'),
            const SizedBox(height: 8),
            Text('Challenge Dice: ${result['challengeDice'][0]}, ${result['challengeDice'][1]}'),
            const SizedBox(height: 8),
            Text(
              'Outcome: ${result['outcome']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getOutcomeColor(result['outcome']),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Color _getOutcomeColor(String outcome) {
    if (outcome.contains('strong hit')) {
      return Colors.green;
    } else if (outcome.contains('weak hit')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  void _showDeleteConfirmation(
    BuildContext context,
    Quest quest,
    GameProvider gameProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              gameProvider.deleteQuest(quest.id);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestCardWidget extends StatefulWidget {
  final Quest quest;
  final Character character;
  final Function(int) onProgressChanged;
  final VoidCallback onProgressRoll;
  final VoidCallback onComplete;
  final VoidCallback onForsake;
  final VoidCallback onDelete;
  final Function(String) onNotesChanged;
  
  const QuestCardWidget({
    Key? key,
    required this.quest,
    required this.character,
    required this.onProgressChanged,
    required this.onProgressRoll,
    required this.onComplete,
    required this.onForsake,
    required this.onDelete,
    required this.onNotesChanged,
  }) : super(key: key);
  
  @override
  _QuestCardWidgetState createState() => _QuestCardWidgetState();
}

class _QuestCardWidgetState extends State<QuestCardWidget> {
  late TextEditingController _notesController;
  
  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.quest.notes);
  }
  
  @override
  void didUpdateWidget(QuestCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller text if the quest notes have changed
    // and the controller text is different (to avoid cursor jumping)
    if (widget.quest.notes != oldWidget.quest.notes && 
        widget.quest.notes != _notesController.text) {
      _notesController.text = widget.quest.notes;
    }
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.quest.rank.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and rank
            Row(
              children: [
                Icon(widget.quest.rank.icon, color: widget.quest.rank.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.quest.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            
            // Character association
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Character: ${widget.character.name}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Rank display
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Rank: ${widget.quest.rank.displayName}',
                    style: TextStyle(
                      color: widget.quest.rank.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress track
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ProgressTrackWidget(
                label: 'Progress',
                value: widget.quest.progress,
                ticks: widget.quest.progressTicks,
                maxValue: 10,
                onBoxChanged: widget.quest.status == QuestStatus.ongoing 
                    ? widget.onProgressChanged 
                    : null,
                onTickChanged: widget.quest.status == QuestStatus.ongoing
                    ? (ticks) => widget.onProgressChanged(ticks ~/ 4)
                    : null,
                isEditable: widget.quest.status == QuestStatus.ongoing,
                showTicks: true,
              ),
            ),
            
            // Progress buttons (only for ongoing quests)
            if (widget.quest.status == QuestStatus.ongoing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Decrease'),
                    onPressed: () {
                      // Use the GameProvider method to remove ticks based on quest rank
                      Provider.of<GameProvider>(context, listen: false)
                          .removeQuestTicksForRank(widget.quest.id);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Advance'),
                    onPressed: () {
                      // Use the GameProvider method to add ticks based on quest rank
                      Provider.of<GameProvider>(context, listen: false)
                          .addQuestTicksForRank(widget.quest.id);
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.casino),
                    label: const Text('Progress Roll'),
                    onPressed: widget.onProgressRoll,
                  ),
                ],
              ),
            
            // Notes section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                controller: _notesController,
                onChanged: widget.onNotesChanged,
                enabled: widget.quest.status == QuestStatus.ongoing,
                textDirection: TextDirection.ltr, // Ensure left-to-right text direction
              ),
            ),
            
            // Status buttons (only for ongoing quests)
            if (widget.quest.status == QuestStatus.ongoing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Forsake'),
                    onPressed: widget.onForsake,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Complete'),
                    onPressed: widget.onComplete,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            
            // Delete button (for all quests)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                onPressed: widget.onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateQuestDialog extends StatefulWidget {
  final List<Character> characters;
  
  const CreateQuestDialog({
    Key? key,
    required this.characters,
  }) : super(key: key);
  
  @override
  _CreateQuestDialogState createState() => _CreateQuestDialogState();
}

class _CreateQuestDialogState extends State<CreateQuestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  QuestRank _selectedRank = QuestRank.troublesome;
  String? _selectedCharacterId;
  
  @override
  void initState() {
    super.initState();
    if (widget.characters.isNotEmpty) {
      _selectedCharacterId = widget.characters.first.id;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Quest'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Quest Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Character dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Character',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCharacterId,
                items: widget.characters.map((character) {
                  return DropdownMenuItem<String>(
                    value: character.id,
                    child: Text(character.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCharacterId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a character';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Rank dropdown
              DropdownButtonFormField<QuestRank>(
                decoration: const InputDecoration(
                  labelText: 'Quest Rank',
                  border: OutlineInputBorder(),
                ),
                value: _selectedRank,
                items: QuestRank.values.map((rank) {
                  return DropdownMenuItem<QuestRank>(
                    value: rank,
                    child: Row(
                      children: [
                        Icon(rank.icon, color: rank.color, size: 16),
                        const SizedBox(width: 8),
                        Text(rank.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRank = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Quest Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textDirection: TextDirection.ltr, // Ensure left-to-right text direction
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'characterId': _selectedCharacterId,
                'rank': _selectedRank,
                'notes': _notesController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
