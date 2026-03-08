import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/quest.dart';
import '../models/character.dart';
import '../models/connection.dart';
import '../providers/game_provider.dart';
import '../widgets/quests/quest_dialog.dart';
import '../widgets/quests/quest_service.dart';
import '../widgets/quests/quest_tab_list.dart';
import '../widgets/connections/connection_dialog.dart';
import '../widgets/connections/connection_service.dart';
import '../widgets/connections/connection_tab_list.dart';
import '../widgets/clocks/clock_dialog.dart';
import '../widgets/clocks/clock_service.dart';
import '../widgets/clocks/clocks_tab_view.dart';

/// A screen for managing quests, connections, and clocks
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
  late ConnectionService _connectionService;
  late ClockService _clockService;
  bool _showCharacterSelector = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Listen for tab changes to show/hide character selector
    _tabController.addListener(() {
      setState(() {
        // Show character selector for quest tabs (0-2) and connections tab (3)
        _showCharacterSelector = _tabController.index < 4;
      });
    });

    // Initialize with the main character if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      _questService = QuestService(gameProvider: gameProvider);
      _connectionService = ConnectionService(gameProvider: gameProvider);
      _clockService = ClockService(gameProvider: gameProvider);

      final game = gameProvider.games.firstWhereOrNull(
        (g) => g.id == widget.gameId,
      );
      if (game == null) return;

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

  Map<QuestStatus, List<Quest>> _getQuestsByStatus(dynamic game) {
    final characterQuests = _selectedCharacterId != null
        ? game.getQuestsForCharacter(_selectedCharacterId!)
        : <Quest>[];
    return {
      for (final status in QuestStatus.values)
        status: characterQuests.where((q) => q.status == status).toList(),
    };
  }

  List<Connection> _getConnections(dynamic game) {
    if (_selectedCharacterId == null) return <Connection>[];
    return game.getConnectionsForCharacter(_selectedCharacterId!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final game = gameProvider.games.firstWhereOrNull(
          (g) => g.id == widget.gameId,
        );
        if (game == null) {
          return const Center(child: Text('Game not found'));
        }

        final charactersWithStats = game.getCharactersWithStats();

        // If no character is selected yet, select the first one
        if (_selectedCharacterId == null && charactersWithStats.isNotEmpty) {
          _selectedCharacterId = charactersWithStats.first.id;
        }

        final questsByStatus = _getQuestsByStatus(game);
        final connections = _getConnections(game);

        // Ensure the services are initialized
        _questService = QuestService(gameProvider: gameProvider);
        _connectionService = ConnectionService(gameProvider: gameProvider);
        _clockService = ClockService(gameProvider: gameProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quests'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Forsaken'),
                Tab(text: 'Connections'),
                Tab(text: 'Clocks'),
              ],
            ),
          ),
          body: Column(
            children: [
              // Character selector (for quest and connection tabs)
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
                      quests: questsByStatus[QuestStatus.ongoing]!,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.ongoing,
                    ),

                    // Completed quests tab
                    QuestTabList(
                      quests: questsByStatus[QuestStatus.completed]!,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.completed,
                    ),

                    // Forsaken quests tab
                    QuestTabList(
                      quests: questsByStatus[QuestStatus.forsaken]!,
                      characters: charactersWithStats,
                      questService: _questService,
                      status: QuestStatus.forsaken,
                    ),

                    // Connections tab
                    ConnectionTabList(
                      connections: connections,
                      characters: charactersWithStats,
                      connectionService: _connectionService,
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
              if (_tabController.index == 4) {
                _showCreateClockDialog(context);
              } else if (_tabController.index == 3) {
                _showCreateConnectionDialog(context, charactersWithStats);
              } else {
                _showCreateQuestDialog(context, charactersWithStats);
              }
            },
            tooltip: _tabController.index == 4
                ? 'Create Clock'
                : _tabController.index == 3
                    ? 'Make a Connection'
                    : 'Create Quest',
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

  /// Show a dialog to create a new connection
  void _showCreateConnectionDialog(
    BuildContext context,
    List<Character> characters,
  ) async {
    if (characters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No characters available to create a connection'),
        ),
      );
      return;
    }

    final result = await ConnectionDialog.showCreateDialog(
      context: context,
      characters: characters,
    );

    if (result != null && context.mounted) {
      await _connectionService.createConnection(
        name: result['name'],
        characterId: result['characterId'],
        rank: result['rank'],
        role: result['role'],
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
