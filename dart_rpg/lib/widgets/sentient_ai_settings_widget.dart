import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../utils/logging_service.dart';
import '../utils/sentient_ai_utils.dart';

/// A reusable widget for Sentient AI settings that can be used in both
/// the game settings screen and the new game screen.
class SentientAiSettingsWidget extends StatefulWidget {
  /// The game object to modify
  final Game game;
  
  /// The game provider to update the game
  final GameProvider gameProvider;
  
  /// The datasworn provider to get AI personas
  final DataswornProvider dataswornProvider;
  
  /// Whether the settings are initially expanded
  final bool initiallyExpanded;
  
  /// Whether to show dividers
  final bool showDividers;
  
  /// Whether to show help text
  final bool showHelpText;
  
  /// Callback for when settings change
  final VoidCallback? onSettingsChanged;
  
  /// Whether this is being used in the new game screen
  /// If true, it won't directly update the game provider
  final bool isNewGame;
  
  /// Whether to disable persona selection (useful for new game screen)
  final bool disablePersonaSelection;
  
  /// Callback for when settings change in new game mode
  final Function(bool enabled, String? name, String? persona, String? imagePath)? 
      onNewGameSettingsChanged;

  const SentientAiSettingsWidget({
    super.key,
    required this.game,
    required this.gameProvider,
    required this.dataswornProvider,
    this.initiallyExpanded = true,
    this.showDividers = true,
    this.showHelpText = true,
    this.onSettingsChanged,
    this.isNewGame = false,
    this.disablePersonaSelection = false,
    this.onNewGameSettingsChanged,
  });

  @override
  State<SentientAiSettingsWidget> createState() => _SentientAiSettingsWidgetState();
}

class _SentientAiSettingsWidgetState extends State<SentientAiSettingsWidget> {
  final TextEditingController _aiNameController = TextEditingController();
  bool _sentientAiExpanded = true;
  
  // For new game mode, we need to track the settings locally
  bool _sentientAiEnabled = false;
  String? _sentientAiName;
  String? _sentientAiPersona;
  String? _sentientAiImagePath;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize expansion state
    _sentientAiExpanded = widget.initiallyExpanded;
    
