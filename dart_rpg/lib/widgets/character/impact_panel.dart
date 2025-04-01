import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../widgets/impact_toggle_widget.dart';

/// A component for managing character impacts.
class ImpactPanel extends StatelessWidget {
  final Character character;
  final bool isEditable;
  final Function(String, bool)? onImpactChanged;

  const ImpactPanel({
    super.key,
    required this.character,
    this.isEditable = false,
    this.onImpactChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Misfortunes
        ImpactCategoryWidget(
          title: 'Misfortunes',
          children: [
            ImpactToggleWidget(
              label: 'Wounded',
              category: 'Misfortunes',
              value: character.impactWounded,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('wounded', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Shaken',
              category: 'Misfortunes',
              value: character.impactShaken,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('shaken', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Unregulated',
              category: 'Misfortunes',
              value: character.impactUnregulated,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('unregulated', value);
                }
              },
            ),
          ],
        ),
        
        // Lasting Effects
        ImpactCategoryWidget(
          title: 'Lasting Effects',
          children: [
            ImpactToggleWidget(
              label: 'Permanently Harmed',
              category: 'Lasting Effects',
              value: character.impactPermanentlyHarmed,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('permanently_harmed', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Traumatized',
              category: 'Lasting Effects',
              value: character.impactTraumatized,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('traumatized', value);
                }
              },
            ),
          ],
        ),
        
        // Burdens
        ImpactCategoryWidget(
          title: 'Burdens',
          children: [
            ImpactToggleWidget(
              label: 'Doomed',
              category: 'Burdens',
              value: character.impactDoomed,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('doomed', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Tormented',
              category: 'Burdens',
              value: character.impactTormented,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('tormented', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Indebted',
              category: 'Burdens',
              value: character.impactIndebted,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('indebted', value);
                }
              },
            ),
          ],
        ),
        
        // Current Rig
        ImpactCategoryWidget(
          title: 'Current Rig',
          children: [
            ImpactToggleWidget(
              label: 'Overheated',
              category: 'Current Rig',
              value: character.impactOverheated,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('overheated', value);
                }
              },
            ),
            ImpactToggleWidget(
              label: 'Infected',
              category: 'Current Rig',
              value: character.impactInfected,
              isEditable: isEditable,
              onChanged: (value) {
                if (onImpactChanged != null) {
                  onImpactChanged!('infected', value);
                }
              },
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        Text(
          'Total Impacts: ${character.totalImpacts} (reduces max momentum by ${character.totalImpacts})',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
