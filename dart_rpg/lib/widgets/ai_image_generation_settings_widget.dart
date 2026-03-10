import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/game.dart';
import '../providers/ai_config_provider.dart';
import '../utils/logging_service.dart';

/// A reusable widget for AI image generation settings that can be used in both
/// the game settings screen and the new game screen.
class AiImageGenerationSettingsWidget extends StatefulWidget {
  /// The game object to modify
  final Game game;
  
  /// The AI config provider to update AI settings
  final AiConfigProvider aiConfigProvider;
  
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
  
  /// Callback for when settings change in new game mode
  final Function(bool enabled, String? provider, String? openaiModel, Map<String, String>? apiKeys, Map<String, String>? artisticDirections)? 
      onNewGameSettingsChanged;

  const AiImageGenerationSettingsWidget({
    super.key,
    required this.game,
    required this.aiConfigProvider,
    this.initiallyExpanded = false,
    this.showDividers = true,
    this.showHelpText = true,
    this.onSettingsChanged,
    this.isNewGame = false,
    this.onNewGameSettingsChanged,
  });

  @override
  State<AiImageGenerationSettingsWidget> createState() => _AiImageGenerationSettingsWidgetState();
}

class _AiImageGenerationSettingsWidgetState extends State<AiImageGenerationSettingsWidget> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _artisticDirectionController = TextEditingController();
  bool _aiImageGenerationExpanded = false;
  bool _showApiKey = false;
  
  // For new game mode, we need to track the settings locally
  bool _aiImageGenerationEnabled = false;
  String? _aiImageProvider;
  String? _openaiModel = 'dall-e-2'; // Default OpenAI model
  Map<String, String> _aiApiKeys = {};
  Map<String, String> _aiArtisticDirections = {};
  
  // List of supported AI providers
  final List<Map<String, String>> _supportedProviders = [
    {'id': 'minimax', 'name': 'Minimax'},
    {'id': 'openai', 'name': 'OpenAI'},
    {'id': 'stability', 'name': 'Stability AI'},
    {'id': 'google_imagen', 'name': 'Google Imagen'},
    {'id': 'fal', 'name': 'FAL.ai (FLUX)'},
  ];
  
  // List of supported OpenAI models
  final List<Map<String, String>> _openaiModels = [
    {'id': 'dall-e-2', 'name': 'DALL-E 2'},
    {'id': 'dall-e-3', 'name': 'DALL-E 3'},
    {'id': 'gpt-image-1', 'name': 'GPT-Image-1'},
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize expansion state
    _aiImageGenerationExpanded = widget.initiallyExpanded;
    
    // Initialize settings
    if (widget.isNewGame) {
      _aiImageGenerationEnabled = false;
      _aiImageProvider = null;
      _aiApiKeys = {};
      _aiArtisticDirections = {};
      _artisticDirectionController.text = "cyberpunk scene, digital art, detailed illustration";
    } else {
      // Initialize the API key controller with the current value if available
      if (widget.game.aiConfig.aiImageProvider != null && 
          widget.game.aiConfig.aiApiKeys.containsKey(widget.game.aiConfig.aiImageProvider!)) {
        _apiKeyController.text = widget.game.aiConfig.aiApiKeys[widget.game.aiConfig.aiImageProvider!]!;
      }
      
      // Initialize the artistic direction controller with the current value if available
      if (widget.game.aiConfig.aiImageProvider != null && 
          widget.game.aiConfig.aiArtisticDirections.containsKey(widget.game.aiConfig.aiImageProvider!)) {
        _artisticDirectionController.text = widget.game.aiConfig.aiArtisticDirections[widget.game.aiConfig.aiImageProvider!]!;
      } else {
        _artisticDirectionController.text = "cyberpunk scene, digital art, detailed illustration";
      }
    }
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _artisticDirectionController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(AiImageGenerationSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update the API key controller when the provider changes
    if (!widget.isNewGame && 
        widget.game.aiConfig.aiImageProvider != null && 
        widget.game.aiConfig.aiApiKeys.containsKey(widget.game.aiConfig.aiImageProvider!)) {
      _apiKeyController.text = widget.game.aiConfig.aiApiKeys[widget.game.aiConfig.aiImageProvider!]!;
    } else if (!widget.isNewGame && widget.game.aiConfig.aiImageProvider != null) {
      _apiKeyController.text = '';
    }
    
    // Update the artistic direction controller when the provider changes
    if (!widget.isNewGame && 
        widget.game.aiConfig.aiImageProvider != null && 
        widget.game.aiConfig.aiArtisticDirections.containsKey(widget.game.aiConfig.aiImageProvider!)) {
      _artisticDirectionController.text = widget.game.aiConfig.aiArtisticDirections[widget.game.aiConfig.aiImageProvider!]!;
    } else if (!widget.isNewGame && widget.game.aiConfig.aiImageProvider != null) {
      _artisticDirectionController.text = "cyberpunk scene, digital art, detailed illustration";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // AI image generation is not available on web due to CORS restrictions
    if (kIsWeb) {
      return Column(
        children: [
          if (widget.showDividers) const Divider(),
          ExpansionTile(
            title: const Text(
              'AI Image Generation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Not available on web',
              style: TextStyle(color: Colors.grey),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI image generation is only available on desktop builds. '
                          'Web browsers block direct API calls to external services due to CORS restrictions. '
                          'Please use the desktop app to generate AI images.',
                          style: TextStyle(fontSize: 14.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (widget.showDividers) const Divider(),
        ],
      );
    }

    // Use either the game's values or the local values depending on mode
    final aiImageGenerationEnabled = widget.isNewGame ?
        _aiImageGenerationEnabled : widget.game.aiConfig.aiImageGenerationEnabled;
    final aiImageProvider = widget.isNewGame ?
        _aiImageProvider : widget.game.aiConfig.aiImageProvider;
    return Column(
      children: [
        if (widget.showDividers) const Divider(),
        
        // AI Image Generation settings
        ExpansionTile(
          title: const Text(
            'AI Image Generation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            aiImageGenerationEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              color: aiImageGenerationEnabled ? Colors.green : Colors.grey,
            ),
          ),
          initiallyExpanded: _aiImageGenerationExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _aiImageGenerationExpanded = expanded;
            });
          },
          children: [
            // Enable/disable AI Image Generation
            SwitchListTile(
              title: const Text('Enable AI Image Generation'),
              subtitle: const Text('Allow generating images using AI services'),
              value: aiImageGenerationEnabled,
              onChanged: (value) {
                if (widget.isNewGame) {
                  setState(() {
                    _aiImageGenerationEnabled = value;
                  });
                  _notifyNewGameSettingsChanged();
                } else {
                  widget.aiConfigProvider.updateAiImageGenerationEnabled(value);
                  if (widget.onSettingsChanged != null) {
                    widget.onSettingsChanged!();
                  }
                }
              },
            ),
            
            if (aiImageGenerationEnabled) ...[
              // AI provider selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'AI Provider',
                    border: OutlineInputBorder(),
                  ),
                  value: aiImageProvider,
                  hint: const Text('Select AI Provider'),
                  isExpanded: true,
                  onChanged: (value) {
                    if (widget.isNewGame) {
                      setState(() {
                        _aiImageProvider = value;
                        
                        // Update the API key controller
                        if (value != null && _aiApiKeys.containsKey(value)) {
                          _apiKeyController.text = _aiApiKeys[value]!;
                        } else {
                          _apiKeyController.text = '';
                        }
                      });
                      _notifyNewGameSettingsChanged();
                    } else {
                      widget.aiConfigProvider.updateAiImageProvider(value);
                      
                      // Update the API key controller
                      if (value != null && widget.game.aiConfig.aiApiKeys.containsKey(value)) {
                        _apiKeyController.text = widget.game.aiConfig.aiApiKeys[value]!;
                      } else {
                        _apiKeyController.text = '';
                      }
                      
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
                    ..._supportedProviders.map((provider) => 
                      DropdownMenuItem<String>(
                        value: provider['id'],
                        child: Text(provider['name']!),
                      ),
                    ),
                  ],
                ),
              ),
              
              // OpenAI model selection
              if (aiImageProvider == 'openai')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'OpenAI Model',
                      border: OutlineInputBorder(),
                    ),
                    value: widget.isNewGame ? 
                        (_aiImageProvider == 'openai' ? 'dall-e-2' : null) : 
                        widget.game.aiConfig.openaiModel ?? 'dall-e-2',
                    hint: const Text('Select OpenAI Model'),
                    isExpanded: true,
                    onChanged: (value) {
                      if (widget.isNewGame) {
                        setState(() {
                          _openaiModel = value;
                        });
                        _notifyNewGameSettingsChanged();
                      } else {
                        if (value != null) {
                          widget.aiConfigProvider.updateOpenAiModel(value);
                          
                          if (widget.onSettingsChanged != null) {
                            widget.onSettingsChanged!();
                          }
                        }
                      }
                    },
                    items: _openaiModels.map((model) => 
                      DropdownMenuItem<String>(
                        value: model['id'],
                        child: Text(model['name']!),
                      ),
                    ).toList(),
                  ),
                ),
              
              // API key input
              if (aiImageProvider != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your API key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showApiKey = !_showApiKey;
                          });
                        },
                      ),
                    ),
                    obscureText: !_showApiKey,
                    onChanged: (value) {
                      if (widget.isNewGame) {
                        setState(() {
                          if (value.isNotEmpty && _aiImageProvider != null) {
                            _aiApiKeys[_aiImageProvider!] = value;
                          } else if (_aiImageProvider != null) {
                            _aiApiKeys.remove(_aiImageProvider!);
                          }
                        });
                        _notifyNewGameSettingsChanged();
                      } else                      if (value.isNotEmpty) {
                        // Log the API key length before updating
                        LoggingService().debug(
                          'Setting API key for $aiImageProvider with length: ${value.length}',
                          tag: 'AiImageGenerationSettingsWidget'
                        );
                        
                        // Update the API key in the game provider
                        widget.aiConfigProvider.updateAiApiKey(aiImageProvider, value);
                        
                        // Verify the API key was set correctly in the game object
                        final apiKey = widget.game.aiConfig.getAiApiKey(aiImageProvider);
                        if (apiKey != null) {
                          LoggingService().debug(
                            'API key for $aiImageProvider was set successfully with length: ${apiKey.length}',
                            tag: 'AiImageGenerationSettingsWidget'
                          );
                        } else {
                          LoggingService().warning(
                            'Failed to set API key for $aiImageProvider',
                            tag: 'AiImageGenerationSettingsWidget'
                          );
                        }
                      } else {
                        widget.aiConfigProvider.removeAiApiKey(aiImageProvider);
                      }
                      
                      if (widget.onSettingsChanged != null) {
                        widget.onSettingsChanged!();
                      }
                    
                    },
                  ),
                ),
                
              // Artistic Direction input
              if (aiImageProvider != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _artisticDirectionController,
                    decoration: const InputDecoration(
                      labelText: 'Artistic Direction',
                      hintText: 'Enter artistic direction for AI images',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      if (widget.isNewGame) {
                        setState(() {
                          if (value.isNotEmpty && _aiImageProvider != null) {
                            _aiArtisticDirections[_aiImageProvider!] = value;
                          } else if (_aiImageProvider != null) {
                            _aiArtisticDirections.remove(_aiImageProvider!);
                          }
                        });
                        _notifyNewGameSettingsChanged();
                      } else                      if (value.isNotEmpty) {
                        // Log the artistic direction before updating
                        LoggingService().debug(
                          'Setting artistic direction for $aiImageProvider',
                          tag: 'AiImageGenerationSettingsWidget'
                        );
                        
                        // Update the artistic direction in the game provider
                        widget.aiConfigProvider.updateAiArtisticDirection(aiImageProvider, value);
                        
                        // Verify the artistic direction was set correctly in the game object
                        final artisticDirection = widget.game.aiConfig.getAiArtisticDirection(aiImageProvider);
                        if (artisticDirection != null) {
                          LoggingService().debug(
                            'Artistic direction for $aiImageProvider was set successfully',
                            tag: 'AiImageGenerationSettingsWidget'
                          );
                        } else {
                          LoggingService().warning(
                            'Failed to set artistic direction for $aiImageProvider',
                            tag: 'AiImageGenerationSettingsWidget'
                          );
                        }
                      }
                      
                      if (widget.onSettingsChanged != null) {
                        widget.onSettingsChanged!();
                      }
                    
                    },
                  ),
                ),
              
              // Help text
              if (widget.showHelpText)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'About AI Image Generation',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'This feature allows you to generate images using AI services. You need to provide an API key for the selected service.',
                              style: TextStyle(fontSize: 14.0),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              'Your API key is stored locally and is only used to generate images. It is never shared with anyone else.',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      // Provider-specific help
                      if (aiImageProvider == 'minimax')
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Minimax API',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'To use Minimax, you need to sign up for an account, obtain an API key, and ensure you have credits in your account.',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://www.minimax.io/platform/user-center/basic-information/interface-key');
                                      if (!await launchUrl(url)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open the URL'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Get your API key here',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Note: You need to have credits in your Minimax account to generate images. New accounts may come with free credits.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      if (aiImageProvider == 'openai')
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OpenAI API',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'To use OpenAI, you need to sign up for an account, obtain an API key, and ensure you have credits in your account.',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://platform.openai.com/api-keys');
                                      if (!await launchUrl(url)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open the URL'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Get your API key here',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Available Models:',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              const Text(
                                '• DALL-E 2: Older model, more affordable\n'
                                '• DALL-E 3: Higher quality images, more expensive\n'
                                '• GPT-Image-1: Latest model with advanced capabilities',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Note: You need to have credits in your OpenAI account to generate images. Pricing varies by model.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (aiImageProvider == 'stability')
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stability AI API',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Uses Stable Diffusion 3.5 Large for high-quality image generation. Generates 1 image per request with per-image pricing.',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://platform.stability.ai/account/keys');
                                      if (!await launchUrl(url)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open the URL'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Get your API key here',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Note: Only 1 image is generated per request. Credits are consumed per image generated.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (aiImageProvider == 'google_imagen')
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Google Imagen API',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Uses Imagen 3 via the Gemini API for high-quality image generation. Supports up to 4 images per request.',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://aistudio.google.com/apikey');
                                      if (!await launchUrl(url)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open the URL'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Get your API key here',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Note: Uses Google AI Studio API key. Free tier available with usage limits.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (aiImageProvider == 'fal')
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FAL.ai (FLUX) API',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Uses FLUX models for fast, high-quality image generation. Generally the most affordable option with good quality results.',
                                style: TextStyle(fontSize: 14.0),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final Uri url = Uri.parse('https://fal.ai/dashboard/keys');
                                      if (!await launchUrl(url)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not open the URL'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Get your API key here',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              const Text(
                                'Note: Uses FLUX dev model. One of the cheapest options for AI image generation.',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
        
        if (widget.showDividers) const Divider(),
      ],
    );
  }
  
  // Helper method to notify new game settings changed
  void _notifyNewGameSettingsChanged() {
    if (widget.isNewGame && widget.onNewGameSettingsChanged != null) {
      widget.onNewGameSettingsChanged!(
        _aiImageGenerationEnabled,
        _aiImageProvider,
        _openaiModel,
        _aiApiKeys,
        _aiArtisticDirections,
      );
    }
  }
}
