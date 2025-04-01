import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';

class AssetDetailDialog extends StatelessWidget {
  final Asset asset;
  
  const AssetDetailDialog({
    super.key,
    required this.asset,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(asset.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asset category
            Text(
              asset.category,
              style: TextStyle(
                color: getAssetCategoryColor(asset.category, 
                  isDarkMode: Theme.of(context).brightness == Brightness.dark),
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Asset description
            if (asset.description != null && asset.description!.isNotEmpty)
              MarkdownBody(
                data: asset.description!,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium,
                  h1: Theme.of(context).textTheme.titleLarge,
                  h2: Theme.of(context).textTheme.titleMedium,
                  h3: Theme.of(context).textTheme.titleSmall,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
