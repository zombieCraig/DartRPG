import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/truth.dart';
import '../../providers/datasworn_provider.dart';
import '../../providers/game_provider.dart';
import '../../services/oracle_service.dart';
import '../../utils/logging_service.dart';

class SetTheSceneStep extends StatefulWidget {
  final Game game;
  final GameProvider gameProvider;
  final DataswornProvider dataswornProvider;

  const SetTheSceneStep({
    super.key,
    required this.game,
    required this.gameProvider,
    required this.dataswornProvider,
  });

  @override
  State<SetTheSceneStep> createState() => SetTheSceneStepState();
}

class SetTheSceneStepState extends State<SetTheSceneStep> {
  final _sceneController = TextEditingController();
  final _loggingService = LoggingService();
  String? _lastOracleResult;

  @override
  void dispose() {
    _sceneController.dispose();
    super.dispose();
  }

  String get sceneText => _sceneController.text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the opening scene of your campaign. What is happening when we first meet your character?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Free text entry
          TextFormField(
            controller: _sceneController,
            decoration: const InputDecoration(
              labelText: 'Opening Scene',
              hintText: 'Describe your inciting incident...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // Oracle Inspiration section
          _buildOracleInspirationSection(context),
          const SizedBox(height: 24),

          // Quest Starters section
          _buildQuestStartersSection(context),
        ],
      ),
    );
  }

  Widget _buildQuestStartersSection(BuildContext context) {
    final questStarters = _getQuestStartersFromTruths();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quest Starters from World Truths',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (questStarters.isEmpty)
          const Text(
            'No quest starters available. Select world truths with quest starters in Step 1.',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          ...questStarters.map((starter) => Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        starter['truthName']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        starter['questStarter']!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            _sceneController.text = starter['questStarter']!;
                            setState(() {});
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Use'),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  List<Map<String, String>> _getQuestStartersFromTruths() {
    final starters = <Map<String, String>>[];
    final truths = widget.dataswornProvider.truths;

    for (final truth in truths) {
      final selectedOptionId = widget.game.getSelectedTruthOption(truth.id);
      if (selectedOptionId == null) continue;

      TruthOption? selectedOption;
      try {
        selectedOption = truth.options.firstWhere(
          (o) => o.id == selectedOptionId,
        );
      } catch (_) {
        continue;
      }

      if (selectedOption.questStarter != null) {
        starters.add({
          'truthName': truth.name,
          'questStarter': selectedOption.questStarter!,
        });
      }
    }

    return starters;
  }

  Widget _buildOracleInspirationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oracle Inspiration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _rollOracles('action', 'theme'),
              icon: const Icon(Icons.casino, size: 16),
              label: const Text('Action + Theme'),
            ),
            ElevatedButton.icon(
              onPressed: () => _rollOracles('descriptor', 'focus'),
              icon: const Icon(Icons.casino, size: 16),
              label: const Text('Descriptor + Focus'),
            ),
          ],
        ),
        if (_lastOracleResult != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _lastOracleResult!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final current = _sceneController.text;
                      if (current.isNotEmpty) {
                        _sceneController.text = '$current\n\n$_lastOracleResult';
                      } else {
                        _sceneController.text = _lastOracleResult!;
                      }
                      setState(() {});
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Use'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _rollOracles(String key1, String key2) async {
    final table1 = OracleService.findOracleTableByKeyAnywhere(
      key1,
      widget.dataswornProvider,
    );
    final table2 = OracleService.findOracleTableByKeyAnywhere(
      key2,
      widget.dataswornProvider,
    );

    if (table1 == null || table2 == null) {
      _loggingService.error(
        'Could not find oracle tables for $key1 and/or $key2',
        tag: 'SetTheSceneStep',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find oracle tables'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result1 = OracleService.rollOnOracleTable(table1);
    final result2 = OracleService.rollOnOracleTable(table2);

    if (result1['success'] && result2['success']) {
      setState(() {
        _lastOracleResult =
            '${result1['oracleRoll'].result} + ${result2['oracleRoll'].result}';
      });
    }
  }
}
