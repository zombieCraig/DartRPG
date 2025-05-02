import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../widgets/sentient_ai_settings_widget.dart';
import '../widgets/ai_image_generation_settings_widget.dart';
import '../widgets/truths_widget.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings'),
      ),
      body: Consumer2<GameProvider, DataswornProvider>(
        builder: (context, gameProvider, dataswornProvider, _) {
          final game = gameProvider.currentGame;
          
          if (game == null) {
            return const Center(
              child: Text('No game selected'),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Game name
              ListTile(
                title: const Text('Game Name'),
                subtitle: Text(game.name),
              ),
              
              // World Truths settings
              TruthsWidget(
                game: game,
                gameProvider: gameProvider,
                truths: dataswornProvider.truths,
                initiallyExpanded: true,
                showDividers: true,
                showHelpText: true,
              ),
              
              // Sentient AI settings
              SentientAiSettingsWidget(
                game: game,
                gameProvider: gameProvider,
                dataswornProvider: dataswornProvider,
                initiallyExpanded: false,
                showDividers: true,
                showHelpText: true,
              ),
              
              // AI Image Generation settings
              AiImageGenerationSettingsWidget(
                game: game,
                gameProvider: gameProvider,
                initiallyExpanded: false,
                showDividers: true,
                showHelpText: true,
              ),
              
              // Other game settings can be added here
            ],
          );
        },
      ),
    );
  }
}
