import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../widgets/progress_track_widget.dart';

/// A component for managing character legacies.
class LegacyPanel extends StatelessWidget {
  final Character character;
  final bool isEditable;
  final VoidCallback? onLegacyChanged;

  const LegacyPanel({
    super.key,
    required this.character,
    this.isEditable = false,
    this.onLegacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressTrackWidget(
          label: 'Quests',
          value: character.legacyQuests,
          ticks: character.legacyQuestsTicks,
          maxValue: 10,
          isEditable: isEditable,
          showTicks: true,
          onTickChanged: isEditable ? (newValue) {
            character.updateLegacyQuestsTicks(newValue);
            if (onLegacyChanged != null) {
              onLegacyChanged!();
            }
          } : null,
        ),
        const SizedBox(height: 8),
        ProgressTrackWidget(
          label: 'Bonds',
          value: character.legacyBonds,
          ticks: character.legacyBondsTicks,
          maxValue: 10,
          isEditable: isEditable,
          showTicks: true,
          onTickChanged: isEditable ? (newValue) {
            character.updateLegacyBondsTicks(newValue);
            if (onLegacyChanged != null) {
              onLegacyChanged!();
            }
          } : null,
        ),
        const SizedBox(height: 8),
        ProgressTrackWidget(
          label: 'Discoveries',
          value: character.legacyDiscoveries,
          ticks: character.legacyDiscoveriesTicks,
          maxValue: 10,
          isEditable: isEditable,
          showTicks: true,
          onTickChanged: isEditable ? (newValue) {
            character.updateLegacyDiscoveriesTicks(newValue);
            if (onLegacyChanged != null) {
              onLegacyChanged!();
            }
          } : null,
        ),
        const SizedBox(height: 8),
        const Text(
          'Legacy tracks represent your character\'s long-term accomplishments. '
          'Each filled box (4 ticks) counts as a legacy point that can be used for character advancement.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
