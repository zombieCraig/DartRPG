import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../models/character.dart';
import '../models/clock.dart';
import '../providers/game_provider.dart';
import '../widgets/quests/quest_dialog.dart';
import '../widgets/quests/quest_service.dart';
import '../widgets/quests/quest_tab_list.dart';
import '../widgets/clocks/clock_dialog.dart';
import '../widgets/clocks/clock_service.dart';
import '../widgets/clocks/clocks_tab_view.dart';

/// A screen for managing quests
class QuestsScreen extends StatefulWidget {
  /// The ID of the game
  final String gameId;
  
  /// Creates a new QuestsScreen
  const QuestsScreen({
    super.key,
    required this.gameId,
  });
  
  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCharacterId;
  late QuestService _questService;
  late ClockService _clockService;
  bool _showCharacterSelector = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Listen for tab changes to show/hide character selector
    _tabController.addListener(() {
      setState(() {
        _showCharacterSelector = _tabController.index < 3;
      });
    });
    
    // Initialize with the main character if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _questService = QuestService(gameProvider: gameProvider);
      _clockService = ClockService(gameProvider: gameProvider);
      
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
        
        // Ensure the services are initialized
        _questService = QuestService(gameProvider: gameProvider);
        _clockService = ClockService(gameProvider: gameProvider);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Quests'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Forsaken'),
                Tab(text: 'Clocks'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Character selector (only for quest tabs)
              if (_showCharacterSelector)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Character',
                      border: OutlineInputBorder(),
                      hintText: 'Select a character',
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
                    QuestTabList(
                      quests: ongoingQuests,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.ongoing,
                    ),
                    
                    // Completed quests tab
                    QuestTabList(
                      quests: completedQuests,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.completed,
                    ),
                    
                    // Forsaken quests tab
                    QuestTabList(
                      quests: forsakenQuests,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.forsaken,
                    ),
                    
                    // Clocks tab
                    ClocksTabView(
                      gameId: widget.gameId,
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Show different dialogs based on the selected tab
              if (_tabController.index == 3) {
                // Clocks tab
                _showCreateClockDialog(context);
              } else {
                // Quest tabs
                _showCreateQuestDialog(context, charactersWithStats);
              }
            },
            tooltip: _tabController.index == 3 ? 'Create Clock' : 'Create Quest',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
  
  /// Show a dialog to create a new quest
  void _showCreateQuestDialog(
    BuildContext context,
    List<Character> characters,
  ) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to create a quest'),
        ),
      );
      return;
    }
    
    final result = await QuestDialog.showCreateDialog(
      context: context,
      characters: characters,
    );
    
    if (result != null && context.mounted) {
      await _questService.createQuest(
        title: result['title'],
        characterId: result['characterId'],
        rank: result['rank'],
        notes: result['notes'],
      );
    }
  }
  
  /// Show a dialog to create a new clock
  void _showCreateClockDialog(BuildContext context) async {
    final result = await ClockDialog.showCreateDialog(
      context: context,
    );
    
    if (result != null && context.mounted) {
      await _clockService.createClock(
        title: result['title'],
        segments: result['segments'],
        type: result['type'],
      );
    }
  }
}
