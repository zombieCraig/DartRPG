import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../models/character.dart';
import '../providers/game_provider.dart';
import '../widgets/quests/quest_dialog.dart';
import '../widgets/quests/quest_service.dart';
import '../widgets/quests/quest_tab_list.dart';

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
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize with the main character if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _questService = QuestService(gameProvider: gameProvider);
      
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
        
        // Ensure the quest service is initialized
        _questService = QuestService(gameProvider: gameProvider);
        
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
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateQuestDialog(context, charactersWithStats),
            tooltip: 'Create Quest',
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
}
