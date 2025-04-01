import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';

class AssetCardWidget extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const AssetCardWidget({
    super.key,
    required this.asset,
    this.onTap,
    this.onRemove,
  });

  Color _getAssetColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return getAssetCategoryColor(asset.category, isDarkMode: isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getAssetColor(context);
    
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
                if (asset.description != null && asset.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 40, // Fixed height for consistent card sizing
                    child: MarkdownBody(
                      data: asset.description!,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 12),
                        h1: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        h2: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        h3: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        code: TextStyle(
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      shrinkWrap: true,
                      softLineBreak: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
