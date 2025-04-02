import 'package:flutter/material.dart';
import '../../../models/character.dart';

/// A panel for displaying and editing character key stats.
class CharacterKeyStatsPanel extends StatefulWidget {
  final Character character;
  final TextEditingController momentumController;
  final TextEditingController healthController;
  final TextEditingController spiritController;
  final TextEditingController supplyController;
  final bool isEditable;
  final bool initiallyExpanded;
  final Function(int momentum, int health, int spirit, int supply)? onStatsChanged;
  
  const CharacterKeyStatsPanel({
    super.key,
    required this.character,
    required this.momentumController,
    required this.healthController,
    required this.spiritController,
    required this.supplyController,
    this.isEditable = false,
    this.initiallyExpanded = true,
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
  }
  
  @override
  Widget build(BuildContext context) {
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
                      setState(() {
                        _momentum = parsed.clamp(-6, 10 - widget.character.totalImpacts);
                        widget.character.momentum = _momentum;
                        if (widget.onStatsChanged != null) {
                          widget.onStatsChanged!(_momentum, _health, _spirit, _supply);
                        }
                      });
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
                      setState(() {
                        _health = parsed.clamp(0, 5);
                        widget.character.health = _health;
                        if (widget.onStatsChanged != null) {
                          widget.onStatsChanged!(_momentum, _health, _spirit, _supply);
                        }
                      });
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
                      setState(() {
                        _spirit = parsed.clamp(0, 5);
                        widget.character.spirit = _spirit;
                        if (widget.onStatsChanged != null) {
                          widget.onStatsChanged!(_momentum, _health, _spirit, _supply);
                        }
                      });
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
                      setState(() {
                        _supply = parsed.clamp(0, 5);
                        widget.character.supply = _supply;
                        if (widget.onStatsChanged != null) {
                          widget.onStatsChanged!(_momentum, _health, _spirit, _supply);
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          ),
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
