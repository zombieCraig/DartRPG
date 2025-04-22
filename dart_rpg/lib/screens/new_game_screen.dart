import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/datasworn_provider.dart';
import '../transitions/navigation_service.dart';
import '../models/game.dart';
import '../widgets/sentient_ai_settings_widget.dart';
import '../widgets/ai_image_generation_settings_widget.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreating = false;
  bool _enableTutorials = true;
  
  // Sentient AI settings
  bool _sentientAiEnabled = false;
  String? _sentientAiName;
  String? _sentientAiPersona;
  String? _sentientAiImagePath;
  
  // AI Image Generation settings
  bool _aiImageGenerationEnabled = false;
  String? _aiImageProvider;
  Map<String, String> _aiApiKeys = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  // Callback for when Sentient AI settings change
  void _onSentientAiSettingsChanged(
    bool enabled,
    String? name,
    String? persona,
    String? imagePath,
  ) {
    setState(() {
      _sentientAiEnabled = enabled;
      _sentientAiName = name;
      _sentientAiPersona = persona;
      _sentientAiImagePath = imagePath;
    });
  }
  
  // Callback for when AI Image Generation settings change
  void _onAiImageGenerationSettingsChanged(
    bool enabled,
    String? provider,
    Map<String, String>? apiKeys,
  ) {
    setState(() {
      _aiImageGenerationEnabled = enabled;
      _aiImageProvider = provider;
      _aiApiKeys = apiKeys ?? {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Game'),
      ),
      body: Consumer2<GameProvider, DataswornProvider>(
        builder: (context, gameProvider, dataswornProvider, _) {
          // Create a temporary game object for the settings widgets
          final tempGame = Game(
            name: 'Temp Game',
            sentientAiEnabled: _sentientAiEnabled,
            sentientAiName: _sentientAiName,
            sentientAiPersona: _sentientAiPersona,
            sentientAiImagePath: _sentientAiImagePath,
            aiImageGenerationEnabled: _aiImageGenerationEnabled,
            aiImageProvider: _aiImageProvider,
          );
          
          // Add API keys to the temp game
          for (final entry in _aiApiKeys.entries) {
            tempGame.setAiApiKey(entry.key, entry.value);
          }
          
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Game Name',
                      hintText: 'Enter a name for your game',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Game Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This game will use the Fe-Runners datasworn source.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Enable Tutorials'),
                    subtitle: const Text('Show helpful tips for new players'),
                    value: _enableTutorials,
                    onChanged: (value) {
                      setState(() {
                        _enableTutorials = value ?? true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Sentient AI Settings
                  SentientAiSettingsWidget(
                    game: tempGame,
                    gameProvider: gameProvider,
                    dataswornProvider: dataswornProvider,
                    initiallyExpanded: false,
                    showDividers: true,
                    showHelpText: true,
                    isNewGame: true,
                    disablePersonaSelection: true, // Disable persona selection in new game screen
                    onNewGameSettingsChanged: _onSentientAiSettingsChanged,
                  ),
                  
                  // AI Image Generation Settings
                  AiImageGenerationSettingsWidget(
                    game: tempGame,
                    gameProvider: gameProvider,
                    initiallyExpanded: false,
                    showDividers: true,
                    showHelpText: true,
                    isNewGame: true,
                    onNewGameSettingsChanged: _onAiImageGenerationSettingsChanged,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_isCreating)
                    const Center(child: CircularProgressIndicator())
                  else
                    Center(
                      child: ElevatedButton(
                        onPressed: _createGame,
                        child: const Text('Create Game'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createGame() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        final dataswornProvider = Provider.of<DataswornProvider>(context, listen: false);
        
        // Create the game with all settings
        final game = await gameProvider.createGame(
          _nameController.text,
          dataswornSource: 'assets/data/fe_runners.json',
          tutorialsEnabled: _enableTutorials,
          sentientAiEnabled: _sentientAiEnabled,
          sentientAiName: _sentientAiName,
          sentientAiPersona: _sentientAiPersona,
          sentientAiImagePath: _sentientAiImagePath,
        );
        
        // Set AI Image Generation settings
        if (_aiImageGenerationEnabled) {
          await gameProvider.updateAiImageGenerationEnabled(_aiImageGenerationEnabled);
          
          if (_aiImageProvider != null) {
            await gameProvider.updateAiImageProvider(_aiImageProvider);
            
            // Set API keys
            for (final entry in _aiApiKeys.entries) {
              await gameProvider.updateAiApiKey(entry.key, entry.value);
            }
          }
        }
        
        // Explicitly save the game
        await gameProvider.saveGame();
        
        // Load the datasworn source
        await dataswornProvider.loadDatasworn('assets/data/fe_runners.json');
        
        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Game "${_nameController.text}" created successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          
          // Return to the game selection screen
          final navigationService = NavigationService();
          navigationService.goBack(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create game: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }
}
