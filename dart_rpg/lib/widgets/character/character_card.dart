import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../utils/asset_utils.dart';
import '../../widgets/common/app_image_widget.dart';
import 'panels/character_key_stats_panel.dart';
import 'panels/mobile_stats_summary.dart';

/// A component for displaying a character card.
class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isMainCharacter;
  final VoidCallback? onTap;

  const CharacterCard({
    super.key,
    required this.character,
    this.isMainCharacter = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen width to adjust height on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: isMobile ? 180 : 220, // Smaller height on mobile
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Character image (now scrollable)
                AspectRatio(
                  aspectRatio: 3/2, // Maintain aspect ratio for image
                  child: AppImageWidget(
                    imageUrl: character.imageUrl,
                    imageId: character.imageId,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.person,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                
                // Character info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Character name and star icon
                      Row(
                        children: [
                          if (isMainCharacter)
                            const Padding(
                              padding: EdgeInsets.only(right: 4.0),
                              child: Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              character.getHandle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Key stats for main characters
                      if (character.isMainCharacter && isMainCharacter) ...[
                        const SizedBox(height: 4),
                        // Use LayoutBuilder to determine if we're on a small screen
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // If the width is less than 300 pixels, use the mobile summary
                            if (constraints.maxWidth < 300) {
                              return MobileStatsSummary(
                                character: character,
                              );
                            } else {
                              // Otherwise use the regular panel
                              return CharacterKeyStatsPanel(
                                character: character,
                                isEditable: true, // Always enable the + and - buttons
                                useCompactMode: true, // Use the compact layout
                                initiallyExpanded: true, // Show without needing to expand
                                onStatsChanged: (momentum, health, spirit, supply) {
                                  // The panel already updates the character object
                                  // No need to do anything else here
                                },
                              );
                            }
                          },
                        ),
                      ],
                      
                      // Compact stats display
                      if (character.stats.isNotEmpty)
                        _buildCompactStats(context),
                      
                      // Assets section
                      if (character.assets.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Assets:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Asset list
                        ...character.assets.map((asset) => _buildAssetItem(context, asset)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Build compact stats display
  Widget _buildCompactStats(BuildContext context) {
    return Wrap(
      spacing: 4, // Horizontal space between stats
      runSpacing: 4, // Vertical space between rows
      children: character.stats.map((stat) {
        return _buildCompactStatChip(stat);
      }).toList(),
    );
  }

  // Build a compact stat chip
  Widget _buildCompactStatChip(CharacterStat stat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${stat.name}: ${stat.value}',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
  
  // Build asset item
  Widget _buildAssetItem(BuildContext context, Asset asset) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2), // Reduced padding
      child: Row(
        children: [
          Container(
            width: 6, // Smaller indicator
            height: 12, // Shorter height
            color: _getAssetCategoryColor(asset.category),
            margin: const EdgeInsets.only(right: 4),
          ),
          Expanded(
            child: Text(
              asset.name,
              style: const TextStyle(
                fontSize: 10, // Smaller font
                decoration: TextDecoration.underline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            asset.category,
            style: TextStyle(
              fontSize: 9, // Smaller font
              color: _getAssetCategoryColor(asset.category),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAssetCategoryColor(String category) {
    return getAssetCategoryColor(category);
  }
}
