import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/character.dart' show Asset, AssetAbility;
import '../utils/asset_utils.dart';
import '../widgets/asset_card_widget.dart';
import '../widgets/asset_content_widget.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  String? _selectedCategory;
  Asset? _selectedAsset;
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<DataswornProvider, GameProvider>(
      builder: (context, dataswornProvider, gameProvider, _) {
        final assetsByCategory = dataswornProvider.getAssetsByCategory();
        final categories = assetsByCategory.keys.toList()..sort();
        
        if (categories.isEmpty) {
          return const Center(
            child: Text('No assets available'),
          );
        }
        
        return Column(
          children: [
            // Category selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Asset Category',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            
            // Asset list
            Expanded(
              child: _selectedCategory != null && assetsByCategory.containsKey(_selectedCategory)
                  ? _buildAssetGrid(assetsByCategory[_selectedCategory]!, gameProvider)
                  : const Center(
                      child: Text('Select an asset category to begin'),
                    ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildAssetGrid(List<Asset> assets, GameProvider gameProvider) {
    final sortedAssets = List<Asset>.from(assets)..sort((a, b) => a.name.compareTo(b.name));
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: sortedAssets.length,
      itemBuilder: (context, index) {
        final asset = sortedAssets[index];
        
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Asset header
              Container(
                color: getAssetCategoryColor(asset.category),
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  asset.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Asset content using AssetContentWidget
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AssetContentWidget(
                    asset: asset,
                    showAbilities: true, // Show abilities in the list view
                    isDetailView: true, // Always use detail view to show all abilities
                    enableToggle: false, // Disable ability toggling in the asset screen
                  ),
                ),
              ),
              
              // Add to character button
              if (gameProvider.currentGame?.mainCharacter != null)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add to Character'),
                  onPressed: () {
                    _addAssetToCharacter(context, asset, gameProvider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  
  void _addAssetToCharacter(BuildContext context, Asset asset, GameProvider gameProvider) {
    final character = gameProvider.currentGame?.mainCharacter;
    
    if (character == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No main character selected'),
        ),
      );
      return;
    }
    
    // Check if the character already has this asset
    final hasAsset = character.assets.any((a) => a.id == asset.id);
    if (hasAsset) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${character.name} already has this asset'),
        ),
      );
      return;
    }
    
    // Add the asset to the character
    character.assets.add(asset);
    
    // Save the changes
    gameProvider.saveGame();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${asset.name} to ${character.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
