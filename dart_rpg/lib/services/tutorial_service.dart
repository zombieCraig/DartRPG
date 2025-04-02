import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/tutorial_popup.dart';

/// A service for managing tutorial popups in the application.
class TutorialService {
  static const String _tutorialShownPrefix = 'tutorial_shown_';
  
  /// Checks if a specific tutorial has been shown before.
  static Future<bool> hasShownTutorial(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_tutorialShownPrefix$tutorialId') ?? false;
  }
  
  /// Marks a tutorial as shown so it won't be displayed again.
  static Future<void> markTutorialAsShown(String tutorialId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_tutorialShownPrefix$tutorialId', true);
  }
  
  /// Resets all tutorial shown states (useful for testing).
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_tutorialShownPrefix)) {
        await prefs.remove(key);
      }
    }
  }
  
  /// Adds a button to the settings screen to reset all tutorials.
  static Widget buildResetTutorialsButton(BuildContext context) {
    return ListTile(
      title: const Text('Reset Tutorials'),
      subtitle: const Text('Show all tutorial popups again'),
      onTap: () async {
        await resetAllTutorials();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All tutorials have been reset'),
            ),
          );
        }
      },
    );
  }
  
  /// Shows a tutorial popup if conditions are met:
  /// - Tutorials are enabled globally in settings
  /// - Tutorials are enabled for the current game
  /// - This specific tutorial hasn't been shown before
  /// - The provided condition is true
  static Future<void> showTutorialIfNeeded({
    required BuildContext context,
    required String tutorialId,
    required String title,
    required String message,
    required bool condition,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    // Check if tutorials are enabled globally and for this game
    if (!settings.enableTutorials || 
        !(gameProvider.currentGame?.tutorialsEnabled ?? false)) {
      return;
    }
    
    // Check if this tutorial has already been shown
    final hasShown = await hasShownTutorial(tutorialId);
    if (hasShown) {
      return;
    }
    
    // Check if the condition is met
    if (!condition) {
      return;
    }
    
    // Show the tutorial popup
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => TutorialPopup(
          title: title,
          message: message,
          onClose: () {
            Navigator.pop(context);
            markTutorialAsShown(tutorialId);
          },
        ),
      );
    }
  }
}
