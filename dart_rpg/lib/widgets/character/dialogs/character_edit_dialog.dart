import 'package:flutter/material.dart';
import '../../../models/character.dart';
import '../../../providers/game_provider.dart';
import '../character_form.dart';
import '../services/character_dialog_service.dart';
import '../panels/character_details_panel.dart';
import '../panels/character_npc_details_panel.dart';
import '../panels/character_key_stats_panel.dart';
import '../panels/character_notes_panel.dart';
import '../stat_panel.dart';
import '../impact_panel.dart';
import '../asset_panel.dart';
import '../legacy_panel.dart';
import 'character_delete_confirmation.dart';

/// A dialog for editing an existing character.
class CharacterEditDialog extends StatefulWidget {
  final GameProvider gameProvider;
  final Character character;
  
  const CharacterEditDialog({
    super.key,
    required this.gameProvider,
    required this.character,
  });
  
  /// Shows a dialog for editing an existing character.
  static Future<void> show(BuildContext context, GameProvider gameProvider, Character character) async {
    await showDialog(
      context: context,
      builder: (context) => CharacterEditDialog(
        gameProvider: gameProvider,
        character: character,
      ),
    );
  }

  @override
  State<CharacterEditDialog> createState() => _CharacterEditDialogState();
}

class _CharacterEditDialogState extends State<CharacterEditDialog> {
  late final TextEditingController nameController;
  late final TextEditingController handleController;
  late final TextEditingController bioController;
  late final TextEditingController imageUrlController;
  late final TextEditingController notesController;
  
  // Controllers for key stats
  late final TextEditingController momentumController;
  late final TextEditingController healthController;
  late final TextEditingController spiritController;
  late final TextEditingController supplyController;
  
  // Controllers for NPC character details
  late final TextEditingController firstLookController;
  late final TextEditingController dispositionController;
  late final TextEditingController trademarkAvatarController;
  late final TextEditingController roleController;
  late final TextEditingController detailsController;
  late final TextEditingController goalsController;
  
  // Create copies of stats for editing
  late final List<CharacterStat> stats;
  
  // Create copies of key stats for editing
  late int momentum;
  late int health;
  late int spirit;
  late int supply;
  
  // Create copies of impacts for editing
  late bool impactWounded;
  late bool impactShaken;
  late bool impactUnregulated;
  late bool impactPermanentlyHarmed;
  late bool impactTraumatized;
  late bool impactDoomed;
  late bool impactTormented;
  late bool impactIndebted;
  late bool impactOverheated;
  late bool impactInfected;
  
  // For collapsible sections and editing state
  bool isEditing = false;
  bool showStats = true;
  bool showKeyStats = true;
  bool showImpacts = false;
  bool showAssets = true;
  bool showBio = true;
  bool showNotes = false;
  bool showLegacies = false;
  bool showNpcDetails = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    nameController = TextEditingController(text: widget.character.name);
    handleController = TextEditingController(text: widget.character.handle ?? widget.character.getHandle());
    bioController = TextEditingController(text: widget.character.bio);
    imageUrlController = TextEditingController(text: widget.character.imageUrl ?? '');
    notesController = TextEditingController(text: widget.character.notes.isNotEmpty ? widget.character.notes.join('\n') : '');
    
    // Initialize key stats controllers
    momentumController = TextEditingController(text: widget.character.momentum.toString());
    healthController = TextEditingController(text: widget.character.health.toString());
    spiritController = TextEditingController(text: widget.character.spirit.toString());
    supplyController = TextEditingController(text: widget.character.supply.toString());
    
    // Initialize NPC character details controllers
    firstLookController = TextEditingController(text: widget.character.firstLook ?? '');
    dispositionController = TextEditingController(text: widget.character.disposition ?? '');
    trademarkAvatarController = TextEditingController(text: widget.character.trademarkAvatar ?? '');
    roleController = TextEditingController(text: widget.character.role ?? '');
    detailsController = TextEditingController(text: widget.character.details ?? '');
    goalsController = TextEditingController(text: widget.character.goals ?? '');
    
    // Initialize stats
    stats = widget.character.stats.map((stat) => CharacterStat(
      name: stat.name,
      value: stat.value,
    )).toList();
    
    // Initialize key stats
    momentum = widget.character.momentum;
    health = widget.character.health;
    spirit = widget.character.spirit;
    supply = widget.character.supply;
    
