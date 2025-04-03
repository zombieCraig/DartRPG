import 'package:flutter/material.dart';
import '../models/character.dart';
import '../widgets/stat_adjuster_widget.dart';
import '../widgets/compact_stat_widget.dart';
import '../providers/game_provider.dart';
import 'package:provider/provider.dart';

class CharacterStatsCard extends StatefulWidget {
  final Character character;
  final VoidCallback? onEdit;

  const CharacterStatsCard({
    super.key,
    required this.character,
    this.onEdit,
  });

  @override
  State<CharacterStatsCard> createState() => _CharacterStatsCardState();
}

class _CharacterStatsCardState extends State<CharacterStatsCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character name and edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${widget.character.name} aka ${widget.character.getHandle()}",
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: widget.onEdit,
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Character stats in a Wrap widget
              if (widget.character.isMainCharacter) ...[
                // Game stats (momentum, health, etc.)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.start,
                  children: [
                    StatAdjusterWidget(
                      label: 'MOMENTUM',
                      value: widget.character.momentum,
                      minValue: -6,
                      maxValue: widget.character.maxMomentum,
                      valueColor: widget.character.momentum < 0 ? Colors.red : null,
                      onChanged: (newValue) {
                        setState(() {
                          widget.character.momentum = newValue;
                        });
                        _saveCharacter();
                      },
                    ),
                    StatAdjusterWidget(
                      label: 'HEALTH',
                      value: widget.character.health,
                      minValue: 0,
                      maxValue: 5,
                      onChanged: (newValue) {
                        setState(() {
                          widget.character.health = newValue;
                        });
                        _saveCharacter();
                      },
                    ),
                    StatAdjusterWidget(
                      label: 'SPIRIT',
                      value: widget.character.spirit,
                      minValue: 0,
                      maxValue: 5,
                      onChanged: (newValue) {
                        setState(() {
                          widget.character.spirit = newValue;
                        });
                        _saveCharacter();
                      },
                    ),
                    StatAdjusterWidget(
                      label: 'SUPPLY',
                      value: widget.character.supply,
                      minValue: 0,
                      maxValue: 5,
                      onChanged: (newValue) {
                        setState(() {
                          widget.character.supply = newValue;
                        });
                        _saveCharacter();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Character stats (Edge, Heart, Iron, etc.)
                const Text(
                  'Character Stats:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildCharacterStats(),
              ],
              
              // Active impacts if any
              if (widget.character.activeImpacts.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Active Impacts:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.character.activeImpacts.map((impact) => 
                    Chip(
                      label: Text(impact),
                      backgroundColor: Colors.red[100],
                      labelStyle: TextStyle(color: Colors.red[900]),
                    )
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCharacterStats() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.start,
      children: widget.character.stats.map((stat) {
        return CompactStatWidget(
          label: stat.name.toUpperCase(),
          value: stat.value,
          minValue: 0,
          maxValue: 5,
          onChanged: (newValue) {
            setState(() {
              stat.value = newValue;
            });
            _saveCharacter();
          },
        );
      }).toList(),
    );
  }
  
  void _saveCharacter() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.saveGame();
  }
}