    // Initialize the AI name controller with the current value
    if (widget.isNewGame) {
      _sentientAiEnabled = false;
      _sentientAiName = null;
      _sentientAiPersona = null;
      _sentientAiImagePath = null;
    } else {
      _aiNameController.text = widget.game.sentientAiName ?? '';
    }
  }
  
  @override
  void dispose() {
    _aiNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Get AI personas from the datasworn provider
    final aiPersonas = widget.gameProvider.getAiPersonas(widget.dataswornProvider);
    
    // Use either the game's values or the local values depending on mode
    final sentientAiEnabled = widget.isNewGame ? _sentientAiEnabled : widget.game.sentientAiEnabled;
    final sentientAiPersona = widget.isNewGame ? _sentientAiPersona : widget.game.sentientAiPersona;
    final sentientAiImagePath = widget.isNewGame ? _sentientAiImagePath : widget.game.sentientAiImagePath;
    
    return Column(
      children: [
        if (widget.showDividers) const Divider(),
        
        // Sentient AI settings
        ExpansionTile(
          title: const Text(
            'Sentient AI',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            sentientAiEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: sentientAiEnabled ? Colors.green : Colors.grey,
            ),
          ),
          initiallyExpanded: _sentientAiExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _sentientAiExpanded = expanded;
            });
          },
          children: [
            // Enable/disable Sentient AI
            SwitchListTile(
              title: const Text('Enable Sentient AI'),
              subtitle: const Text('Allow AI to appear during certain moves'),
              value: sentientAiEnabled,
              onChanged: (value) {
                if (widget.isNewGame) {
                  setState(() {
                    _sentientAiEnabled = value;
                  });
                  _notifyNewGameSettingsChanged();
                } else {
                  widget.gameProvider.updateSentientAiEnabled(value);
                  if (widget.onSettingsChanged != null) {
                    widget.onSettingsChanged!();
                  }
                }
              },
            ),
            
            if (sentientAiEnabled) ...[
              // AI name
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _aiNameController,
                  decoration: const InputDecoration(
                    labelText: 'AI Name (Optional)',
                    hintText: 'Enter a name for the AI',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    final nameValue = value.isEmpty ? null : value;
                    if (widget.isNewGame) {
                      setState(() {
                        _sentientAiName = nameValue;
                      });
                      _notifyNewGameSettingsChanged();
                    } else {
                      widget.gameProvider.updateSentientAiName(nameValue);
                      if (widget.onSettingsChanged != null) {
                        widget.onSettingsChanged!();
                      }
                    }
                  },
                ),
              ),
              
              // AI persona
              if (widget.disablePersonaSelection) ...[
                // Show a message that persona selection is available after game creation
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Persona Selection',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Persona selection will be available in Game Settings after the game is created and data is loaded.',
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Regular persona selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'AI Persona (Optional)',
                            border: OutlineInputBorder(),
                          ),
                          value: sentientAiPersona,
                          hint: const Text('Select AI Persona'),
                          isExpanded: true,
                          onChanged: (value) {
                            if (widget.isNewGame) {
                              setState(() {
                                _sentientAiPersona = value;
                              });
                              _notifyNewGameSettingsChanged();
                            } else {
                              widget.gameProvider.updateSentientAiPersona(value);
                              if (widget.onSettingsChanged != null) {
                                widget.onSettingsChanged!();
                              }
                            }
                          },
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...aiPersonas.map((persona) => 
                              DropdownMenuItem<String>(
                                value: persona['id'],
                                child: Text(persona['name']!),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        tooltip: 'Random Persona',
                        onPressed: () {
                          final randomPersona = widget.gameProvider.getRandomAiPersona(widget.dataswornProvider);
                          if (randomPersona != null) {
                            if (widget.isNewGame) {
                              setState(() {
                                _sentientAiPersona = randomPersona;
                              });
                              _notifyNewGameSettingsChanged();
                            } else {
                              widget.gameProvider.updateSentientAiPersona(randomPersona);
                              if (widget.onSettingsChanged != null) {
                                widget.onSettingsChanged!();
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
              
              // AI persona description
              if (sentientAiPersona != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    sentientAiPersona.split(' - ').length > 1
                        ? sentientAiPersona.split(' - ')[1]
                        : '',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              
              // AI image
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Image (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: SentientAiUtils.buildAiImage(
                          context,
                          sentientAiImagePath,
                          sentientAiPersona,
                          useResponsiveHeight: false, // Use fixed height in settings
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Select Image'),
                          onPressed: () => _selectImage(context),
                        ),
                        if (sentientAiImagePath != null)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (widget.isNewGame) {
                                setState(() {
                                  _sentientAiImagePath = null;
                                });
                                _notifyNewGameSettingsChanged();
                              } else {
                                widget.gameProvider.updateSentientAiImagePath(null);
                                if (widget.onSettingsChanged != null) {
                                  widget.onSettingsChanged!();
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Help text
              if (widget.showHelpText)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'The Sentient AI is an optional game mechanic that can cause an AI to appear at certain times in the game, altering the outcome. When a move with Sentient AI capability is rolled and one or more challenge dice show a 10, the AI will appear.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ],
        ),
        
        if (widget.showDividers) const Divider(),
      ],
    );
  }
  
  // Method to select an image from the gallery
  Future<void> _selectImage(BuildContext context) async {
    try {
      // Use FilePicker to select an image
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          if (widget.isNewGame) {
            setState(() {
              _sentientAiImagePath = file.path;
            });
            _notifyNewGameSettingsChanged();
          } else {
            widget.gameProvider.updateSentientAiImagePath(file.path);
            if (widget.onSettingsChanged != null) {
              widget.onSettingsChanged!();
            }
          }
        }
      }
    } catch (e) {
      LoggingService().error(
        'Failed to select image',
        tag: 'SentientAiSettingsWidget',
        error: e,
        stackTrace: StackTrace.current,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Helper method to notify new game settings changed
  void _notifyNewGameSettingsChanged() {
    if (widget.isNewGame && widget.onNewGameSettingsChanged != null) {
      widget.onNewGameSettingsChanged!(
        _sentientAiEnabled,
        _sentientAiName,
        _sentientAiPersona,
        _sentientAiImagePath,
      );
    }
  }
}
