import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/game_provider.dart';
import 'providers/datasworn_provider.dart';
import 'providers/image_manager_provider.dart';
import 'screens/game_selection_screen.dart';
import 'utils/logging_service.dart';

void main() {
  // Initialize logging service
  final logger = LoggingService();
  logger.info('Starting Fe-Runners Journal app', tag: 'Main');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => DataswornProvider()),
        ChangeNotifierProvider(create: (_) => ImageManagerProvider()..loadImages()),
      ],
      child: Builder(
        builder: (context) {
          // Connect the GameProvider and ImageManagerProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final gameProvider = Provider.of<GameProvider>(context, listen: false);
            final imageManagerProvider = Provider.of<ImageManagerProvider>(context, listen: false);
            gameProvider.setImageManagerProvider(imageManagerProvider);
          });
          
          return Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return MaterialApp(
                title: 'Fe-Runners Journal',
                theme: settings.getTheme(false),
                darkTheme: settings.getTheme(true),
                themeMode: settings.themeMode,
                home: const GameSelectionScreen(),
                // Custom page transitions
                onGenerateRoute: (settings) {
                  // Only apply custom transitions if animations are enabled
                  if (!context.read<SettingsProvider>().enableAnimations) {
                    return null; // Use default transitions
                  }
                  
                  // Get the route settings
                  final name = settings.name;
                  final arguments = settings.arguments;
                  
                  // Handle specific named routes if needed
                  if (name == '/') {
                    return MaterialPageRoute(
                      builder: (_) => const GameSelectionScreen(),
                      settings: settings,
                    );
                  }
                  
                  // For other routes, return null to use the default behavior
                  return null;
                },
              );
            },
          );
        },
      ),
    );
  }
}
