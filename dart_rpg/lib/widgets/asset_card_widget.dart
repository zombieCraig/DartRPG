import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';
import '../providers/game_provider.dart';

class AssetCardWidget extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showAbilities;
  final Function(AssetAbility, bool)? onAbilityToggle;

  const AssetCardWidget({
    super.key,
    required this.asset,
    this.onTap,
    this.onRemove,
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
      child: InkWell(
        onTap: onTap,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        asset.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  asset.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                  ),
                ),
                
                // Scrollable content area for description and abilities
                Flexible(
                  child: ClipRect(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Asset description
                          if (asset.description != null && asset.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            MarkdownBody(
                              data: asset.description!,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(fontSize: 12),
                                h1: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                h2: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                h3: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                code: TextStyle(
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  fontSize: 12,
                                ),
                              ),
                              shrinkWrap: true,
                              softLineBreak: true,
                            ),
                          ],
                          
                          // Display abilities if they exist and showAbilities is true
                          if (showAbilities && asset.abilities.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 4),
                            Text(
                              'Abilities',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Display only the first ability with a "Show more" button if there are more
                            if (asset.abilities.isNotEmpty)
                              _buildAbilityItem(
                                context, 
                                asset.abilities[0], 
                                color,
                                (newValue) {
                                  if (onAbilityToggle != null) {
                                    onAbilityToggle!(asset.abilities[0], newValue);
                                  } else {
                                    // Default toggle behavior if no callback provided
                                    asset.abilities[0].enabled = newValue;
                                    gameProvider.saveGame();
                                  }
                                },
                              ),
                            
                            // Show a "View all abilities" button if there are more than one ability
                            if (asset.abilities.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '+ ${asset.abilities.length - 1} more abilities',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle indicator that can be toggled
          GestureDetector(
            onTap: () {
              onToggle(!ability.enabled);
            },
            child: Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              width: 16,
              height: 16,
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
                p: const TextStyle(fontSize: 12),
                h1: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                h2: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                h3: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  fontSize: 12,
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
