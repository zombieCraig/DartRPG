import 'package:flutter/material.dart';
import '../models/truth.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../utils/dice_roller.dart';
import '../utils/logging_service.dart';

/// A widget to display and manage world truths for a game
class TruthsWidget extends StatefulWidget {
  final Game game;
  final GameProvider gameProvider;
  final List<Truth> truths;
  final bool initiallyExpanded;
  final bool showDividers;
  final bool showHelpText;

  const TruthsWidget({
    Key? key,
    required this.game,
    required this.gameProvider,
    required this.truths,
    this.initiallyExpanded = false,
    this.showDividers = true,
    this.showHelpText = true,
  }) : super(key: key);

  @override
  State<TruthsWidget> createState() => _TruthsWidgetState();
}

class _TruthsWidgetState extends State<TruthsWidget> {
  bool _isExpanded = false;
  final LoggingService _loggingService = LoggingService();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // Expansion tile for the section
          ExpansionTile(
            title: const Text(
              'World Truths',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: widget.showHelpText
                ? const Text('Define the world your character inhabits')
                : null,
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Roll All button
                IconButton(
                  icon: const Icon(Icons.casino),
                  tooltip: 'Roll on all truths',
                  onPressed: _rollAllTruths,
                ),
                // Default expansion/collapse icon
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ],
            ),
          ),
          
          // Truth content (only visible when expanded)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List of truths
                  ...widget.truths.map((truth) => _buildTruthItem(truth)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTruthItem(Truth truth) {
    // Get the currently selected option ID (if any)
    final selectedOptionId = widget.game.getSelectedTruthOption(truth.id);
    
    // Find the selected option object
    TruthOption? selectedOption;
    if (selectedOptionId != null) {
      try {
        selectedOption = truth.options.firstWhere(
          (option) => option.id == selectedOptionId,
        );
        _loggingService.debug(
          'Found selected option: ${selectedOption.summary}',
          tag: 'TruthsWidget'
        );
      } catch (e) {
        _loggingService.error(
          'Failed to find selected option with ID $selectedOptionId',
          tag: 'TruthsWidget',
          error: e,
          stackTrace: StackTrace.current
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Truth name and roll button
        Row(
          children: [
            Expanded(
              child: Text(
                truth.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.casino, size: 20),
              tooltip: 'Roll on this truth',
              onPressed: () => _rollTruth(truth),
            ),
          ],
        ),
        
        // Truth question
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            truth.question,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
        
        // Dropdown for selecting an option
        DropdownButtonFormField<String?>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: selectedOptionId,
          hint: const Text('None Selected'),
          onChanged: (newValue) {
            _selectTruthOption(truth.id, newValue);
          },
          items: [
            // "None Selected" option
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None Selected'),
            ),
            // Options from the truth
            ...truth.options.map((option) {
              return DropdownMenuItem<String?>(
                value: option.id,
                child: Text(option.summary),
              );
            }),
          ],
        ),
        
        // Selected option description (if any)
        if (selectedOption != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedOption.description,
                  style: const TextStyle(fontSize: 14),
                ),
                if (selectedOption.questStarter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quest Starter:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          selectedOption.questStarter!,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        
        // Divider between truths
        if (widget.showDividers && widget.truths.last != truth)
          const Divider(height: 32),
      ],
    );
  }

  void _selectTruthOption(String truthId, String? optionId) {
    _loggingService.debug(
      'Setting truth $truthId to option $optionId',
      tag: 'TruthsWidget'
    );
    
    widget.game.setTruth(truthId, optionId);
    widget.gameProvider.saveGame();
    setState(() {});
  }

  void _rollTruth(Truth truth) {
    _loggingService.debug(
      'Rolling on truth: ${truth.name} with dice ${truth.dice}',
      tag: 'TruthsWidget'
    );
    
    // Parse the dice string (e.g., "1d100")
    final diceResult = DiceRoller.rollDiceNotation(truth.dice);
    final diceRoll = diceResult.reduce((sum, die) => sum + die); // Sum the dice
    _loggingService.debug(
      'Rolled $diceRoll on ${truth.dice}',
      tag: 'TruthsWidget'
    );
    
    // Find the option that matches the roll
    for (final option in truth.options) {
      if (diceRoll >= option.minRoll && diceRoll <= option.maxRoll) {
        _loggingService.debug(
          'Roll $diceRoll matches option: ${option.summary} (${option.minRoll}-${option.maxRoll})',
          tag: 'TruthsWidget'
        );
        
        // Select this option
        _selectTruthOption(truth.id, option.id);
        break;
      }
    }
  }

  void _rollAllTruths() {
    _loggingService.debug(
      'Rolling on all truths',
      tag: 'TruthsWidget'
    );
    
    for (final truth in widget.truths) {
      _rollTruth(truth);
    }
  }
}
