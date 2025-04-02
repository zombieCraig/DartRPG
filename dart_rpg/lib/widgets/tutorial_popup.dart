import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// A reusable widget for displaying tutorial popups.
class TutorialPopup extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onClose;
  final bool showDisableOption;

  /// Creates a tutorial popup.
  /// 
  /// The [title] and [message] are displayed in the popup.
  /// The [onClose] callback is called when the user dismisses the popup.
  /// If [showDisableOption] is true, a checkbox to disable all tutorials is shown.
  const TutorialPopup({
    Key? key,
    required this.title,
    required this.message,
    required this.onClose,
    this.showDisableOption = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (showDisableOption) ...[
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return CheckboxListTile(
                  title: const Text('Disable all tutorials'),
                  value: !settings.enableTutorials,
                  onChanged: (value) {
                    settings.setEnableTutorials(!(value ?? false));
                  },
                );
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
