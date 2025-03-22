import 'package:flutter/material.dart';
import '../models/character.dart';

class AssetCardWidget extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const AssetCardWidget({
    Key? key,
    required this.asset,
    this.onTap,
    this.onRemove,
  }) : super(key: key);

  Color _getAssetColor(BuildContext context) {
    switch (asset.category.toLowerCase()) {
      case 'base rig':
        return Colors.black;
      case 'module':
        return Colors.blue;
      case 'path':
        return Colors.orange;
      case 'companion':
        return Colors.yellow;
      default:
        return Colors.purple;
    }
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
                  Text(
                    asset.description!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
