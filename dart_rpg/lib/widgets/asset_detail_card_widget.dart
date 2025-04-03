import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';
import '../providers/game_provider.dart';

/// A specialized version of the asset card widget for use in detail dialogs
/// that avoids using Expanded to prevent layout issues
class AssetDetailCardWidget extends StatelessWidget {
  final Asset asset;
  final bool showAbilities;
  final Function(AssetAbility, bool)? onAbilityToggle;

  const AssetDetailCardWidget({
    super.key,
    required this.asset,
    this.showAbilities = true,
    this.onAbilityToggle,
  });

  Color _getAssetColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return getAssetCategoryColor(asset.category, isDarkMode: isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAssetColor(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: color, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remove asset description as it's not a field in the JSON
              
                // Display abilities if they exist and showAbilities is true
                if (showAbilities && asset.abilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    'Abilities',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Display abilities directly in a column
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: asset.abilities.length,
                    itemBuilder: (context, index) {
                      return _buildAbilityItem(
                        context, 
                        asset.abilities[index], 
                        color,
                        (newValue) {
                          if (onAbilityToggle != null) {
                            onAbilityToggle!(asset.abilities[index], newValue);
                          } else {
                            // Default toggle behavior if no callback provided
                            asset.abilities[index].enabled = newValue;
                            gameProvider.saveGame();
                          }
                        },
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAbilityItem(
    BuildContext context, 
    AssetAbility ability, 
    Color color,
    Function(bool) onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle indicator that can be toggled
          GestureDetector(
            onTap: () {
              onToggle(!ability.enabled);
            },
            child: Container(
              margin: const EdgeInsets.only(top: 2, right: 12),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: ability.enabled ? color : Colors.transparent,
              ),
            ),
          ),
          
          // Ability text
          Expanded(
            child: MarkdownBody(
              data: ability.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14),
                h1: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  fontSize: 14,
                ),
              ),
              shrinkWrap: true,
              softLineBreak: true,
            ),
          ),
        ],
      ),
    );
  }
}
