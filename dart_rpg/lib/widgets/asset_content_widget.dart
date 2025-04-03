import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';
import '../providers/game_provider.dart';

/// A widget that displays only the content of an asset (description and abilities)
/// without the name and category header, to avoid duplication in cards that already
/// display the asset name in a header.
class AssetContentWidget extends StatelessWidget {
  final Asset asset;
  final bool showAbilities;
  final Function(AssetAbility, bool)? onAbilityToggle;
  final bool isDetailView;
  final bool enableToggle;

  const AssetContentWidget({
    super.key,
    required this.asset,
    this.showAbilities = true,
    this.onAbilityToggle,
    this.isDetailView = false,
    this.enableToggle = true,
  });

  Color _getAssetColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return getAssetCategoryColor(asset.category, isDarkMode: isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAssetColor(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    if (!showAbilities || asset.abilities.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Header for abilities section
    final abilitiesHeader = Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        'Abilities',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
    
    // For detail view (scrollable with fixed height)
    if (isDetailView) {
      // Create a list of widgets with the header and abilities
      final List<Widget> contentWidgets = [];
      
      // Add optional fields if they exist
      if (asset.options.isNotEmpty) {
        // Add options header
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'Options',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
        
        // Add each option that has a value
        for (final entry in asset.options.entries) {
          final option = entry.value;
          if (option.value != null && option.value!.isNotEmpty) {
            contentWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.label}: ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        option.value!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        
        // Add a divider if there were any options
        if (contentWidgets.length > 1) {
          contentWidgets.add(const Divider(height: 16));
        }
      }
      
      // Add abilities header and abilities
      contentWidgets.add(abilitiesHeader);
      
      // Add each ability widget to the list
      for (final ability in asset.abilities) {
        contentWidgets.add(
          _buildAbilityItem(
            context, 
            ability, 
            color,
            (newValue) {
              if (onAbilityToggle != null) {
                onAbilityToggle!(ability, newValue);
              } else {
                // Default toggle behavior if no callback provided
                ability.enabled = newValue;
                gameProvider.saveGame();
              }
            },
          ),
        );
      }
      
      // Return a ListView with all content widgets
      return SizedBox(
        height: 150, // Fixed height for the content
        child: ListView(
          shrinkWrap: true,
          children: contentWidgets,
        ),
      );
    } 
    // For summary view (compact)
    else {
      final List<Widget> contentWidgets = [];
      
      // Add options that have values (in summary view, just show the first one)
      for (final entry in asset.options.entries) {
        final option = entry.value;
        if (option.value != null && option.value!.isNotEmpty) {
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${option.label}: ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      option.value!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
          break; // Only show the first option in summary view
        }
      }
      
      // Add abilities
      contentWidgets.add(abilitiesHeader);
      
      // Show first ability
      if (asset.abilities.isNotEmpty) {
        contentWidgets.add(
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
        );
      }
      
      // Show indicator for additional abilities
      if (asset.abilities.length > 1) {
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 24.0),
            child: Text(
              '+ ${asset.abilities.length - 1} more abilities',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: contentWidgets,
      );
    }
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
          enableToggle 
            ? GestureDetector(
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
              )
            : Container(
                margin: const EdgeInsets.only(top: 2, right: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  color: ability.enabled ? color : Colors.transparent,
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
