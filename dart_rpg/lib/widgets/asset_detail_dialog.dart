import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';
import '../providers/game_provider.dart';
import 'asset_detail_card_widget.dart';

class AssetDetailDialog extends StatefulWidget {
  final Asset asset;
  final bool isCharacterAsset;
  
  const AssetDetailDialog({
    super.key,
    required this.asset,
    this.isCharacterAsset = true,
  });
  
  @override
  State<AssetDetailDialog> createState() => _AssetDetailDialogState();
}

class _AssetDetailDialogState extends State<AssetDetailDialog> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    return AlertDialog(
      title: Text(widget.asset.name),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset category
            Text(
              widget.asset.category,
              style: TextStyle(
                color: getAssetCategoryColor(
                  widget.asset.category, 
                  isDarkMode: Theme.of(context).brightness == Brightness.dark
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Use AssetDetailCardWidget for consistent display
            Expanded(
              child: SingleChildScrollView(
                child: AssetDetailCardWidget(
                  asset: widget.asset,
                  showAbilities: true,
                  onAbilityToggle: widget.isCharacterAsset ? (ability, newValue) {
                    setState(() {
                      ability.enabled = newValue;
                      gameProvider.saveGame();
                    });
                  } : null,
                ),
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
