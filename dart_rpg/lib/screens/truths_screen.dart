import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/truths_widget.dart';

class TruthsScreen extends StatelessWidget {
  const TruthsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DataswornProvider, GameProvider>(
      builder: (context, dataswornProvider, gameProvider, _) {
        final game = gameProvider.currentGame;

        if (game == null) {
          return const EmptyStateWidget(
            icon: Icons.public,
            message: 'No game loaded',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: TruthsWidget(
            game: game,
            gameProvider: gameProvider,
            truths: dataswornProvider.truths,
            initiallyExpanded: true,
            showHelpText: false,
          ),
        );
      },
    );
  }
}
