import 'package:flutter/material.dart';
import '../../models/character.dart';
import '../../utils/asset_utils.dart';

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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 220, // Fixed height to ensure scrolling works
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Character image (now scrollable)
                AspectRatio(
                  aspectRatio: 3/2, // Maintain aspect ratio for image
                  child: character.imageUrl != null
                      ? Image.network(
                          character.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 64,
                            color: Colors.grey,
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
