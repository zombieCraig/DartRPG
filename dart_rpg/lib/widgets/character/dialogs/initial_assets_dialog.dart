import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/character.dart';
import '../../../providers/datasworn_provider.dart';
import '../../../providers/game_provider.dart';
import '../../../utils/asset_utils.dart';
import '../../../widgets/asset_detail_dialog.dart';
import '../../../widgets/asset_content_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A dialog for selecting initial assets for a new character.
class InitialAssetsDialog extends StatefulWidget {
  final Character character;
  final GameProvider gameProvider;
  
  const InitialAssetsDialog({
    super.key,
    required this.character,
    required this.gameProvider,
  });
  
  /// Shows a dialog for selecting initial assets.
  static Future<bool> show(BuildContext context, Character character, GameProvider gameProvider) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InitialAssetsDialog(
        character: character,
        gameProvider: gameProvider,
      ),
    );
    
    return result ?? false;
  }

  @override
  State<InitialAssetsDialog> createState() => _InitialAssetsDialogState();
}

class _InitialAssetsDialogState extends State<InitialAssetsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Asset> _selectedAssets = [];
  List<String> _categories = [];
  
  @override
  void initState() {
    super.initState();
    
    // Get asset categories from DataswornProvider
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final assetsByCategory = dataswornProvider.getAssetsByCategory();
    _categories = assetsByCategory.keys.toList()..sort();
    
    // Initialize tab controller
    _tabController = TabController(length: _categories.length, vsync: this);
    
    // Add Base Rig asset if it's not already in the character's assets
    final hasBaseRig = widget.character.assets.any((a) => a.name == 'Base Rig');
    if (!hasBaseRig) {
      widget.character.assets.add(Asset.baseRig());
    }
    
    // Initialize selected assets with character's existing assets
    _selectedAssets = List.from(widget.character.assets);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DataswornProvider>(
      builder: (context, dataswornProvider, _) {
        final assetsByCategory = dataswornProvider.getAssetsByCategory();
        
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dialog header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Initial Assets',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'New characters typically start with 2 Path assets and 1 additional asset of your choosing.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                
                // Selected assets panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Assets (${_selectedAssets.length}):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: _selectedAssets.isEmpty
                            ? const Text('No assets selected')
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedAssets.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final asset = _selectedAssets[index];
                                  return Tooltip(
                                    richMessage: WidgetSpan(
                                      child: Container(
                                        constraints: const BoxConstraints(maxWidth: 300),
                                        padding: const EdgeInsets.all(8),
                                        child: asset.description != null
                                          ? MarkdownBody(
                                              data: asset.description!,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                h1: TextStyle(
                                                  fontSize: 14, 
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                h2: TextStyle(
                                                  fontSize: 13, 
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                h3: TextStyle(
                                                  fontSize: 12, 
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                                code: TextStyle(
                                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                              ),
                                              shrinkWrap: true,
                                              softLineBreak: true,
                                            )
                                          : Text(
                                              'No description available',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                      ),
                                    ),
                                    // Increase the wait duration for better user experience
                                    waitDuration: const Duration(milliseconds: 500),
                                    // Style the tooltip to match the app's theme
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    // Use the Chip as the child of the Tooltip
                                    child: Chip(
                                      label: Text(asset.name),
                                      backgroundColor: getAssetCategoryColor(
                                        asset.category,
                                        isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                      ).withAlpha(51), // 0.2 opacity = 51 alpha
                                      deleteIcon: asset.name == 'Base Rig'
                                          ? null // Don't allow removing Base Rig
                                          : const Icon(Icons.close, size: 16),
                                      onDeleted: asset.name == 'Base Rig'
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedAssets.removeAt(index);
                                              });
                                            },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                
                // Category tabs
                if (_categories.isNotEmpty) ...[
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabs: _categories.map((category) => Tab(text: category)).toList(),
                    onTap: (index) {
                      // Tab selection is handled by the TabController
                    },
                  ),
                  
                  // Asset grid
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _categories.map((category) {
                        final assets = assetsByCategory[category] ?? [];
                        final sortedAssets = List<Asset>.from(assets)..sort((a, b) => a.name.compareTo(b.name));
                        
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: sortedAssets.length,
                          itemBuilder: (context, index) {
                            final asset = sortedAssets[index];
                            final isSelected = _selectedAssets.any((a) => a.id == asset.id);
                            
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  _toggleAssetSelection(asset);
                                },
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Asset header
                                        Container(
                                          color: getAssetCategoryColor(
                                            asset.category,
                                            isDarkMode: Theme.of(context).brightness == Brightness.dark,
                                          ),
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
                                                // Use Flexible instead of SizedBox with fixed height
                                                Flexible(
                                                  child: AssetContentWidget(
                                                    asset: asset,
                                                    showAbilities: true, // Show abilities in the grid view
                                                    isDetailView: true, // Use detail view to show all abilities
                                                  ),
                                                ),
                                                const Spacer(),
                                                // View details button
                                                Center(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      _showAssetDetails(asset);
                                                    },
                                                    child: const Text('View Details'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Selection indicator
                                    if (isSelected)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary,
                                            borderRadius: const BorderRadius.only(
                                              bottomLeft: Radius.circular(8),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                // Dialog actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Define the random buttons group
                      final randomButtonsGroup = Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _addRandomPathAsset,
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Add Random Path'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _addRandomAsset,
                            icon: const Icon(Icons.casino),
                            label: const Text('Add Random Asset'),
                          ),
                        ],
                      );
                      
                      // Define the navigation buttons group
                      final navigationButtonsGroup = Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Skip for Now'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _confirmSelection();
                            },
                            child: const Text('Confirm Selection'),
                          ),
                        ],
                      );
                      
                      // Check if we have enough width for side-by-side layout
                      if (constraints.maxWidth > 600) {
                        // Wide layout: buttons side by side
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            randomButtonsGroup,
                            navigationButtonsGroup,
                          ],
                        );
                      } else {
                        // Narrow layout: buttons stacked vertically
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            randomButtonsGroup,
                            const SizedBox(height: 16), // Add spacing between rows
                            navigationButtonsGroup,
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Toggles the selection of an asset.
  void _toggleAssetSelection(Asset asset) {
    setState(() {
      final isSelected = _selectedAssets.any((a) => a.id == asset.id);
      
      if (isSelected) {
        // Don't allow removing Base Rig
        if (asset.name == 'Base Rig') return;
        
        _selectedAssets.removeWhere((a) => a.id == asset.id);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }
  
  /// Shows the asset details dialog.
  void _showAssetDetails(Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AssetDetailDialog(asset: asset),
    );
  }
  
  /// Confirms the asset selection and updates the character.
  void _confirmSelection() {
    // Update character's assets
    widget.character.assets = _selectedAssets;
    
    // Save the game - this will also notify listeners
    widget.gameProvider.saveGame();
    
    // Close the dialog
    Navigator.pop(context, true);
  }
  
  /// Adds a random path asset that hasn't been added to the character yet.
  void _addRandomPathAsset() {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final assetsByCategory = dataswornProvider.getAssetsByCategory();
    
    // Get all path assets
    final pathAssets = assetsByCategory.entries
        .where((entry) => entry.key.toLowerCase().contains('path'))
        .expand((entry) => entry.value)
        .toList();
    
    // Filter out assets that are already selected
    final availablePathAssets = pathAssets
        .where((asset) => !_selectedAssets.any((a) => a.id == asset.id))
        .toList();
    
    if (availablePathAssets.isEmpty) {
      // Show a snackbar if no available path assets
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more path assets available to add')),
      );
      return;
    }
    
    // Select a random path asset
    final random = Random();
    final randomAsset = availablePathAssets[random.nextInt(availablePathAssets.length)];
    
    // Add the asset to selected assets
    setState(() {
      _selectedAssets.add(randomAsset);
    });
  }

  /// Adds a random asset of any type that hasn't been added to the character yet.
  void _addRandomAsset() {
    final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
    final allAssets = dataswornProvider.assets;
    
    // Filter out assets that are already selected
    final availableAssets = allAssets
        .where((asset) => !_selectedAssets.any((a) => a.id == asset.id))
        .toList();
    
    if (availableAssets.isEmpty) {
      // Show a snackbar if no available assets
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more assets available to add')),
      );
      return;
    }
    
    // Select a random asset
    final random = Random();
    final randomAsset = availableAssets[random.nextInt(availableAssets.length)];
    
    // Add the asset to selected assets
    setState(() {
      _selectedAssets.add(randomAsset);
    });
  }
}