    // Initialize impacts
    impactWounded = widget.character.impactWounded;
    impactShaken = widget.character.impactShaken;
    impactUnregulated = widget.character.impactUnregulated;
    impactPermanentlyHarmed = widget.character.impactPermanentlyHarmed;
    impactTraumatized = widget.character.impactTraumatized;
    impactDoomed = widget.character.impactDoomed;
    impactTormented = widget.character.impactTormented;
    impactIndebted = widget.character.impactIndebted;
    impactOverheated = widget.character.impactOverheated;
    impactInfected = widget.character.impactInfected;
    
    // Initialize section visibility
    showNpcDetails = !widget.character.isMainCharacter;
  }
  
  @override
  void dispose() {
    nameController.dispose();
    handleController.dispose();
    bioController.dispose();
    imageUrlController.dispose();
    notesController.dispose();
    momentumController.dispose();
    healthController.dispose();
    spiritController.dispose();
    supplyController.dispose();
    firstLookController.dispose();
    dispositionController.dispose();
    trademarkAvatarController.dispose();
    roleController.dispose();
    detailsController.dispose();
    goalsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Character' : "${widget.character.name} aka ${widget.character.getHandle()}"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEditing) ...[
              // Character form for basic information
              CharacterForm(
                nameController: nameController,
                handleController: handleController,
                bioController: bioController,
                imageUrlController: imageUrlController,
                isPlayerCharacterSwitchVisible: false,
                isPlayerCharacter: widget.character.isMainCharacter,
                onPlayerCharacterChanged: null,
                // Pass controllers for NPC character details
                firstLookController: !widget.character.isMainCharacter ? firstLookController : null,
                dispositionController: !widget.character.isMainCharacter ? dispositionController : null,
                trademarkAvatarController: !widget.character.isMainCharacter ? trademarkAvatarController : null,
                roleController: !widget.character.isMainCharacter ? roleController : null,
                detailsController: !widget.character.isMainCharacter ? detailsController : null,
                goalsController: !widget.character.isMainCharacter ? goalsController : null,
              ),
            ] else ...[
              // Character details panel
              CharacterDetailsPanel(character: widget.character),
            ],
            
            const SizedBox(height: 16),
            
            // NPC Character Details section (collapsible)
            if (!widget.character.isMainCharacter && !isEditing) ...[
              CharacterNpcDetailsPanel(
                character: widget.character,
                initiallyExpanded: showNpcDetails,
              ),
            ],
            
            // Key Stats section (collapsible)
            if (widget.character.isMainCharacter) ...[
              CharacterKeyStatsPanel(
                character: widget.character,
                momentumController: momentumController,
                healthController: healthController,
                spiritController: spiritController,
                supplyController: supplyController,
                isEditable: isEditing,
                initiallyExpanded: showKeyStats,
                useCompactMode: !isEditing, // Use compact mode when viewing, text field mode when editing
                onStatsChanged: (newMomentum, newHealth, newSpirit, newSupply) {
                  setState(() {
                    momentum = newMomentum;
                    health = newHealth;
                    spirit = newSpirit;
                    supply = newSupply;
                  });
                },
              ),
            ],
            
            // Impacts section (collapsible)
            if (widget.character.isMainCharacter) ...[
              ListTile(
                title: const Text('Impacts', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(showImpacts ? Icons.expand_less : Icons.expand_more),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    showImpacts = !showImpacts;
                  });
                },
              ),
              if (showImpacts) ...[
                ImpactPanel(
                  character: widget.character,
                  isEditable: isEditing,
                  onImpactChanged: (impactType, value) {
                    setState(() {
                      switch (impactType) {
                        case 'wounded':
                          impactWounded = value;
                          widget.character.impactWounded = value;
                          break;
                        case 'shaken':
                          impactShaken = value;
                          widget.character.impactShaken = value;
                          break;
                        case 'unregulated':
                          impactUnregulated = value;
                          widget.character.impactUnregulated = value;
                          break;
                        case 'permanently_harmed':
                          impactPermanentlyHarmed = value;
                          widget.character.impactPermanentlyHarmed = value;
                          break;
                        case 'traumatized':
                          impactTraumatized = value;
                          widget.character.impactTraumatized = value;
                          break;
                        case 'doomed':
                          impactDoomed = value;
                          widget.character.impactDoomed = value;
                          break;
                        case 'tormented':
                          impactTormented = value;
                          widget.character.impactTormented = value;
                          break;
                        case 'indebted':
                          impactIndebted = value;
                          widget.character.impactIndebted = value;
                          break;
                        case 'overheated':
                          impactOverheated = value;
                          widget.character.impactOverheated = value;
                          break;
                        case 'infected':
                          impactInfected = value;
                          widget.character.impactInfected = value;
                          break;
                      }
                    });
                  },
                ),
              ],
            ],
            
            // Assets section (collapsible)
            if (widget.character.isMainCharacter) ...[
              ListTile(
                title: const Text('Assets', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(showAssets ? Icons.expand_less : Icons.expand_more),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    showAssets = !showAssets;
                  });
                },
              ),
              if (showAssets) ...[
                AssetPanel(
                  character: widget.character,
                  isEditable: isEditing,
                  onAssetsChanged: () {
                    setState(() {});
                  },
                ),
              ],
            ],
            
            // Legacies section (collapsible)
            if (widget.character.isMainCharacter) ...[
              ListTile(
                title: const Text('Legacies', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(showLegacies ? Icons.expand_less : Icons.expand_more),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    showLegacies = !showLegacies;
                  });
                },
              ),
              if (showLegacies) ...[
                LegacyPanel(
                  character: widget.character,
                  isEditable: isEditing,
                  onLegacyChanged: () {
                    setState(() {});
                  },
                ),
              ],
            ],
            
            // Notes section (collapsible)
            if (widget.character.isMainCharacter) ...[
              CharacterNotesPanel(
                character: widget.character,
                notesController: notesController,
                isEditable: isEditing,
                initiallyExpanded: showNotes,
              ),
            ],
            
            // Character stats section (collapsible)
            if (widget.character.stats.isNotEmpty) ...[
              ListTile(
                title: const Text('Stats', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(showStats ? Icons.expand_less : Icons.expand_more),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() {
                    showStats = !showStats;
                  });
                },
              ),
              if (showStats) ...[
                StatPanel(
                  stats: stats,
                  isEditable: isEditing,
                  onStatChanged: (index, value) {
                    setState(() {
                      stats[index].value = value;
                    });
                  },
                ),
              ],
            ],
            
            const SizedBox(height: 16),
            
            if (widget.character.stats.isNotEmpty && !isEditing)
              ElevatedButton.icon(
                icon: const Icon(Icons.star),
                label: Text(
                  widget.gameProvider.currentGame?.mainCharacter?.id == widget.character.id
                      ? 'Main Character'
                      : 'Set as Main Character',
                ),
                onPressed: widget.gameProvider.currentGame?.mainCharacter?.id == widget.character.id
                    ? null
                    : () {
                        CharacterDialogService.setAsMainCharacter(
                          gameProvider: widget.gameProvider,
                          character: widget.character,
                        );
                        Navigator.pop(context);
                      },
              ),
          ],
        ),
      ),
      actions: [
        if (!isEditing)
          TextButton(
            onPressed: () async {
              // Show delete confirmation
              final confirmed = await CharacterDeleteConfirmation.show(
                context,
                widget.character,
              );
              
              if (confirmed && mounted) {
                CharacterDialogService.deleteCharacter(
                  gameProvider: widget.gameProvider,
                  character: widget.character,
                );
                Navigator.pop(context); // Close character details dialog
              }
            },
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () {
            if (isEditing) {
              // Save changes
              if (nameController.text.isEmpty && handleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a name or handle'),
                  ),
                );
                return;
              }
              
              // Update character using the service
              CharacterDialogService.updateCharacter(
                gameProvider: widget.gameProvider,
                character: widget.character,
                name: nameController.text,
                handle: handleController.text,
                bio: bioController.text,
                imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                notes: notesController.text.isEmpty 
                    ? [] 
                    : notesController.text.split('\n').where((line) => line.trim().isNotEmpty).toList(),
                stats: widget.character.stats.isNotEmpty ? stats : null,
                // Key stats
                momentum: momentum,
                health: health,
                spirit: spirit,
                supply: supply,
                // Impacts
                impactWounded: impactWounded,
                impactShaken: impactShaken,
                impactUnregulated: impactUnregulated,
                impactPermanentlyHarmed: impactPermanentlyHarmed,
                impactTraumatized: impactTraumatized,
                impactDoomed: impactDoomed,
                impactTormented: impactTormented,
                impactIndebted: impactIndebted,
                impactOverheated: impactOverheated,
                impactInfected: impactInfected,
                // NPC character details
                firstLook: !widget.character.isMainCharacter ? firstLookController.text : null,
                disposition: !widget.character.isMainCharacter ? dispositionController.text : null,
                trademarkAvatar: !widget.character.isMainCharacter ? trademarkAvatarController.text : null,
                role: !widget.character.isMainCharacter ? roleController.text : null,
                details: !widget.character.isMainCharacter ? detailsController.text : null,
                goals: !widget.character.isMainCharacter ? goalsController.text : null,
              );
              
              setState(() {
                isEditing = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Save' : 'Close'),
        ),
        if (!isEditing)
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
            child: const Text('Edit'),
          ),
      ],
    );
  }
}
