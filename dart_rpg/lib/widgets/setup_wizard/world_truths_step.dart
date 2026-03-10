import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/truth.dart';
import '../../providers/game_provider.dart';
import '../truths_widget.dart';

class WorldTruthsStep extends StatelessWidget {
  final Game game;
  final GameProvider gameProvider;
  final List<Truth> truths;

  const WorldTruthsStep({
    super.key,
    required this.game,
    required this.gameProvider,
    required this.truths,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Define the world your character will inhabit. Select or roll for each truth to establish the setting.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        TruthsWidget(
          game: game,
          gameProvider: gameProvider,
          truths: truths,
          initiallyExpanded: true,
          showHelpText: false,
        ),
      ],
    );
  }
}
