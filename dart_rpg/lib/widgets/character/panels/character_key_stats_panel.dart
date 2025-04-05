import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/character.dart';
import '../../../providers/game_provider.dart';

/// A panel for displaying and editing character key stats.
/// Supports both compact view with +/- buttons and text field input for editing.
class CharacterKeyStatsPanel extends StatefulWidget {
  final Character character;
  final TextEditingController? momentumController;
  final TextEditingController? healthController;
  final TextEditingController? spiritController;
  final TextEditingController? supplyController;
  final bool isEditable;
  final bool initiallyExpanded;
  final bool useCompactMode;
  final Function(int momentum, int health, int spirit, int supply)? onStatsChanged;
  
  const CharacterKeyStatsPanel({
    super.key,
    required this.character,
    this.momentumController,
    this.healthController,
    this.spiritController,
    this.supplyController,
    this.isEditable = false,
    this.initiallyExpanded = true,
    this.useCompactMode = false,
    this.onStatsChanged,
  });

  @override
  State<CharacterKeyStatsPanel> createState() => _CharacterKeyStatsPanelState();
}

class _CharacterKeyStatsPanelState extends State<CharacterKeyStatsPanel> {
  late bool _isExpanded;
  late int _momentum;
  late int _health;
  late int _spirit;
  late int _supply;
  
  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _momentum = widget.character.momentum;
    _health = widget.character.health;
    _spirit = widget.character.spirit;
    _supply = widget.character.supply;
    
