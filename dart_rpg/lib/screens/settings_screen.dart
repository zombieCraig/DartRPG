import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../utils/logging_service.dart';
import '../services/tutorial_service.dart';
import '../transitions/transition_type.dart';
import '../transitions/navigation_service.dart';
import 'animation_test_screen.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  // Method to show a preview of the selected transition
  static void _showTransitionPreview(BuildContext context, TransitionType type) {
    // Create a simple preview screen
    final previewScreen = Scaffold(
      appBar: AppBar(
        title: Text('${type.displayName} Preview'),
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        color: Colors.blueGrey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type.icon,
                color: Colors.greenAccent,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'Transition Preview',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  type.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Return to Settings'),
              ),
            ],
          ),
        ),
      ),
    );

    // Use the NavigationService to show the preview with the selected transition
    final navigationService = NavigationService();
    navigationService.navigateTo(
      context,
      previewScreen,
      transitionType: type,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Theme settings
              const Text(
                'Appearance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  settings.setDarkMode(value);
                },
              ),
              SwitchListTile(
                title: const Text('Enable Tutorials'),
                subtitle: const Text('Show helpful tips for new players'),
                value: settings.enableTutorials,
                onChanged: (value) {
                  settings.setEnableTutorials(value);
                },
              ),
              if (settings.enableTutorials)
                TutorialService.buildResetTutorialsButton(context),
              const Divider(),
              
              // Font size settings
              const Text(
                'Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Font Size'),
                subtitle: Slider(
                  min: 12,
                  max: 24,
                  divisions: 6,
                  label: settings.fontSize.toStringAsFixed(1),
                  value: settings.fontSize,
                  onChanged: (value) {
                    settings.setFontSize(value);
                  },
                ),
                trailing: Text(
                  settings.fontSize.toStringAsFixed(1),
                  style: TextStyle(fontSize: settings.fontSize),
                ),
              ),
              
              // Font family settings
              ListTile(
                title: const Text('Font Family'),
                subtitle: DropdownButton<String>(
                  value: settings.fontFamily,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      settings.setFontFamily(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Roboto',
                      child: Text('Roboto'),
                    ),
                    DropdownMenuItem(
                      value: 'OpenSans',
                      child: Text('Open Sans'),
                    ),
                    DropdownMenuItem(
                      value: 'Lato',
                      child: Text('Lato'),
                    ),
                    DropdownMenuItem(
                      value: 'Montserrat',
                      child: Text('Montserrat'),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Animation settings
              const Text(
                'Animations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Master toggle for all animations
              SwitchListTile(
                title: const Text('Enable Animations'),
                subtitle: const Text('Toggle all animation effects'),
                value: settings.enableAnimations,
                onChanged: (value) {
                  settings.setEnableAnimations(value);
                },
              ),
              
              // Only show these options if animations are enabled
              if (settings.enableAnimations) ...[
                // Animation speed slider
                ListTile(
                  title: const Text('Animation Speed'),
                  subtitle: Slider(
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${settings.animationSpeed.toStringAsFixed(1)}x',
                    value: settings.animationSpeed,
                    onChanged: (value) {
                      settings.setAnimationSpeed(value);
                    },
                  ),
                  trailing: Text(
                    '${settings.animationSpeed.toStringAsFixed(1)}x',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Screen transition settings
                const Text(
                  'Screen Transitions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Transition type dropdown
                ListTile(
                  title: const Text('Transition Style'),
                  subtitle: DropdownButton<TransitionType>(
                    value: settings.transitionType,
                    isExpanded: true,
                    onChanged: (TransitionType? newValue) {
                      if (newValue != null) {
                        settings.setTransitionType(newValue);
                      }
                    },
                    items: TransitionType.values.map((type) {
                      return DropdownMenuItem<TransitionType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 16),
                            const SizedBox(width: 8),
                            Text(type.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Transition description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    settings.transitionType.description,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
                
                // Preview transition button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview Transition'),
                    onPressed: () => _showTransitionPreview(context, settings.transitionType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                
                // Animation preview options
                const Text(
                  'Preview Animations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Progress animation test
                ListTile(
                  title: const Text('Progress Animations'),
                  subtitle: const Text('Test progress track animations'),
                  trailing: const Icon(Icons.animation),
                  onTap: () {
                    final navigationService = NavigationService();
                    navigationService.navigateTo(
                      context,
                      const AnimationTestScreen(),
                    );
                  },
                ),
                
              ],
              
              const Divider(),
              
              // Developer options
              const Text(
                'Developer Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Log Level'),
                subtitle: Text('Current: ${settings.getLogLevelName(settings.logLevel)}'),
                trailing: DropdownButton<int>(
                  value: settings.logLevel,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      settings.setLogLevel(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: LoggingService.levelDebug,
                      child: const Text('Debug'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.levelInfo,
                      child: const Text('Info'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.levelWarning,
                      child: const Text('Warning'),
                    ),
                    DropdownMenuItem(
                      value: LoggingService.levelError,
                      child: const Text('Error'),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('View Logs'),
                subtitle: const Text('View and manage application logs'),
                leading: const Icon(Icons.list_alt),
                onTap: () {
                  final navigationService = NavigationService();
                  navigationService.navigateTo(
                    context,
                    const LogViewerScreen(),
                  );
                },
              ),
              
              const Divider(),
              
              // About section
              const Text(
                'About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const ListTile(
                title: Text('Fe-Runners Solo RPG'),
                subtitle: Text('Version 0.0.1'),
              ),
              ListTile(
                title: const Text('Source Code'),
                subtitle: const Text('View on GitHub'),
                onTap: () async {
                  final Uri url = Uri.parse('https://github.com/zombieCraig/DartRPG');
                  if (!await launchUrl(url)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open URL')),
                    );
                  }
                },
              ),
              ListTile(
                title: const Text('Fe-Runners'),
                subtitle: const Text('Learn more about the Fe-Runners RPG'),
                onTap: () async {
                  final Uri url = Uri.parse('https://zombiecraig.itch.io/fe-runners');
                  if (!await launchUrl(url)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open URL')),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
