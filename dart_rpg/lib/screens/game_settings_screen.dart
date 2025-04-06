import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../models/game.dart';
import '../widgets/sentient_ai_settings_widget.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({Key? key}) : super(key: key);

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
              
              // Sentient AI settings
              SentientAiSettingsWidget(
                game: game,
                gameProvider: gameProvider,
                dataswornProvider: dataswornProvider,
                initiallyExpanded: true,
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
