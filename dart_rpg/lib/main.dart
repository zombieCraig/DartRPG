import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'providers/game_provider.dart';
import 'providers/datasworn_provider.dart';
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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Fe-Runners Journal',
            theme: settings.getTheme(false),
            darkTheme: settings.getTheme(true),
            themeMode: settings.themeMode,
            home: const GameSelectionScreen(),
          );
        },
      ),
    );
  }
}
