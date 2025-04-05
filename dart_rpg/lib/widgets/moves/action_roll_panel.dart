import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/move.dart';
import '../../models/character.dart';
import '../../providers/game_provider.dart';

/// A panel for handling action rolls.
class ActionRollPanel extends StatefulWidget {
  final Move move;
  final Function(Move, String, int, int) onRoll;
  
  const ActionRollPanel({
    super.key,
    required this.move,
    required this.onRoll,
  });
  
  @override
  State<ActionRollPanel> createState() => _ActionRollPanelState();
}

class _ActionRollPanelState extends State<ActionRollPanel> {
  String? _selectedStat;
  final TextEditingController _modifierController = TextEditingController();
  
  @override
  void dispose() {
    _modifierController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final character = gameProvider.currentGame?.mainCharacter;
    
    // Get all available options (stats and condition meters)
    final availableOptions = widget.move.getAvailableOptions();
    
    // If this move uses a special method (highest or lowest), determine which option to use
    if (widget.move.hasSpecialMethod()) {
      final specialMethod = widget.move.getSpecialMethod();
      Map<String, dynamic>? selectedOption;
      int selectedValue = specialMethod == 'highest' ? -1 : 999; // Start with extreme values
      
      for (var option in availableOptions) {
        int value = 0;
        
        if (option['using'] == 'stat' && character != null) {
          // Get stat value
          final statName = option['stat'];
          final characterStat = character.stats.firstWhere(
            (s) => s.name.toLowerCase() == statName.toLowerCase(),
            orElse: () => CharacterStat(name: statName, value: 0),
          );
          value = characterStat.value;
        } else if (option['using'] == 'condition_meter' && character != null) {
          // Get condition meter value
          final meterName = option['condition_meter'];
          value = character.getConditionMeterValue(meterName) ?? 0;
        }
        
        if ((specialMethod == 'highest' && value > selectedValue) ||
            (specialMethod == 'lowest' && value < selectedValue)) {
          selectedValue = value;
          selectedOption = option;
        }
      }
      
      // Use only the selected option
      if (selectedOption != null) {
        availableOptions.clear();
        availableOptions.add(selectedOption);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display a message if using a special method
        if (widget.move.hasSpecialMethod()) ...[
          Text(
            'This move uses the ${widget.move.getSpecialMethod()} value option:',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
        ],
        
        // Option selection
        const Text(
          'Select Option:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        if (character != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableOptions.map((option) {
              // Get the display name and value
              String name;
              int value = 0;
              
              if (option['using'] == 'stat') {
                name = option['stat'];
                final characterStat = character.stats.firstWhere(
                  (s) => s.name.toLowerCase() == name.toLowerCase(),
                  orElse: () => CharacterStat(name: name, value: 0),
                );
                value = characterStat.value;
              } else if (option['using'] == 'condition_meter') {
                name = option['condition_meter'];
                value = character.getConditionMeterValue(name) ?? 0;
              } else {
                // Fallback for unknown option types
                name = option['using'] ?? 'Unknown';
              }
              
              return ChoiceChip(
                label: Text('$name ($value)'),
                selected: _selectedStat == name,
                onSelected: (selected) {
                  setState(() {
                    _selectedStat = selected ? name : null;
                  });
                },
              );
            }).toList(),
          ),
          
          // Only show modifier field if an option is selected
          if (_selectedStat != null) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _modifierController,
              decoration: const InputDecoration(
                labelText: 'Optional Modifier',
                hintText: 'e.g., +2, -1',
                helperText: 'One-time adjustment to Action Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
            ),
            
            const SizedBox(height: 16),
            
            // Roll button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sports_martial_arts),
                label: const Text('Roll Dice'),
                onPressed: () {
                  if (_selectedStat != null) {
                    // Find the stat value
                    int statValue = 0;
                    for (final s in character.stats) {
                      if (s.name.toLowerCase() == _selectedStat!.toLowerCase()) {
                        statValue = s.value;
                        break;
                      }
                    }
                    
                    // Parse the optional modifier
                    int modifier = 0;
                    if (_modifierController.text.isNotEmpty) {
                      modifier = int.tryParse(_modifierController.text) ?? 0;
                    }
                    
                    // Call the onRoll callback
                    widget.onRoll(widget.move, _selectedStat!, statValue, modifier);
                  }
                },
              ),
            ),
          ],
        ] else ...[
          const Text('No main character selected'),
        ],
      ],
    );
  }
}
