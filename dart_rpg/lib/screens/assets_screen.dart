import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/datasworn_provider.dart';
import '../providers/game_provider.dart';
import '../models/character.dart' show Asset;
import '../utils/asset_utils.dart';

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
                    _selectedAsset = null;
                  });
                },
              ),
            ),
            
            // Asset list or details
            Expanded(
              child: _selectedAsset != null
                  ? _buildAssetDetails(_selectedAsset!, gameProvider)
                  : _selectedCategory != null && assetsByCategory.containsKey(_selectedCategory)
                      ? _buildAssetList(assetsByCategory[_selectedCategory]!, gameProvider)
                      : const Center(
                          child: Text('Select an asset category to begin'),
                        ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildAssetList(List<Asset> assets, GameProvider gameProvider) {
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
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedAsset = asset;
              });
            },
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
                
                // Asset content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 80, // Fixed height for consistent card sizing
                          child: asset.description != null
                              ? MarkdownBody(
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
                                )
                              : const Text(
                                  'No description available',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                        ),
                        const Spacer(),
                        // Asset enabled status
                        if (asset.enabled) ...[
                          const Text(
                            'Enabled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Disabled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
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
          ),
        );
      },
    );
  }
  
  Widget _buildAssetDetails(Asset asset, GameProvider gameProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Assets'),
            onPressed: () {
              setState(() {
                _selectedAsset = null;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Asset card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset name
                  Text(
                    asset.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Asset category
                  Text(
                    asset.category,
                    style: TextStyle(
                      color: getAssetCategoryColor(asset.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Asset description
                  if (asset.description != null) ...[
                    MarkdownBody(
                      data: asset.description!,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyMedium,
                        h1: Theme.of(context).textTheme.titleLarge,
                        h2: Theme.of(context).textTheme.titleMedium,
                        h3: Theme.of(context).textTheme.titleSmall,
                        code: TextStyle(
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Asset enabled status
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        asset.enabled ? 'Enabled' : 'Disabled',
                        style: TextStyle(
                          color: asset.enabled ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Add to character button
                  if (gameProvider.currentGame?.mainCharacter != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Character'),
                        onPressed: () {
                          _addAssetToCharacter(context, asset, gameProvider);
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