    // Update controllers if provided
    _updateControllers();
  }
  
  @override
  void didUpdateWidget(CharacterKeyStatsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _momentum = widget.character.momentum;
      _health = widget.character.health;
      _spirit = widget.character.spirit;
      _supply = widget.character.supply;
      _updateControllers();
    }
  }
  
  void _updateControllers() {
    if (widget.momentumController != null) {
      widget.momentumController!.text = _momentum.toString();
    }
    if (widget.healthController != null) {
      widget.healthController!.text = _health.toString();
    }
    if (widget.spiritController != null) {
      widget.spiritController!.text = _spirit.toString();
    }
    if (widget.supplyController != null) {
      widget.supplyController!.text = _supply.toString();
    }
  }
  
  void _updateStats(String type, int value) {
    setState(() {
      switch (type) {
        case 'momentum':
          _momentum = value.clamp(-6, widget.character.maxMomentum);
          widget.character.momentum = _momentum;
          if (widget.momentumController != null) {
            widget.momentumController!.text = _momentum.toString();
          }
          break;
        case 'health':
          _health = value.clamp(0, 5);
          widget.character.health = _health;
          if (widget.healthController != null) {
            widget.healthController!.text = _health.toString();
          }
          break;
        case 'spirit':
          _spirit = value.clamp(0, 5);
          widget.character.spirit = _spirit;
          if (widget.spiritController != null) {
            widget.spiritController!.text = _spirit.toString();
          }
          break;
        case 'supply':
          _supply = value.clamp(0, 5);
          widget.character.supply = _supply;
          if (widget.supplyController != null) {
            widget.supplyController!.text = _supply.toString();
          }
          break;
      }
      
      // Save the game when stats are changed
      if (widget.isEditable) {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        gameProvider.saveGame();
      }
      
      if (widget.onStatsChanged != null) {
        widget.onStatsChanged!(_momentum, _health, _spirit, _supply);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // In compact mode, we don't need the title, expand/collapse functionality, or max momentum info
    if (widget.useCompactMode) {
      return _buildCompactView();
    } else {
      // Standard view with title and expand/collapse functionality
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('Key Stats', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            _buildTextFieldView(),
            
            const SizedBox(height: 8),
            Text(
              'Max Momentum: ${widget.character.maxMomentum} (reduced by ${widget.character.totalImpacts} impacts)',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }
  }
  
  Widget _buildCompactView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              context,
              label: 'MOMENTUM',
              value: _momentum,
              minValue: -6,
              maxValue: widget.character.maxMomentum,
              color: _momentum < 0 ? Colors.red : Colors.blue,
              textColor: Colors.black87, // Black text for all stats
              tooltip: 'Momentum represents your character\'s forward progress and can be spent for bonuses',
              onChanged: (newValue) => _updateStats('momentum', newValue),
            ),
            _buildStatItem(
              context,
              label: 'HEALTH',
              value: _health,
              minValue: 0,
              maxValue: 5,
              color: Colors.red,
              textColor: Colors.black87, // Black text for all stats
              tooltip: 'Health represents your character\'s physical condition',
              onChanged: (newValue) => _updateStats('health', newValue),
            ),
            _buildStatItem(
              context,
              label: 'SPIRIT',
              value: _spirit,
              minValue: 0,
              maxValue: 5,
              color: Colors.purple,
              textColor: Colors.black87, // Black text for all stats
              tooltip: 'Spirit represents your character\'s mental and emotional state',
              onChanged: (newValue) => _updateStats('spirit', newValue),
            ),
            _buildStatItem(
              context,
              label: 'SUPPLY',
              value: _supply,
              minValue: 0,
              maxValue: 5,
              color: Colors.amber[700]!, // Darker amber for better contrast
              textColor: Colors.black87, // Black text for all stats
              tooltip: 'Supply represents your character\'s resources and equipment',
              onChanged: (newValue) => _updateStats('supply', newValue),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTextFieldView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.momentumController,
                decoration: const InputDecoration(
                  labelText: 'Momentum',
                  helperText: 'Range: -6 to 10',
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.isEditable,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateStats('momentum', parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.healthController,
                decoration: const InputDecoration(
                  labelText: 'Health',
                  helperText: 'Range: 0 to 5',
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.isEditable,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateStats('health', parsed);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.spiritController,
                decoration: const InputDecoration(
                  labelText: 'Spirit',
                  helperText: 'Range: 0 to 5',
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.isEditable,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateStats('spirit', parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.supplyController,
                decoration: const InputDecoration(
                  labelText: 'Supply',
                  helperText: 'Range: 0 to 5',
                ),
                keyboardType: TextInputType.number,
                readOnly: !widget.isEditable,
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateStats('supply', parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required int value,
    required int minValue,
    required int maxValue,
    required Color color,
    Color? textColor,
    required Function(int) onChanged,
    String? tooltip,
  }) {
    // Use textColor if provided, otherwise use the main color
    final labelColor = textColor ?? color.withAlpha(204); // 0.8 opacity = 204 alpha
    final valueColor = textColor ?? color;
    // Create the base widget
    Widget statItem = Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(128)), // 0.5 opacity = 128 alpha
        borderRadius: BorderRadius.circular(4),
        color: color.withAlpha(26), // 0.1 opacity = 26 alpha
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Value and adjustment buttons - Wrap in FittedBox to prevent overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Decrease button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.isEditable && value > minValue ? () => onChanged(value - 1) : null,
                    child: Container(
                      padding: const EdgeInsets.all(2), // Reduced padding
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24), // Smaller constraints
                      child: Icon(
                        Icons.remove,
                        size: 14, // Smaller icon
                        color: widget.isEditable && value > minValue ? color : Colors.grey.withAlpha(128), // 0.5 opacity = 128 alpha
                      ),
                    ),
                  ),
                ),
                
                // Value
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0), // Reduced padding
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 16, // Smaller font
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ),
                
                // Increase button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.isEditable && value < maxValue ? () => onChanged(value + 1) : null,
                    child: Container(
                      padding: const EdgeInsets.all(2), // Reduced padding
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24), // Smaller constraints
                      child: Icon(
                        Icons.add,
                        size: 14, // Smaller icon
                        color: widget.isEditable && value < maxValue ? color : Colors.grey.withAlpha(128), // 0.5 opacity = 128 alpha
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    // Add padding
    statItem = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: statItem,
    );
    
    // Wrap with tooltip if provided
    if (tooltip != null) {
      statItem = Tooltip(
        message: tooltip,
        preferBelow: true,
        showDuration: const Duration(seconds: 2),
        child: statItem,
      );
    }
    
    // Wrap with Expanded for Row layout
    return Expanded(child: statItem);
  }
}
