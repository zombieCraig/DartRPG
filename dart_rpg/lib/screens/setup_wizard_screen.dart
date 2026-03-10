import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../transitions/navigation_service.dart';
import '../utils/logging_service.dart';
import '../widgets/setup_wizard/wizard_step_indicator.dart';
import '../widgets/setup_wizard/world_truths_step.dart';
import '../widgets/setup_wizard/faction_setup_step.dart';
import '../widgets/setup_wizard/character_creation_step.dart';
import '../widgets/setup_wizard/network_nodes_step.dart';
import '../widgets/setup_wizard/set_the_scene_step.dart';
import 'loading_screen.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  int _currentStep = 0;
  final _loggingService = LoggingService();
  final _sceneStepKey = GlobalKey<SetTheSceneStepState>();

  static const _stepLabels = [
    'Truths',
    'Factions',
    'Character',
    'Network',
    'Scene',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, DataswornProvider>(
      builder: (context, gameProvider, dataswornProvider, _) {
        final game = gameProvider.currentGame;
        if (game == null) {
          return const Scaffold(
            body: Center(child: Text('No game loaded')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Campaign Setup'),
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () => _skipAll(gameProvider, game.id, game.dataswornSource),
                child: const Text('Skip All'),
              ),
            ],
          ),
          body: Column(
            children: [
              WizardStepIndicator(
                currentStep: _currentStep,
                totalSteps: _stepLabels.length,
                stepLabels: _stepLabels,
              ),
              const Divider(),
              Expanded(
                child: _buildCurrentStep(game, gameProvider, dataswornProvider),
              ),
              _buildNavigationBar(gameProvider, game),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(
    dynamic game,
    GameProvider gameProvider,
    DataswornProvider dataswornProvider,
  ) {
    switch (_currentStep) {
      case 0:
        return SingleChildScrollView(
          child: WorldTruthsStep(
            game: game,
            gameProvider: gameProvider,
            truths: dataswornProvider.truths,
          ),
        );
      case 1:
        return SingleChildScrollView(
          child: FactionSetupStep(
            game: game,
            gameProvider: gameProvider,
          ),
        );
      case 2:
        return SingleChildScrollView(
          child: CharacterCreationStep(
            game: game,
            gameProvider: gameProvider,
          ),
        );
      case 3:
        return SingleChildScrollView(
          child: NetworkNodesStep(
            game: game,
            gameProvider: gameProvider,
          ),
        );
      case 4:
        return SetTheSceneStep(
          key: _sceneStepKey,
          game: game,
          gameProvider: gameProvider,
          dataswornProvider: dataswornProvider,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationBar(GameProvider gameProvider, dynamic game) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _currentStep--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            )
          else
            const SizedBox(width: 100),
          TextButton(
            onPressed: () => _skipStep(gameProvider, game),
            child: const Text('Skip'),
          ),
          if (_currentStep < _stepLabels.length - 1)
            ElevatedButton.icon(
              onPressed: () => setState(() => _currentStep++),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _finishWizard(gameProvider, game),
              icon: const Icon(Icons.check),
              label: const Text('Finish'),
            ),
        ],
      ),
    );
  }

  void _skipStep(GameProvider gameProvider, dynamic game) {
    if (_currentStep < _stepLabels.length - 1) {
      setState(() => _currentStep++);
    } else {
      _finishWizard(gameProvider, game);
    }
  }

  Future<void> _skipAll(
    GameProvider gameProvider,
    String gameId,
    String? dataswornSource,
  ) async {
    _loggingService.debug('Skipping all wizard steps', tag: 'SetupWizard');
    final game = gameProvider.currentGame;
    if (game != null) {
      game.setupWizardCompleted = true;
      await gameProvider.saveGame();
    }
    if (!mounted) return;
    _navigateToLoadingScreen(
      gameId,
      dataswornSource,
      game?.mainCharacter != null,
    );
  }

  Future<void> _finishWizard(GameProvider gameProvider, dynamic game) async {
    _loggingService.debug('Finishing wizard', tag: 'SetupWizard');

    // Create Session 0 and add scene text if provided
    final sceneText = _sceneStepKey.currentState?.sceneText ?? '';
    if (sceneText.isNotEmpty) {
      try {
        await gameProvider.createSession('Session 0');
        await gameProvider.createJournalEntry(sceneText);
      } catch (e) {
        _loggingService.error(
          'Error creating Session 0',
          tag: 'SetupWizard',
          error: e,
          stackTrace: StackTrace.current,
        );
      }
    }

    game.setupWizardCompleted = true;
    await gameProvider.saveGame();

    if (!mounted) return;
    _navigateToLoadingScreen(
      game.id,
      game.dataswornSource,
      game.mainCharacter != null,
    );
  }

  void _navigateToLoadingScreen(
    String gameId,
    String? dataswornSource,
    bool hasMainCharacter,
  ) {
    final navigationService = NavigationService();
    navigationService.replaceWith(
      context,
      LoadingScreen(
        gameId: gameId,
        dataswornSource: dataswornSource,
        hasMainCharacter: hasMainCharacter,
      ),
    );
  }
}
