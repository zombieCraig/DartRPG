import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../providers/datasworn_provider.dart';
import '../../widgets/asset_content_widget.dart';
import '../../widgets/asset_detail_dialog.dart';
import '../../utils/asset_utils.dart';

/// A component for managing character assets.
class AssetPanel extends StatelessWidget {
  final Character character;
  final bool isEditable;
  final VoidCallback? onAssetsChanged;

  const AssetPanel({
    super.key,
    required this.character,
    this.isEditable = false,
    this.onAssetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (character.assets.isEmpty)
          const Text('No assets attached'),
        ...character.assets.map((asset) {
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                _showAssetDetailsDialog(context, asset);
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: getAssetCategoryColor(asset.category),
                      width: 4,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Asset header
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
                          if (isEditable && asset.category.toLowerCase() != 'base rig')
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                character.assets.remove(asset);
                                if (onAssetsChanged != null) {
                                  onAssetsChanged!();
                                }
                              },
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
                          color: getAssetCategoryColor(asset.category),
                        ),
                      ),
                      
                      // Asset content
                      Flexible(
                        child: AssetContentWidget(
                          asset: asset,
                          showAbilities: true,
                          isDetailView: false, // Use summary view in the panel
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        
        if (isEditable) ...[
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Asset'),
            onPressed: () {
              // Show asset selection dialog
              _showAssetSelectionDialog(context, (asset) {
                character.assets.add(asset);
                if (onAssetsChanged != null) {
                  onAssetsChanged!();
                }
              });
            },
          ),
        ],
      ],
    );
  }

  // Asset selection dialog using assets from DataswornProvider
  void _showAssetSelectionDialog(BuildContext context, Function(Asset) onAssetSelected) {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final assetsByCategory = dataswornProvider.getAssetsByCategory();
    
    if (assetsByCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No assets available. Please load a datasworn source.'),
        ),
      );
      return;
    }
    
    // Sort categories alphabetically
    final sortedCategories = assetsByCategory.keys.toList()..sort();
    final initialCategory = sortedCategories.isNotEmpty ? sortedCategories.first : null;
    
    showDialog(
      context: context,
      builder: (context) {
        // Use a ValueNotifier to track the selected category
        final selectedCategoryNotifier = ValueNotifier<String?>(initialCategory);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Asset'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Asset Category',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedCategoryNotifier.value,
                      items: sortedCategories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryNotifier.value = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Asset list - using ValueListenableBuilder to rebuild when category changes
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: selectedCategoryNotifier,
                        builder: (context, selectedCategory, _) {
                          if (selectedCategory == null || !assetsByCategory.containsKey(selectedCategory)) {
                            return const Center(child: Text('Select a category to view assets'));
                          }
                          
                          final assetsInCategory = assetsByCategory[selectedCategory]!;
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: assetsInCategory.length,
                            itemBuilder: (context, index) {
                              final asset = assetsInCategory[index];
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Color.lerp(
                                  getAssetCategoryColor(asset.category),
                                  Colors.white,
                                  0.9,
                                ),
                                child: ListTile(
                                  title: Text(
                                    asset.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    asset.category,
                                    style: TextStyle(
                                      color: getAssetCategoryColor(asset.category),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    onAssetSelected(asset);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showAssetDetailsDialog(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AssetDetailDialog(
        asset: asset,
        isCharacterAsset: true, // This is a character asset, so enable ability toggling
      ),
    );
  }
}
