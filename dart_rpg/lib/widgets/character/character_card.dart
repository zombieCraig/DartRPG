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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Character image or placeholder
            Expanded(
              flex: 3,
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            character.name,
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
                    if (character.stats.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: character.stats.map((stat) {
                          return Chip(
                            label: Text(
                              '${stat.name}: ${stat.value}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
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
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: character.assets.length,
                          itemBuilder: (context, assetIndex) {
                            final asset = character.assets[assetIndex];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 16,
                                    color: _getAssetCategoryColor(asset.category),
                                    margin: const EdgeInsets.only(right: 4),
                                  ),
                                  Expanded(
                                    child: Text(
                                      asset.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    asset.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getAssetCategoryColor(asset.category),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAssetCategoryColor(String category) {
    return getAssetCategoryColor(category);
  }
}
