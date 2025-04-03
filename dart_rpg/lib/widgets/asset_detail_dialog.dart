import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../utils/asset_utils.dart';
import '../providers/game_provider.dart';
import '../utils/logging_service.dart';
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
  // Map to store controllers for each option
  final Map<String, TextEditingController> _controllers = {};
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers for each option
    for (final entry in widget.asset.options.entries) {
      _controllers[entry.key] = TextEditingController(text: entry.value.value);
    }
  }
  
  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
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
            
            // Optional fields section (only for character assets)
            if (widget.isCharacterAsset && widget.asset.options.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: getAssetCategoryColor(
                    widget.asset.category, 
                    isDarkMode: Theme.of(context).brightness == Brightness.dark
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...widget.asset.options.entries.map((entry) {
                final option = entry.value;
                
                // Only support text fields for now
                if (option.fieldType != 'text') {
                  // Log warning for unsupported field types
                  LoggingService().warning(
                    'Unsupported field type "${option.fieldType}" for option "${entry.key}" in asset "${widget.asset.name}"',
                    tag: 'AssetDetailDialog',
                  );
                  return const SizedBox.shrink();
                }
                
                // Ensure we have a controller for this option
                if (!_controllers.containsKey(entry.key)) {
                  _controllers[entry.key] = TextEditingController(text: option.value);
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: option.label,
                      border: const OutlineInputBorder(),
                      hintText: option.label,
                    ),
                    controller: _controllers[entry.key],
                    onChanged: (value) {
                      setState(() {
                        option.value = value;
                        gameProvider.saveGame();
                      });
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],
            
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
